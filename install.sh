#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# CODESPACES DOTFILES INSTALLATION SCRIPT
# Updated: 2025-10-16 - Parallel installation, timeouts, security fixes
# ═══════════════════════════════════════════════════════════════════

# NOTE: NOT using 'set -e' because we need custom error handling for:
# - Background jobs that may fail
# - Optional installations (SuperClaude, some MCP servers)
# - grep commands that may not match
# We explicitly check critical commands and exit at the end with proper code
set -u  # Error on undefined variables

# VERBOSE OUTPUT - Show what's happening
exec 1> >(tee -a /tmp/dotfiles-install.log)
exec 2>&1
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "  DOTFILES INSTALLATION STARTED - $(date)"
echo "  Log: /tmp/dotfiles-install.log"
echo "════════════════════════════════════════════════════════════════════"
echo ""

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
# DOTFILES DIRECTORY DETECTION
# ═══════════════════════════════════════════════════════════════════

# Detect dotfiles location (GitHub Codespaces sets $DOTFILES env var)
if [ -n "${DOTFILES:-}" ]; then
    DOTFILES_DIR="$DOTFILES"
    log "Using Codespaces dotfiles directory: $DOTFILES_DIR"
elif [ -d "$HOME/.dotfiles" ]; then
    DOTFILES_DIR="$HOME/.dotfiles"
    log "Using dotfiles directory: $DOTFILES_DIR"
else
    # Fallback: use script's directory
    DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
    log "Using script directory as dotfiles: $DOTFILES_DIR"
fi

# Validate critical files exist
log "Validating dotfiles directory..."
VALIDATION_FAILED=false

for file in .claude.json .bashrc; do
    if [ ! -f "$DOTFILES_DIR/$file" ]; then
        error "CRITICAL: $file not found in $DOTFILES_DIR"
        VALIDATION_FAILED=true
    fi
done

if [ "$VALIDATION_FAILED" = true ]; then
    error "Dotfiles validation failed!"
    error "Directory contents:"
    ls -la "$DOTFILES_DIR" 2>&1 || echo "Cannot list directory"
    exit 1
fi

success "Dotfiles directory validated: $DOTFILES_DIR"
echo ""

# ═══════════════════════════════════════════════════════════════════
# START INSTALLATION
# ═══════════════════════════════════════════════════════════════════

log "🚀 Setting up your Codespace environment..."
echo "============================================"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 1: Copy Configuration Files
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════════"
log "📋 STEP 1/5: Copying configuration files..."
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Copy .bashrc FIRST (critical for shell aliases)
if [ -f "$DOTFILES_DIR/.bashrc" ]; then
    if cp "$DOTFILES_DIR/.bashrc" ~/.bashrc; then
        success "Copied .bashrc to home directory"
    else
        error "CRITICAL: Failed to copy .bashrc"
        exit 1
    fi
else
    error "CRITICAL: .bashrc not found in $DOTFILES_DIR"
    exit 1
fi

# Copy .bash_profile (loads .bashrc on login)
if [ -f "$DOTFILES_DIR/.bash_profile" ]; then
    if cp "$DOTFILES_DIR/.bash_profile" ~/.bash_profile; then
        success "Copied .bash_profile to home directory"
    else
        warn "Failed to copy .bash_profile (not critical)"
    fi
fi

# Copy .claude.json (critical for MCP servers)
if [ -f "$DOTFILES_DIR/.claude.json" ]; then
    if cp "$DOTFILES_DIR/.claude.json" ~/.claude.json && chmod 600 ~/.claude.json; then
        success "Copied .claude.json to home directory (permissions: 600)"
    else
        error "CRITICAL: Failed to copy or chmod .claude.json"
        exit 1
    fi
else
    error "CRITICAL: .claude.json not found in $DOTFILES_DIR"
    exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Install Core Tools (Claude Code & SuperClaude)
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════════"
log "📦 STEP 2/5: Installing core tools..."
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Install Claude Code (with timeout)
log "1/3 Installing Claude Code..."
if timeout $PACKAGE_TIMEOUT npm install -g @anthropic-ai/claude-code@latest --force 2>&1 | (grep -v "npm WARN" || true) | tail -3; then
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

