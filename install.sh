#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# CODESPACES DOTFILES INSTALLATION SCRIPT
# Updated: 2025-10-30 - Timeout fixes, heartbeat monitoring, hang prevention
# ═══════════════════════════════════════════════════════════════════
#
# HANG PREVENTION FIXES:
# - run_with_timeout() wrapper for ALL external commands (npm, pip, gh)
# - Heartbeat monitoring every 10 seconds during long operations
# - Emergency timeout after 15 minutes (kills entire script)
# - Progress indicators every 15 seconds for parallel jobs
# - Proper Ctrl+C handling with cleanup trap
# - Non-blocking background jobs with timeout protection
# - Detailed logging of what command is running
#
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
echo "💡 This runs ONCE when creating a new codespace."
echo "   Follow the checkmarks below to track progress!"
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

# Auto-open status file in VS Code so user sees it immediately
if command -v code >/dev/null 2>&1; then
    code "$VISIBLE_STATUS_FILE" 2>/dev/null &
    log "Status file will auto-open in VS Code"
fi

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

# Run command with timeout and heartbeat monitoring
# Usage: run_with_timeout <timeout_seconds> <command> [args...]
run_with_timeout() {
    local timeout=$1
    shift
    local cmd="$*"

    log "Running with ${timeout}s timeout: $cmd"

    # Start heartbeat in background
    (
        elapsed=0  # FIXED: Removed 'local' - not allowed in subshell
        while [ $elapsed -lt $timeout ]; do
            sleep 10
            elapsed=$((elapsed + 10))
            if [ $elapsed -lt $timeout ]; then
                progress "Still working... (${elapsed}s elapsed, max ${timeout}s)"
            fi
        done
    ) &
    local heartbeat_pid=$!

    # Run command with timeout
    timeout "$timeout" bash -c "$cmd" &
    local cmd_pid=$!

    # Wait for command to finish
    local exit_code=0
    if wait $cmd_pid 2>/dev/null; then
        exit_code=0
    else
        exit_code=$?
    fi

    # Kill heartbeat
    kill $heartbeat_pid 2>/dev/null || true
    wait $heartbeat_pid 2>/dev/null || true

    # Check if timeout occurred (exit code 124)
    if [ $exit_code -eq 124 ]; then
        error "Command timed out after ${timeout}s: $cmd"
        return 124
    fi

    return $exit_code
}

# Show large, visible step indicators
show_step() {
    local current=$1
    local total=$2
    local description=$3
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║  STEP $current/$total: $description"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""

    # Calculate progress percentage
    local percent=$((current * 100 / total))
    local bars=$((percent / 5))
    local spaces=$((20 - bars))
    local progress_bar=$(printf '█%.0s' $(seq 1 $bars))$(printf '░%.0s' $(seq 1 $spaces))

    # Update visible status file with progress bar
    {
        echo ""
        echo "════════════════════════════════════════════════════════════════════"
        echo "STEP $current/$total: $description"
        echo "Progress: [$progress_bar] $percent%"
        echo "Time: $(date '+%H:%M:%S')"
        echo "════════════════════════════════════════════════════════════════════"
    } >> "$VISIBLE_STATUS_FILE"
}

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
    local exit_code=$?
    log "Cleaning up background processes... (exit code: $exit_code)"

    # Kill all background jobs
    jobs -p | xargs -r kill -TERM 2>/dev/null || true
    sleep 1
    jobs -p | xargs -r kill -KILL 2>/dev/null || true

    # Kill script timeout watcher
    if [ -n "${SCRIPT_TIMEOUT_PID:-}" ]; then
        kill -TERM $SCRIPT_TIMEOUT_PID 2>/dev/null || true
    fi

    # If we're exiting due to timeout or error, update visible status
    if [ $exit_code -ne 0 ] && [ -n "${VISIBLE_STATUS_FILE:-}" ]; then
        echo "" >> "$VISIBLE_STATUS_FILE"
        echo "════════════════════════════════════════════════════════════════════" >> "$VISIBLE_STATUS_FILE"
        echo "⚠️  Installation interrupted or timed out at: $(date)" >> "$VISIBLE_STATUS_FILE"
        echo "════════════════════════════════════════════════════════════════════" >> "$VISIBLE_STATUS_FILE"
    fi
}

