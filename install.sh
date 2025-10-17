#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# CODESPACES DOTFILES INSTALLATION SCRIPT
# Updated: 2025-10-16 - Parallel installation, timeouts, security fixes
# ═══════════════════════════════════════════════════════════════════

set -e  # Exit on error
set -u  # Error on undefined variables

# ═══════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

# Timeout for individual package installations (5 minutes per package)
readonly PACKAGE_TIMEOUT=300

# Timeout for entire script (15 minutes total)
readonly SCRIPT_TIMEOUT=900

# Colors for output (safe, no external deps)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

# Print with timestamp
log() {
    echo "[$(date +'%H:%M:%S')] $*"
}

# Print success message
success() {
    echo -e "${GREEN}✅ $*${NC}"
}

# Print error message
error() {
    echo -e "${RED}❌ $*${NC}"
}

# Print warning message
warn() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

# Cleanup function for timeouts
cleanup() {
    log "Cleaning up background processes..."
    jobs -p | xargs -r kill 2>/dev/null || true
}

# Set up trap for cleanup
trap cleanup EXIT INT TERM

# ═══════════════════════════════════════════════════════════════════
# SCRIPT TIMEOUT WRAPPER
# ═══════════════════════════════════════════════════════════════════

# Set a timeout for the entire script
(
    sleep $SCRIPT_TIMEOUT
    error "Installation timed out after ${SCRIPT_TIMEOUT}s"
    kill -TERM $$ 2>/dev/null || true
) &
SCRIPT_TIMEOUT_PID=$!

# ═══════════════════════════════════════════════════════════════════
# START INSTALLATION
# ═══════════════════════════════════════════════════════════════════

log "🚀 Setting up your Codespace environment..."
echo "============================================"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 1: Copy Configuration Files
# ═══════════════════════════════════════════════════════════════════

log "📋 Copying configuration files..."

# Copy .claude.json to home directory FIRST (critical for MCP servers)
if [ -f "$(dirname "$0")/.claude.json" ]; then
    cp "$(dirname "$0")/.claude.json" ~/.claude.json
    chmod 600 ~/.claude.json  # Security: Only owner can read
    success "Copied .claude.json to home directory (permissions: 600)"
else
    warn ".claude.json not found in dotfiles"
fi

# Copy .bash_profile if it exists
if [ -f "$(dirname "$0")/.bash_profile" ]; then
    cp "$(dirname "$0")/.bash_profile" ~/.bash_profile
    success "Copied .bash_profile"
fi

# Copy .bashrc if it exists
if [ -f "$(dirname "$0")/.bashrc" ]; then
    cp "$(dirname "$0")/.bashrc" ~/.bashrc
    success "Copied .bashrc"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Install Core Tools (Claude Code & SuperClaude)
# ═══════════════════════════════════════════════════════════════════

log "📦 Installing core tools..."
echo ""

# Install Claude Code (with timeout)
log "1/2 Installing Claude Code..."
if timeout $PACKAGE_TIMEOUT npm install -g @anthropic-ai/claude-code@latest --force 2>&1 | grep -v "npm WARN" | tail -3; then
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>&1 | head -1 || echo "unknown")
        success "Claude Code installed: $CLAUDE_VERSION"
    else
        error "Claude Code installation failed - command not found"
    fi
else
    error "Claude Code installation timed out or failed"
fi

echo ""

# Install SuperClaude (with timeout)
log "2/2 Installing SuperClaude..."
if command -v pipx &> /dev/null; then
    timeout $PACKAGE_TIMEOUT pipx install SuperClaude --force 2>&1 | tail -2
    timeout $PACKAGE_TIMEOUT pipx upgrade SuperClaude 2>&1 | tail -2
else
    timeout $PACKAGE_TIMEOUT pip install --break-system-packages --user --upgrade --force-reinstall SuperClaude 2>&1 | grep -v "Requirement already satisfied" | tail -3
fi

if command -v SuperClaude &> /dev/null || python3 -m SuperClaude --version &> /dev/null 2>&1; then
    SUPERCLAUDE_VERSION=$(python3 -m SuperClaude --version 2>&1 | head -1 || echo "installed")
    success "SuperClaude installed: $SUPERCLAUDE_VERSION"
else
    warn "SuperClaude installation had issues (not critical)"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 3: Install MCP Servers (IN PARALLEL - NEW!)
# ═══════════════════════════════════════════════════════════════════

log "🔌 Installing MCP Servers (parallel installation)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create temporary directory for installation logs
TEMP_LOG_DIR=$(mktemp -d)