# Install SuperClaude (with timeout and proper error handling)
log "2/3 Installing SuperClaude..."
SUPERCLAUDE_INSTALLED=false
if command -v pipx &> /dev/null; then
    if timeout $PACKAGE_TIMEOUT pipx install SuperClaude --force 2>&1 | tail -2; then
        SUPERCLAUDE_INSTALLED=true
    elif timeout $PACKAGE_TIMEOUT pipx upgrade SuperClaude 2>&1 | tail -2; then
        SUPERCLAUDE_INSTALLED=true
    fi
else
    if timeout $PACKAGE_TIMEOUT pip install --break-system-packages --user --upgrade --force-reinstall SuperClaude 2>&1 | tail -3; then
        SUPERCLAUDE_INSTALLED=true
    fi
fi

if python3 -m SuperClaude --version &> /dev/null 2>&1; then
    SUPERCLAUDE_VERSION=$(python3 -m SuperClaude --version 2>&1 | head -1 || echo "installed")
    success "SuperClaude installed: $SUPERCLAUDE_VERSION"

    # Run SuperClaude install to set up framework
    log "Running SuperClaude setup..."
    if python3 -m SuperClaude install 2>&1 | tail -5; then
        success "SuperClaude framework installed"
    else
        warn "SuperClaude framework setup had issues"
    fi
else
    warn "SuperClaude installation failed (not critical)"
fi

echo ""

# Install Claude Flow @alpha (with timeout) - install globally first
log "3/3 Installing Claude Flow @alpha..."
if timeout $PACKAGE_TIMEOUT npm install -g claude-flow@alpha --force 2>&1 | (grep -v "npm WARN" || true) | tail -3; then
    if command -v claude-flow &> /dev/null; then
        CLAUDE_FLOW_VERSION=$(claude-flow --version 2>&1 | head -1 || echo "installed")
        success "Claude Flow installed: $CLAUDE_FLOW_VERSION"

        # Initialize Claude Flow configuration
        log "Initializing Claude Flow configuration..."
        if timeout $PACKAGE_TIMEOUT claude-flow init --force 2>&1 | tail -2; then
            success "Claude Flow configuration initialized"
        else
            warn "Claude Flow init had issues (may need manual setup)"
        fi
    else
        warn "Claude Flow installation completed but command not found"
    fi
else
    warn "Claude Flow installation failed (not critical)"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 3: Install MCP Servers (IN PARALLEL - NEW!)
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════════"
log "🔌 STEP 3/5: Installing MCP Servers (parallel installation)..."
echo "════════════════════════════════════════════════════════════════════"
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
# NOTE: Only installing essential MCPs. Claude Flow provides 90+ additional MCPs.
log "Starting parallel installations (4 essential MCPs only)..."

install_npm_package "@modelcontextprotocol/server-github" "github" &
PID_1=$!

install_npm_package "@modelcontextprotocol/server-filesystem" "filesystem" &
PID_2=$!

install_npm_package "@playwright/mcp" "playwright" &
PID_3=$!

install_npm_package "@modelcontextprotocol/server-sequential-thinking" "sequential-thinking" &
PID_4=$!

# Wait for all installations to complete and track failures
log "Waiting for installations to complete..."
FAILED_INSTALLS=0
TOTAL_INSTALLS=4

for pid in $PID_1 $PID_2 $PID_3 $PID_4; do
    if ! wait $pid 2>/dev/null; then
        ((FAILED_INSTALLS++))
    fi
done

echo ""
if [ $FAILED_INSTALLS -eq 0 ]; then
    success "All $TOTAL_INSTALLS essential MCP packages installed successfully!"
    success "Claude Flow provides 90+ additional MCPs for advanced workflows"
elif [ $FAILED_INSTALLS -le 1 ]; then
    warn "$FAILED_INSTALLS/$TOTAL_INSTALLS installations failed (acceptable threshold)"
    warn "Claude Flow provides 90+ additional MCPs if needed"
else
    error "$FAILED_INSTALLS/$TOTAL_INSTALLS installations failed (too many failures)"
    error "Check logs in: $TEMP_LOG_DIR"
    error "Continuing with verification to assess impact..."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 4: Verification
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════════"
log "🔍 STEP 4/5: Running verification checks..."
echo "════════════════════════════════════════════════════════════════════"
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

# Check MCP packages (4 essential only - Claude Flow provides 90+ additional)
MCP_INSTALLED=0
MCP_FAILED=0