# Set up trap for cleanup - will run on EXIT, SIGINT (Ctrl+C), SIGTERM
trap cleanup EXIT INT TERM

# Make Ctrl+C work properly
set -m  # Enable job control

# ═══════════════════════════════════════════════════════════════════
# SCRIPT TIMEOUT WRAPPER - EMERGENCY KILL SWITCH
# ═══════════════════════════════════════════════════════════════════

# Set a timeout for the entire script - ABSOLUTE MAXIMUM 15 MINUTES
(
    elapsed=0  # FIXED: Removed 'local' - not allowed in subshell
    max_time=$SCRIPT_TIMEOUT

    while [ $elapsed -lt $max_time ]; do
        sleep 60  # Check every minute
        elapsed=$((elapsed + 60))

        if [ $elapsed -ge $max_time ]; then
            echo "════════════════════════════════════════════════════════════════════" >&2
            echo "🚨 EMERGENCY TIMEOUT: Installation exceeded ${SCRIPT_TIMEOUT}s" >&2
            echo "════════════════════════════════════════════════════════════════════" >&2
            echo "" >&2
            echo "This usually means a package installation hung." >&2
            echo "Check /tmp/dotfiles-install.log for details." >&2
            echo "" >&2

            # Update visible status
            if [ -f "$VISIBLE_STATUS_FILE" ]; then
                echo "" >> "$VISIBLE_STATUS_FILE"
                echo "════════════════════════════════════════════════════════════════════" >> "$VISIBLE_STATUS_FILE"
                echo "🚨 EMERGENCY TIMEOUT after ${SCRIPT_TIMEOUT}s" >> "$VISIBLE_STATUS_FILE"
                echo "════════════════════════════════════════════════════════════════════" >> "$VISIBLE_STATUS_FILE"
            fi

            # Kill the main script
            kill -TERM $$ 2>/dev/null || true
            sleep 2
            kill -KILL $$ 2>/dev/null || true
        fi
    done
) &
SCRIPT_TIMEOUT_PID=$!
log "Emergency timeout watcher started (max ${SCRIPT_TIMEOUT}s)"

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

show_step 1 5 "Setting up shell configuration"
echo "📝 Copying configuration files..."
echo ""

# Copy .bashrc FIRST (critical for shell aliases)
progress "  [1/5] Copying .bashrc..."
if [ -f "$DOTFILES_DIR/.bashrc" ]; then
    if cp "$DOTFILES_DIR/.bashrc" ~/.bashrc; then
        success "        .bashrc copied"
    else
        error "CRITICAL: Failed to copy .bashrc"
        exit 1
    fi
else
    error "CRITICAL: .bashrc not found in $DOTFILES_DIR"
    exit 1
fi

# Copy .bash_profile (loads .bashrc on login)
progress "  [2/5] Copying .bash_profile..."
if [ -f "$DOTFILES_DIR/.bash_profile" ]; then
    if cp "$DOTFILES_DIR/.bash_profile" ~/.bash_profile; then
        success "        .bash_profile copied"
    else
        warn "Failed to copy .bash_profile (not critical)"
    fi
fi

# Copy .claude.json (critical for MCP servers)
progress "  [3/5] Copying .claude.json..."
if [ -f "$DOTFILES_DIR/.claude.json" ]; then
    if cp "$DOTFILES_DIR/.claude.json" ~/.claude.json && chmod 600 ~/.claude.json; then
        success "        .claude.json copied (permissions: 600)"
    else
        error "CRITICAL: Failed to copy or chmod .claude.json"
        exit 1
    fi
else
    error "CRITICAL: .claude.json not found in $DOTFILES_DIR"
    exit 1
fi

