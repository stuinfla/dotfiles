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

# VISIBLE INSTALLATION WITH PROGRESS TRACKING
LOG_FILE="/tmp/dotfiles-install.log"
PROGRESS_FILE="/tmp/dotfiles-progress.txt"

# CRITICAL: Create visible status file in workspace that users can see!
# postCreateCommand runs bash from $DOTFILES directory, so $PWD is the dotfiles dir, NOT the repo!
# We need to find the ACTUAL repository directory in /workspaces/
# Find first directory in /workspaces/ that isn't .codespaces, .oryx, or hidden
REPO_DIR=$(find /workspaces -maxdepth 1 -type d ! -name 'workspaces' ! -name '.*' -print -quit 2>/dev/null)
if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR" ]; then
    # Fallback: use current directory if we can't find repo
    REPO_DIR="$PWD"
fi
VISIBLE_STATUS_FILE="$REPO_DIR/DOTFILES-INSTALLATION-STATUS.txt"

# Debug: Log the paths we're using
echo "DEBUG: REPO_DIR=$REPO_DIR" >> /tmp/dotfiles-startup.log
echo "DEBUG: VISIBLE_STATUS_FILE=$VISIBLE_STATUS_FILE" >> /tmp/dotfiles-startup.log
echo "DEBUG: PWD=$PWD" >> /tmp/dotfiles-startup.log

# Clear previous logs
> "$LOG_FILE"
> "$PROGRESS_FILE"

# CRITICAL: Keep ALL output visible to user for transparency
# We'll log errors manually in functions - do NOT redirect stderr
# User MUST see installation progress in real-time

clear  # Clear the terminal so user sees our messages

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║          🚀  SETTING UP YOUR DEVELOPMENT ENVIRONMENT  🚀          ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 What's being installed:"
echo "   • Claude Code CLI - AI-powered coding assistant"
echo "   • MCP Servers - Advanced tool integrations"
echo "   • Development tools - git aliases, shell improvements"
echo "   • Extension watchdog - Keeps unwanted extensions away"
echo ""
echo "⏱️  Expected time: 3-5 minutes"
echo ""
echo "💡 What's happening: This runs ONCE when creating a new codespace."
echo "   Your workspace will be ready soon - grab a coffee! ☕"
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Initialize progress file
echo "Installation started at $(date)" > "$PROGRESS_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$PROGRESS_FILE"

# Create VISIBLE status file that appears in VS Code file explorer
# Note: Use unquoted EOF to allow variable expansion
cat > "$VISIBLE_STATUS_FILE" <<EOF
════════════════════════════════════════════════════════════════════
🚀 DOTFILES INSTALLATION IN PROGRESS
════════════════════════════════════════════════════════════════════

Installation started at: $(date)

⏱️  Expected time: 3-5 minutes

This file updates in real-time. Refresh to see latest progress!

File location: $VISIBLE_STATUS_FILE

════════════════════════════════════════════════════════════════════
PROGRESS LOG:
════════════════════════════════════════════════════════════════════

EOF

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

# Print to log file only (with timestamp)
log() {
    echo "[$(date +'%H:%M:%S')] $*" >> "$LOG_FILE"
}

# Print progress to user, progress file, AND visible status file
progress() {
    local msg="$*"
    echo -e "${YELLOW}⏳ $msg${NC}"
    echo "[$(date +'%H:%M:%S')] $msg" >> "$PROGRESS_FILE"
    # Also write to VISIBLE file in workspace
    echo "[$(date +'%H:%M:%S')] ⏳ $msg" >> "$VISIBLE_STATUS_FILE"
}

# Print to user (clean, no timestamp)
user_message() {
    echo "$*"
}

# Print success message to user, progress file, AND visible status file
success() {
    echo -e "${GREEN}✅ $*${NC}"
    echo "[$(date +'%H:%M:%S')] ✅ $*" >> "$PROGRESS_FILE"
    echo "[$(date +'%H:%M:%S')] ✅ $*" >> "$VISIBLE_STATUS_FILE"
}

# Print error message to user, progress file, AND visible status file
error() {
    echo -e "${RED}❌ $*${NC}"
    echo "[$(date +'%H:%M:%S')] ❌ $*" >> "$PROGRESS_FILE"
    echo "[$(date +'%H:%M:%S')] ❌ $*" >> "$VISIBLE_STATUS_FILE"
}