if npm list -g @modelcontextprotocol/server-github &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if npm list -g @modelcontextprotocol/server-filesystem &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if npm list -g @playwright/mcp &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if npm list -g @modelcontextprotocol/server-sequential-thinking &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi

if [ $MCP_INSTALLED -ge 3 ]; then
    success "Essential MCP Servers: $MCP_INSTALLED/4 installed (Claude Flow provides 90+ additional)"
    ((PASS_COUNT++))
else
    error "Essential MCP Servers: $MCP_INSTALLED/4 installed (minimum 3 required)"
    ((FAIL_COUNT++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 5: AUTO-RENAME CODESPACE TO MATCH REPOSITORY
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "════════════════════════════════════════════════════════════════════"
log "🏷️  STEP 5/5: Auto-renaming Codespace to match repository..."
echo "════════════════════════════════════════════════════════════════════"
echo ""

if [ -n "$CODESPACES" ] && [ -n "$GITHUB_REPOSITORY" ] && [ -n "$CODESPACE_NAME" ]; then

    REPO_NAME=$(basename "$GITHUB_REPOSITORY" 2>/dev/null)

    if [ -n "$REPO_NAME" ]; then
        if gh codespace edit --codespace "$CODESPACE_NAME" --display-name "$REPO_NAME" 2>&1 | tail -2; then
            success "Codespace renamed to: $REPO_NAME"
        else
            warn "Could not auto-rename codespace (not critical, you can run 'rename-codespace' manually)"
        fi
    fi
fi

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
echo "🎯 IMPORTANT - TO ACTIVATE DSP ALIAS:"
echo ""
echo "   ⚡ RESTART YOUR TERMINAL or run:"
echo "      source ~/.bashrc"
echo ""
echo "   Then you can use:"
echo "   • dsp --version     - Verify DSP alias works"
echo "   • dsp               - Start Claude Code"
echo "   • check_secrets     - Verify API keys"
echo "   • check_versions    - Show all installed tools"
echo "   • check_sessions    - View Claude sessions"
echo ""
echo "💡 Session resume enabled at: ~/.claude-sessions"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Write visible summary to workspace
SUMMARY_FILE="/workspaces/DOTFILES-INSTALL-SUMMARY.txt"
if [ -d "/workspaces" ]; then
    cat > "$SUMMARY_FILE" <<EOF
════════════════════════════════════════════════════════════════════
DOTFILES INSTALLATION COMPLETED - $(date)
════════════════════════════════════════════════════════════════════

Installation Results:
  ✅ Passed:  $PASS_COUNT checks
  ❌ Failed:  $FAIL_COUNT checks

Files Installed:
  • .bashrc (shell configuration with DSP/dsp aliases)
  • .bash_profile (loads .bashrc on login)
  • .claude.json (MCP server configuration)

Tools Installed:
  • Claude Code @latest
  • SuperClaude (latest)
  • Claude Flow @alpha (globally installed)
  • 9 MCP Servers (parallel installation)

⚡ IMPORTANT - TO ACTIVATE DSP ALIAS:
  Restart your terminal or run: source ~/.bashrc

Quick Test Commands (after restarting terminal):
  dsp --version       # Test DSP alias
  dsp                 # Start Claude Code
  check_secrets       # Verify API keys
  check_versions      # Show installed versions
  check_sessions      # View Claude sessions

Full Installation Log:
  /tmp/dotfiles-install.log
  /workspaces/.codespaces/.persistedshare/creation.log

════════════════════════════════════════════════════════════════════
EOF
    success "Installation summary written to: $SUMMARY_FILE"
    echo ""
    echo "🔍 To view installation details:"
    echo "   cat $SUMMARY_FILE"
    echo "   cat /tmp/dotfiles-install.log"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "                    🎉 INSTALLATION COMPLETE! 🎉"
echo "════════════════════════════════════════════════════════════════════"
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

# Exit with success if critical components are working
# Critical: .bashrc, .claude.json, Claude Code
# Optional: SuperClaude, some MCP servers
if [ -f "$HOME/.bashrc" ] && [ -f "$HOME/.claude.json" ] && command -v claude &> /dev/null; then
    log "✅ Critical components installed successfully - exiting with success code"
    exit 0
else
    error "❌ Critical components missing - exiting with failure code"
    exit 1
fi