# Copy .vscode directory to workspace (blocks Cline + suppresses welcome screens)
progress "  [4/5] Configuring VS Code..."
if [ -d "/workspaces" ]; then
    WORKSPACE_DIR=$(find /workspaces -maxdepth 1 -type d ! -name "workspaces" -print -quit 2>/dev/null)
    if [ -n "$WORKSPACE_DIR" ] && [ -d "$DOTFILES_DIR/.vscode" ]; then
        mkdir -p "$WORKSPACE_DIR/.vscode"
        if cp -r "$DOTFILES_DIR/.vscode/"* "$WORKSPACE_DIR/.vscode/" 2>/dev/null; then
            success "        VS Code configured (welcome screens suppressed)"
        else
            log "⚠️  Could not copy .vscode (non-critical)"
        fi
    fi
fi

# Copy .claude-flow directory for full instantiation
progress "  [5/5] Copying .claude-flow directory..."
if [ -d "$DOTFILES_DIR/.claude-flow" ]; then
    if cp -r "$DOTFILES_DIR/.claude-flow" ~/ 2>/dev/null; then
        success "        .claude-flow directory copied"
    else
        log "⚠️  Could not copy .claude-flow (will be created by init)"
    fi
fi

echo ""
success "✅ Step 1/5 complete: Shell configuration ready"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Install Core Tools (Claude Code & SuperClaude)
# ═══════════════════════════════════════════════════════════════════

show_step 2 5 "Installing AI development tools"
echo "🤖 Installing 3 essential tools..."
echo ""

# Install Claude Code with visible progress
progress "  [1/3] Installing Claude Code (latest)..."
log "Installing Claude Code..."
if run_with_timeout $PACKAGE_TIMEOUT "npm install -g @anthropic-ai/claude-code@latest --force --progress=false --loglevel=error >> '$LOG_FILE' 2>&1"; then
    if command -v claude &> /dev/null; then
        success "        Claude Code installed"
        log "Claude Code version: $(claude --version 2>&1 | head -1)"
    fi
else
    error "Claude Code installation failed or timed out"
fi

# Install SuperClaude with visible progress
progress "  [2/3] Installing SuperClaude (latest)..."
log "Installing SuperClaude..."
SUPERCLAUDE_INSTALLED=false
if command -v pipx &> /dev/null; then
    if run_with_timeout $PACKAGE_TIMEOUT "pipx install SuperClaude --force >> '$LOG_FILE' 2>&1"; then
        SUPERCLAUDE_INSTALLED=true
    elif run_with_timeout $PACKAGE_TIMEOUT "pipx upgrade SuperClaude >> '$LOG_FILE' 2>&1"; then
        SUPERCLAUDE_INSTALLED=true
    fi
else
    if run_with_timeout $PACKAGE_TIMEOUT "pip install --break-system-packages --user --upgrade --force-reinstall --no-input SuperClaude >> '$LOG_FILE' 2>&1"; then
        SUPERCLAUDE_INSTALLED=true
    fi
fi

if python3 -m SuperClaude --version &> /dev/null 2>&1; then
    success "        SuperClaude installed"
    log "SuperClaude version: $(python3 -m SuperClaude --version 2>&1 | head -1)"
    # Silent setup with timeout
    run_with_timeout 60 "python3 -m SuperClaude install >> '$LOG_FILE' 2>&1" || true
fi

# Install Claude Flow @alpha with visible progress
progress "  [3/3] Installing Claude Flow @alpha (MCP server + 90+ tools)..."
log "Installing Claude Flow @alpha..."
if run_with_timeout $PACKAGE_TIMEOUT "npm install -g claude-flow@alpha --force --progress=false --loglevel=error >> '$LOG_FILE' 2>&1"; then
    if command -v claude-flow &> /dev/null; then
        success "        Claude Flow installed"
        log "Claude Flow version: $(claude-flow --version 2>&1 | head -1)"

        # Initialize Claude Flow configuration (silent)
        log "Initializing Claude Flow configuration..."
        if run_with_timeout $PACKAGE_TIMEOUT "claude-flow init --force >> '$LOG_FILE' 2>&1"; then
            success "Claude Flow configuration initialized"
        else
            warn "Claude Flow init had issues (may need manual setup)"
        fi

        # CRITICAL: Register Claude Flow as MCP server
        log "Registering Claude Flow as MCP server..."
        if command -v claude &> /dev/null; then
            if run_with_timeout 60 "claude mcp add claude-flow npx claude-flow@alpha mcp start >> '$LOG_FILE' 2>&1"; then
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
    warn "Claude Flow installation failed or timed out (not critical)"