# Function to install npm package with logging
install_npm_package() {
    local package_name="$1"
    local display_name="$2"
    local log_file="$TEMP_LOG_DIR/${package_name//\//_}.log"

    if timeout $PACKAGE_TIMEOUT npm install -g "${package_name}@latest" --force > "$log_file" 2>&1; then
        success "$display_name"
        return 0
    else
        error "$display_name (check $log_file)"
        return 1
    fi
}

# Function to install Python package with logging
install_pip_package() {
    local package_name="$1"
    local display_name="$2"
    local log_file="$TEMP_LOG_DIR/${package_name}.log"

    if timeout $PACKAGE_TIMEOUT pip install --break-system-packages --user --upgrade --force-reinstall "$package_name" > "$log_file" 2>&1; then
        success "$display_name"
        return 0
    else
        error "$display_name (check $log_file)"
        return 1
    fi
}

# Start all installations in parallel (background jobs)
log "Starting parallel installations..."

install_npm_package "mcp-installer" "mcp-installer" &
PID_1=$!

install_npm_package "@modelcontextprotocol/server-brave-search" "brave-search" &
PID_2=$!

install_pip_package "mcp-server-fetch" "fetch (Python)" &
PID_3=$!

install_npm_package "@modelcontextprotocol/server-github" "github" &
PID_4=$!

install_npm_package "@modelcontextprotocol/server-filesystem" "filesystem" &
PID_5=$!

install_npm_package "@playwright/mcp" "playwright" &
PID_6=$!

install_npm_package "@modelcontextprotocol/server-sequential-thinking" "sequential-thinking" &
PID_7=$!

install_npm_package "@modelcontextprotocol/server-gdrive" "google-drive" &
PID_8=$!

install_npm_package "@huggingface/mcp-server-huggingface" "huggingface" &
PID_9=$!

# Wait for all installations to complete
log "Waiting for installations to complete..."
wait $PID_1 $PID_2 $PID_3 $PID_4 $PID_5 $PID_6 $PID_7 $PID_8 $PID_9 2>/dev/null || true

echo ""
log "Parallel installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 4: Verification
# ═══════════════════════════════════════════════════════════════════

log "🔍 Running verification checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# Check Claude Code
if command -v claude &> /dev/null; then
    success "Claude Code: $(claude --version 2>&1 | head -1)"
    ((PASS_COUNT++))
else
    error "Claude Code: Not found"
    ((FAIL_COUNT++))
fi

# Check SuperClaude
if python3 -m SuperClaude --version &> /dev/null 2>&1; then
    success "SuperClaude: $(python3 -m SuperClaude --version 2>&1 | head -1)"
    ((PASS_COUNT++))
else
    warn "SuperClaude: Not available (optional)"
fi

# Check .claude.json
if [ -f "$HOME/.claude.json" ]; then
    MCP_COUNT=$(grep -c '"command"' "$HOME/.claude.json" 2>/dev/null || echo "0")
    success ".claude.json: Found ($MCP_COUNT MCP servers configured)"
    ((PASS_COUNT++))
else
    error ".claude.json: Missing"
    ((FAIL_COUNT++))
fi

# Check MCP packages (sample)
MCP_INSTALLED=0
MCP_FAILED=0

if npm list -g mcp-installer &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if npm list -g @modelcontextprotocol/server-brave-search &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if npm list -g @modelcontextprotocol/server-github &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if python3 -m pip show mcp-server-fetch &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi

if [ $MCP_INSTALLED -ge 3 ]; then
    success "MCP Servers: $MCP_INSTALLED installed, $MCP_FAILED failed"
    ((PASS_COUNT++))
else
    error "MCP Servers: $MCP_INSTALLED installed, $MCP_FAILED failed (minimum 3 required)"
    ((FAIL_COUNT++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════

log "📊 INSTALLATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   ✅ Passed:  $PASS_COUNT checks"
echo "   ❌ Failed:  $FAIL_COUNT checks"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    success "PERFECT! Everything installed successfully!"
elif [ $FAIL_COUNT -le 2 ]; then
    warn "Installation complete with minor issues. Review above."
else
    error "Installation completed with errors. Review above."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 NEXT STEPS:"
echo "   • Type 'claude --version' to verify"
echo "   • Type 'check_secrets' to verify API keys"
echo "   • Type 'check_sessions' to verify session directory"
echo "   • Type 'claude' to start!"
echo ""
echo "💡 Session resume is enabled at: ~/.claude-sessions"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Cancel the script timeout
kill $SCRIPT_TIMEOUT_PID 2>/dev/null || true

# Clean up temp log directory if installation was successful
if [ $FAIL_COUNT -eq 0 ]; then
    rm -rf "$TEMP_LOG_DIR"
else
    log "Installation logs saved in: $TEMP_LOG_DIR"
fi

log "Installation script completed in $(( SECONDS / 60 ))m $(( SECONDS % 60 ))s"