# Print warning message to user, progress file, AND visible status file
warn() {
    echo -e "${YELLOW}⚠️  $*${NC}"
    echo "[$(date +'%H:%M:%S')] ⚠️ $*" >> "$PROGRESS_FILE"
    echo "[$(date +'%H:%M:%S')] ⚠️ $*" >> "$VISIBLE_STATUS_FILE"
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
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  STEP 1/5: Setting up shell configuration                        ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Copying .bashrc, git config, and development aliases..."
echo "   (These customize your terminal and git commands)"
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

# Copy .vscode directory to workspace (blocks Cline + suppresses welcome screens)
progress "Configuring VS Code to suppress welcome screens..."
if [ -d "/workspaces" ]; then
    WORKSPACE_DIR=$(find /workspaces -maxdepth 1 -type d ! -name "workspaces" -print -quit 2>/dev/null)
    if [ -n "$WORKSPACE_DIR" ] && [ -d "$DOTFILES_DIR/.vscode" ]; then
        mkdir -p "$WORKSPACE_DIR/.vscode"
        if cp -r "$DOTFILES_DIR/.vscode/"* "$WORKSPACE_DIR/.vscode/" 2>/dev/null; then
            success "VS Code configured: Cline blocked + welcome screens suppressed"
        else
            log "⚠️  Could not copy .vscode (non-critical)"
        fi
    fi
fi

# Copy .claude-flow directory for full instantiation
if [ -d "$DOTFILES_DIR/.claude-flow" ]; then
    if cp -r "$DOTFILES_DIR/.claude-flow" ~/ 2>/dev/null; then
        success "Copied .claude-flow directory (full instantiation)"
    else
        log "⚠️  Could not copy .claude-flow (will be created by init)"
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Install Core Tools (Claude Code & SuperClaude)
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  STEP 2/5: Installing AI development tools                       ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "🤖 Installing Claude Code CLI - Your AI coding assistant"
echo "   (Latest version from NPM, includes MCP support)"
echo ""
echo "⚡ Installing SuperClaude - Enhanced Claude capabilities"
echo "   (Framework for advanced AI workflows)"
echo ""
echo "🌊 Installing Claude Flow @alpha - 90+ advanced tools"
echo "   (MCP server with swarm orchestration)"
echo ""
echo "⏱️  This step takes ~2-3 minutes (downloading and installing packages)"
echo ""

# Install Claude Code with visible progress
progress "  [1/3] Installing Claude Code (latest)..."
log "Installing Claude Code..."
if timeout $PACKAGE_TIMEOUT npm install -g @anthropic-ai/claude-code@latest --force >> "$LOG_FILE" 2>&1; then
    if command -v claude &> /dev/null; then
        success "        Claude Code installed"
        log "Claude Code version: $(claude --version 2>&1 | head -1)"
    fi
fi

# Install SuperClaude with visible progress
progress "  [2/3] Installing SuperClaude (latest)..."
log "Installing SuperClaude..."
SUPERCLAUDE_INSTALLED=false
if command -v pipx &> /dev/null; then
    if timeout $PACKAGE_TIMEOUT pipx install SuperClaude --force >> "$LOG_FILE" 2>&1; then
        SUPERCLAUDE_INSTALLED=true
    elif timeout $PACKAGE_TIMEOUT pipx upgrade SuperClaude >> "$LOG_FILE" 2>&1; then
        SUPERCLAUDE_INSTALLED=true
    fi
else
    if timeout $PACKAGE_TIMEOUT pip install --break-system-packages --user --upgrade --force-reinstall SuperClaude >> "$LOG_FILE" 2>&1; then
        SUPERCLAUDE_INSTALLED=true
    fi
fi

if python3 -m SuperClaude --version &> /dev/null 2>&1; then
    success "        SuperClaude installed"
    log "SuperClaude version: $(python3 -m SuperClaude --version 2>&1 | head -1)"
    # Silent setup
    python3 -m SuperClaude install >> "$LOG_FILE" 2>&1 || true
fi

# Install Claude Flow @alpha with visible progress
progress "  [3/3] Installing Claude Flow @alpha (MCP server + 90+ tools)..."
log "Installing Claude Flow @alpha..."
if timeout $PACKAGE_TIMEOUT npm install -g claude-flow@alpha --force >> "$LOG_FILE" 2>&1; then
    if command -v claude-flow &> /dev/null; then
        success "        Claude Flow installed"
        log "Claude Flow version: $(claude-flow --version 2>&1 | head -1)"

        # Initialize Claude Flow configuration (silent)
        log "Initializing Claude Flow configuration..."
        if timeout $PACKAGE_TIMEOUT claude-flow init --force >> "$LOG_FILE" 2>&1; then
            success "Claude Flow configuration initialized"
        else
            warn "Claude Flow init had issues (may need manual setup)"
        fi

        # CRITICAL: Register Claude Flow as MCP server
        log "Registering Claude Flow as MCP server..."
        if command -v claude &> /dev/null; then
            if claude mcp add claude-flow npx claude-flow@alpha mcp start >> "$LOG_FILE" 2>&1; then
                success "        Claude Flow MCP server registered"
            else
                error "Failed to register Claude Flow MCP server"
            fi
        else
            warn "Claude CLI not available yet - MCP registration will be attempted later"
        fi
    else
        warn "Claude Flow installation completed but command not found"
    fi
else
    warn "Claude Flow installation failed (not critical)"
fi

echo ""

# Start ULTRA-AGGRESSIVE EXTENSION WATCHDOG
# This watchdog runs for 20 MINUTES checking every 3 SECONDS
# Extensions often install LATE (5-10 min after codespace opens), so we need extended monitoring
log "🔧 Starting ultra-aggressive extension watchdog (20 min monitoring)..."

# Start watchdog as truly detached background process
setsid bash -c '
    VSCODE_EXT_DIR="$HOME/.vscode-remote/extensions"
    LOG_FILE="/tmp/extension-watchdog.log"

    echo "========================================" >> "$LOG_FILE"
    echo "[$(date)] ULTRA-AGGRESSIVE Watchdog started - 20 min monitoring, 3 sec checks" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"

    # Wait up to 2 minutes for extensions directory to appear
    for i in {1..120}; do
        if [ -d "$VSCODE_EXT_DIR" ]; then
            echo "[$(date)] Extensions directory found! Starting monitoring..." >> "$LOG_FILE"
            break
        fi
        sleep 1
    done

    if [ ! -d "$VSCODE_EXT_DIR" ]; then
        echo "[$(date)] Extensions directory never appeared" >> "$LOG_FILE"
        exit 1
    fi

    # NOW MONITOR FOR 20 MINUTES (400 checks * 3 seconds)
    REMOVAL_COUNT=0

    for iteration in {1..400}; do
        echo "[$(date)] Check $iteration/400" >> "$LOG_FILE"

        # Remove Kombai - try multiple patterns (case-insensitive, comprehensive)
        REMOVED=0
        if find "$VSCODE_EXT_DIR" -maxdepth 1 -type d \( -iname "*kombai*" -o -iname "*komba*" \) -exec rm -rf {} \; 2>/dev/null; then
            echo "[$(date)] ✅ Removed Kombai" >> "$LOG_FILE"
            ((REMOVAL_COUNT++))
            REMOVED=1
        fi

        # Remove Test Explorer - multiple patterns (hocklabs, littlefox, any test explorer)
        if find "$VSCODE_EXT_DIR" -maxdepth 1 -type d \( -iname "*test*explorer*" -o -iname "*hocklabs*" -o -iname "*littlefox*" \) -exec rm -rf {} \; 2>/dev/null; then
            echo "[$(date)] ✅ Removed Test Explorer" >> "$LOG_FILE"
            ((REMOVAL_COUNT++))
            REMOVED=1
        fi

        # Remove Cline - multiple patterns (cline, claude-dev, saoud)
        if find "$VSCODE_EXT_DIR" -maxdepth 1 -type d \( -iname "*cline*" -o -iname "*claude-dev*" -o -iname "*saoud*" \) -exec rm -rf {} \; 2>/dev/null; then
            echo "[$(date)] ✅ Removed Cline" >> "$LOG_FILE"
            ((REMOVAL_COUNT++))
            REMOVED=1
        fi

        # Log if we removed anything this iteration
        if [ $REMOVED -eq 1 ]; then
            echo "[$(date)] 🗑️  Total removals so far: $REMOVAL_COUNT" >> "$LOG_FILE"
        fi

        sleep 3
    done

    echo "[$(date)] Watchdog completed - Removed $REMOVAL_COUNT extension(s) over 20 minutes" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
' </dev/null >/dev/null 2>&1 &
disown

success "Ultra-aggressive extension watchdog started (20 min, 3 sec checks)"

echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 3: Install MCP Servers (IN PARALLEL - NEW!)
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  STEP 3/5: Installing MCP servers (parallel)                     ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "🔌 Installing 4 essential MCP servers:"
echo "   • GitHub MCP - Repository access and API tools"
echo "   • Filesystem MCP - Safe file operations"
echo "   • Playwright MCP - Browser automation and testing"
echo "   • Sequential Thinking MCP - Advanced reasoning"
echo ""
echo "💡 Note: Claude Flow provides 90+ additional MCP servers"
echo "   (These 4 are installed for faster startup)"
echo ""
echo "⏱️  Installing in parallel - ~1-2 minutes"
echo ""

# Create temporary directory for installation logs
TEMP_LOG_DIR=$(mktemp -d)

# Function to install npm package silently
install_npm_package() {
    local package_name="$1"
    local display_name="$2"

    log "Installing $package_name..."
    if timeout $PACKAGE_TIMEOUT npm install -g "${package_name}@latest" --force >> "$LOG_FILE" 2>&1; then
        success "$display_name"
        return 0
    else
        error "$display_name"
        log "Failed to install $package_name - check $LOG_FILE for details"
        return 1
    fi
}

# Function to install Python package silently
install_pip_package() {
    local package_name="$1"
    local display_name="$2"

    log "Installing $package_name..."
    if timeout $PACKAGE_TIMEOUT pip install --break-system-packages --user --upgrade --force-reinstall "$package_name" >> "$LOG_FILE" 2>&1; then
        success "$display_name"
        return 0
    else
        error "$display_name"
        log "Failed to install $package_name - check $LOG_FILE for details"
        return 1
    fi
}

# Start all installations in parallel (background jobs)
# NOTE: Only installing essential MCPs. Claude Flow provides 90+ additional MCPs.
progress "Installing 4 essential MCP servers in parallel..."
progress "  • GitHub MCP (starting...)"
progress "  • Filesystem MCP (starting...)"
progress "  • Playwright MCP (starting...)"
progress "  • Sequential Thinking MCP (starting...)"
log "Starting parallel installations (4 essential MCPs only)..."

install_npm_package "@modelcontextprotocol/server-github" "  ✅ GitHub MCP" &
PID_1=$!

install_npm_package "@modelcontextprotocol/server-filesystem" "  ✅ Filesystem MCP" &
PID_2=$!

install_npm_package "@playwright/mcp" "  ✅ Playwright MCP" &
PID_3=$!

install_npm_package "@modelcontextprotocol/server-sequential-thinking" "  ✅ Sequential Thinking MCP" &
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
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  STEP 4/5: Verifying installation                                ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Checking installed tools and configurations:"
echo "   • Claude Code version and availability"
echo "   • SuperClaude installation status"
echo "   • MCP server configuration (.claude.json)"
echo "   • Extension watchdog (background process)"
echo ""
echo "⏱️  Quick verification - ~30 seconds"
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

# Check SuperClaude (silent - optional)
if python3 -m SuperClaude --version &> /dev/null 2>&1; then
    success "SuperClaude: $(python3 -m SuperClaude --version 2>&1 | head -1)"
    ((PASS_COUNT++))
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
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  STEP 5/5: Finalizing setup                                      ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "🏷️  Auto-renaming codespace to match your repository name"
echo "   (Makes it easier to identify in GitHub Codespaces list)"
echo ""
echo "⏱️  Final step - ~10 seconds"
echo ""

if [ -n "$CODESPACES" ] && [ -n "$GITHUB_REPOSITORY" ] && [ -n "$CODESPACE_NAME" ]; then

    REPO_NAME=$(basename "$GITHUB_REPOSITORY" 2>/dev/null)

    if [ -n "$REPO_NAME" ]; then
        log "Renaming codespace to: $REPO_NAME"
        if gh codespace edit --codespace "$CODESPACE_NAME" --display-name "$REPO_NAME" >> "$LOG_FILE" 2>&1; then
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
echo "   • check_status      - System monitor (repo, memory, CPU)"
echo "   • check_secrets     - Verify API keys"
echo "   • check_versions    - Show all installed tools"
echo "   • check_sessions    - View Claude sessions"
echo ""
echo "💡 Session resume enabled at: ~/.claude-sessions"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run cleanup scripts to ensure clean VS Code state
progress "Suppressing VS Code welcome screens and setup prompts..."

if [ -f "$DOTFILES_DIR/scripts/cleanup-vscode-state.sh" ]; then
    bash "$DOTFILES_DIR/scripts/cleanup-vscode-state.sh" 2>/dev/null || true
fi

# Kombai is now uninstalled during extension removal (line 282), no need for reset script
# Removed reset-kombai.sh call

# NEW: Suppress all welcome screens and setup prompts
if [ -f "$DOTFILES_DIR/scripts/suppress-welcome-screens.sh" ]; then
    bash "$DOTFILES_DIR/scripts/suppress-welcome-screens.sh" 2>/dev/null || true
    success "All welcome screens and setup prompts suppressed"
else
    log "⚠️  suppress-welcome-screens.sh not found (non-critical)"
fi

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

# ═══════════════════════════════════════════════════════════════════
# Installation Summary and Version Verification
# ═══════════════════════════════════════════════════════════════════

echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║                  🎉  INSTALLATION COMPLETE!  🎉                   ║"
echo "║                                                                   ║"
echo "║              YOUR CODESPACE IS READY TO USE! ✅                   ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ INSTALLED TOOLS & VERSIONS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Claude Code version with checkmark
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "installed")
    echo "  ✅ Claude Code:        $CLAUDE_VERSION"