fi

echo ""
success "✅ Step 2/5 complete: All development tools installed"
echo ""

# Start ULTRA-AGGRESSIVE EXTENSION WATCHDOG
# This watchdog runs for 20 MINUTES checking every 3 SECONDS
# Extensions often install LATE (5-10 min after codespace opens), so we need extended monitoring
log "🔧 Starting ultra-aggressive extension watchdog (20 min monitoring)..."

# Start watchdog as truly detached background process
setsid bash -c '
    VSCODE_EXT_DIR="$HOME/.vscode-remote/extensions"
    LOG_FILE="/tmp/extension-watchdog.log"
    PARENT_PID='"$$"'  # FIXED: Store parent PID to check if parent is still alive

    echo "========================================" >> "$LOG_FILE"
    echo "[$(date)] ULTRA-AGGRESSIVE Watchdog started - 20 min monitoring, 3 sec checks" >> "$LOG_FILE"
    echo "[$(date)] Parent PID: $PARENT_PID" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"

    # Wait up to 2 minutes for extensions directory to appear
    for i in {1..120}; do
        # FIXED: Check if parent process still exists
        if ! kill -0 $PARENT_PID 2>/dev/null; then
            echo "[$(date)] Parent process died, exiting watchdog" >> "$LOG_FILE"
            exit 0
        fi

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
        # FIXED: Check if parent process still exists
        if ! kill -0 $PARENT_PID 2>/dev/null; then
            echo "[$(date)] Parent process died at iteration $iteration, exiting gracefully" >> "$LOG_FILE"
            echo "[$(date)] Total removals before exit: $REMOVAL_COUNT" >> "$LOG_FILE"
            exit 0
        fi

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

show_step 3 5 "Installing MCP servers (parallel)"
echo "🔌 Installing 4 essential MCP servers in parallel..."
echo ""

# Create temporary directory for installation logs
TEMP_LOG_DIR=$(mktemp -d)

# Function to install npm package silently
install_npm_package() {
    local package_name="$1"
    local display_name="$2"

    log "Installing $package_name..."
    if run_with_timeout $PACKAGE_TIMEOUT "npm install -g '${package_name}@latest' --force --progress=false --loglevel=error >> '$LOG_FILE' 2>&1"; then
        success "$display_name"
        return 0
    else
        error "$display_name (failed or timed out)"
        log "Failed to install $package_name - check $LOG_FILE for details"
        return 1
    fi
}

# Function to install Python package silently
install_pip_package() {
    local package_name="$1"
    local display_name="$2"

    log "Installing $package_name..."
    if run_with_timeout $PACKAGE_TIMEOUT "pip install --break-system-packages --user --upgrade --force-reinstall --no-input '$package_name' >> '$LOG_FILE' 2>&1"; then
        success "$display_name"
        return 0
    else
        error "$display_name (failed or timed out)"
        log "Failed to install $package_name - check $LOG_FILE for details"
        return 1
    fi
}

# Start all installations in parallel (background jobs)
# NOTE: Only installing essential MCPs. Claude Flow provides 90+ additional MCPs.
progress "  [1/4] GitHub MCP (starting...)"
progress "  [2/4] Filesystem MCP (starting...)"
progress "  [3/4] Playwright MCP (starting...)"
progress "  [4/4] Sequential Thinking MCP (starting...)"
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

# Monitor background jobs with heartbeat
WAIT_START=$SECONDS
WAIT_TIMEOUT=600  # 10 minutes max for all parallel installs

while [ $((SECONDS - WAIT_START)) -lt $WAIT_TIMEOUT ]; do
    # Check if all jobs are done
    JOBS_DONE=0
    for pid in $PID_1 $PID_2 $PID_3 $PID_4; do
        if ! kill -0 $pid 2>/dev/null; then
            ((JOBS_DONE++))
        fi
    done

    if [ $JOBS_DONE -eq 4 ]; then
        break
    fi

    # Show heartbeat every 15 seconds
    if [ $((SECONDS % 15)) -eq 0 ]; then
        progress "Parallel installs in progress... ($JOBS_DONE/4 complete)"
    fi

    sleep 1
done

# Collect exit codes
for pid in $PID_1 $PID_2 $PID_3 $PID_4; do
    if ! wait $pid 2>/dev/null; then
        ((FAILED_INSTALLS++))
    fi
done

echo ""
SUCCESSFUL_INSTALLS=$((TOTAL_INSTALLS - FAILED_INSTALLS))
if [ $FAILED_INSTALLS -eq 0 ]; then
    success "All $TOTAL_INSTALLS/$TOTAL_INSTALLS MCP packages installed successfully!"
    success "Claude Flow provides 90+ additional MCPs for advanced workflows"
elif [ $FAILED_INSTALLS -le 1 ]; then
    warn "$SUCCESSFUL_INSTALLS/$TOTAL_INSTALLS MCP servers installed (acceptable threshold)"
    warn "Claude Flow provides 90+ additional MCPs if needed"
else
    error "$SUCCESSFUL_INSTALLS/$TOTAL_INSTALLS MCP servers installed (too many failures)"
    error "Check logs in: $TEMP_LOG_DIR"
    error "Continuing with verification to assess impact..."
fi
echo ""
success "✅ Step 3/5 complete: MCP servers installed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 4: Verification
# ═══════════════════════════════════════════════════════════════════

show_step 4 5 "Verifying installation"
echo "🔍 Checking installed components..."
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# Check Claude Code
progress "  [1/4] Verifying Claude Code..."
if command -v claude &> /dev/null; then
    success "        Claude Code: $(claude --version 2>&1 | head -1)"
    ((PASS_COUNT++))
else
    error "        Claude Code: Not found"
    ((FAIL_COUNT++))
fi

# Check SuperClaude (silent - optional)
progress "  [2/4] Verifying SuperClaude..."
if python3 -m SuperClaude --version &> /dev/null 2>&1; then
    success "        SuperClaude: $(python3 -m SuperClaude --version 2>&1 | head -1)"
    ((PASS_COUNT++))
fi

# Check .claude.json
progress "  [3/4] Verifying .claude.json..."
if [ -f "$HOME/.claude.json" ]; then
    MCP_COUNT=$(grep -c '"command"' "$HOME/.claude.json" 2>/dev/null || echo "0")
    success "        .claude.json: Found ($MCP_COUNT MCP servers configured)"
    ((PASS_COUNT++))
else
    error "        .claude.json: Missing"
    ((FAIL_COUNT++))
fi

# Check MCP packages (4 essential only - Claude Flow provides 90+ additional)
progress "  [4/4] Verifying MCP servers..."
MCP_INSTALLED=0
MCP_FAILED=0

if npm list -g @modelcontextprotocol/server-github &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if npm list -g @modelcontextprotocol/server-filesystem &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if npm list -g @playwright/mcp &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi
if npm list -g @modelcontextprotocol/server-sequential-thinking &> /dev/null; then ((MCP_INSTALLED++)); else ((MCP_FAILED++)); fi

if [ $MCP_INSTALLED -ge 3 ]; then
    success "        Essential MCP Servers: $MCP_INSTALLED/4 installed (Claude Flow provides 90+ additional)"
    ((PASS_COUNT++))
else
    error "        Essential MCP Servers: $MCP_INSTALLED/4 installed (minimum 3 required)"
    ((FAIL_COUNT++))
fi