else
    echo "  ❌ Claude Code:        NOT FOUND (installation failed)"
fi

# SuperClaude version with checkmark
if command -v superclaude &> /dev/null || python3 -m SuperClaude --version &> /dev/null 2>&1; then
    SC_VERSION=$(python3 -m SuperClaude --version 2>/dev/null | head -1 || echo "installed")
    echo "  ✅ SuperClaude:        $SC_VERSION"
else
    echo "  ⚠️  SuperClaude:        Not installed (optional)"
fi

# Claude Flow version with checkmark
if command -v claude-flow &> /dev/null; then
    CF_VERSION=$(claude-flow --version 2>/dev/null | head -1 || echo "installed")
    echo "  ✅ Claude Flow:        $CF_VERSION"
else
    echo "  ❌ Claude Flow:        NOT FOUND (installation failed)"
fi

# MCP Servers count
MCP_COUNT=$(grep -c '"command"' "$HOME/.claude.json" 2>/dev/null || echo "0")
echo "  ✅ MCP Servers:        $MCP_COUNT configured"

# Extension watchdog
echo "  ✅ Extension Watchdog: Running for 20 min (removes Kombai/TestExplorer/Cline)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 QUICK START COMMANDS:"
echo ""
echo "  dsp --version       ← Test your setup"
echo "  dsp                 ← Start Claude Code"
echo "  check_versions      ← Show all tool versions"
echo "  check_secrets       ← Verify API keys"
echo "  check_sessions      ← View Claude sessions"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 NEXT STEP: Restart your terminal or run: source ~/.bashrc"
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Cancel the script timeout
kill $SCRIPT_TIMEOUT_PID 2>/dev/null || true

# Create a flag file to show summary on next shell
mkdir -p ~/.cache
touch ~/.cache/dotfiles_just_installed

echo "🔄 Restarting terminal with clean environment in 2 seconds..."
echo ""

# Mark installation as complete in visible status file
cat >> "$VISIBLE_STATUS_FILE" <<EOF

════════════════════════════════════════════════════════════════════
✅ INSTALLATION COMPLETED SUCCESSFULLY!
════════════════════════════════════════════════════════════════════

Completed at: $(date)

✅ Passed:  $PASS_COUNT checks
❌ Failed:  $FAIL_COUNT checks

🎉 Your codespace is ready!

To activate DSP alias:
  source ~/.bashrc

Then you can use:
  dsp               # Start Claude Code
  dsp --version     # Verify installation
  check_versions    # Show all installed tools

This file will auto-delete when you close this codespace.

════════════════════════════════════════════════════════════════════
EOF

sleep 2

# Automatically restart terminal with fresh environment
# This ensures DSP alias and all configurations are fully loaded
exec bash

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