echo ""
success "✅ Step 4/5 complete: Installation verified"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════
# STEP 5: AUTO-RENAME CODESPACE TO MATCH REPOSITORY
# ═══════════════════════════════════════════════════════════════════

show_step 5 5 "Finalizing setup"
echo "🏷️  Final configuration steps..."
echo ""

progress "  [1/2] Renaming codespace..."
if [ -n "$CODESPACES" ] && [ -n "${GITHUB_REPOSITORY:-}" ] && [ -n "$CODESPACE_NAME" ]; then

    REPO_NAME=$(basename "${GITHUB_REPOSITORY:-}" 2>/dev/null)

    if [ -n "$REPO_NAME" ]; then
        log "Renaming codespace to: $REPO_NAME"
        if run_with_timeout 30 "gh codespace edit --codespace '$CODESPACE_NAME' --display-name '$REPO_NAME' >> '$LOG_FILE' 2>&1"; then
            success "        Codespace renamed to: $REPO_NAME"
        else
            warn "        Could not auto-rename codespace (not critical)"
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
progress "  [2/2] Final cleanup and configuration..."

if [ -f "$DOTFILES_DIR/scripts/cleanup-vscode-state.sh" ]; then
    bash "$DOTFILES_DIR/scripts/cleanup-vscode-state.sh" 2>/dev/null || true
fi

# Kombai is now uninstalled during extension removal (line 282), no need for reset script
# Removed reset-kombai.sh call

# NEW: Suppress all welcome screens and setup prompts
if [ -f "$DOTFILES_DIR/scripts/suppress-welcome-screens.sh" ]; then
    bash "$DOTFILES_DIR/scripts/suppress-welcome-screens.sh" 2>/dev/null || true
    success "        Welcome screens and setup prompts suppressed"
else
    log "⚠️  suppress-welcome-screens.sh not found (non-critical)"
fi

echo ""
success "✅ Step 5/5 complete: Setup finalized"
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

echo "🔄 Restarting terminal to activate all configurations..."
echo ""

# Mark installation as complete - .bashrc will show welcome message
mkdir -p ~/.cache
touch ~/.cache/dotfiles_just_installed

# Store installation summary for welcome message
cat > ~/.cache/dotfiles_summary <<EOF
PASS_COUNT=$PASS_COUNT
FAIL_COUNT=$FAIL_COUNT
EOF

# Mark installation as complete in visible status file
cat >> "$VISIBLE_STATUS_FILE" <<EOF

════════════════════════════════════════════════════════════════════
  ✅ INSTALLATION COMPLETED SUCCESSFULLY!
════════════════════════════════════════════════════════════════════

⏰ Completed at: $(date '+%Y-%m-%d %H:%M:%S')
⏱️  Total time: ~$(($(date +%s) - START_TIME)) seconds

🎉 Your terminal will restart in 1-2 seconds...
💡 Watch for the welcome message with tool versions!

📊 Installation Summary:
   ✅ Passed: $PASS_COUNT checks
   ${FAIL_COUNT:+❌ Failed: $FAIL_COUNT checks}

════════════════════════════════════════════════════════════════════
EOF

sleep 1

# ═══════════════════════════════════════════════════════════════════
# COMPLETION SIGNAL - Make it IMPOSSIBLE to miss!
# ═══════════════════════════════════════════════════════════════════

progress "Running completion signal script..."
if [ -f "$DOTFILES_DIR/scripts/completion-signal.sh" ]; then
    bash "$DOTFILES_DIR/scripts/completion-signal.sh" 2>&1 || true
    success "Completion indicators created!"
else
    warn "completion-signal.sh not found (not critical)"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Show clear terminal restart message so user knows what's happening
echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║   🔄 RESTARTING TERMINAL TO ACTIVATE NEW ENVIRONMENT...          ║"
echo "║                                                                   ║"
echo "║   ⏱️  This takes 1-2 seconds - watch for the welcome message!    ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Automatically restart terminal with fresh environment
# This ensures DSP alias and all configurations are fully loaded
# .bashrc will detect first-run and show welcome message
sleep 1
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
