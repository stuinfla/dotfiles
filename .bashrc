# ═══════════════════════════════════════════════════════════════════
# GITHUB CODESPACES - DOTFILES CONFIGURATION
# Updated: 2025-10-16 - Added session resume, optimizations, security fixes
# ═══════════════════════════════════════════════════════════════════

# Ensure PATH includes npm global packages
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ═══════════════════════════════════════════════════════════════════
# CLAUDE CODE CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

# SESSION DIRECTORY - Not used with current Claude Code version
# Claude Code 2.0.27+ does not support --session-dir option
# Keeping directory for potential future use or manual session management
export CLAUDE_SESSION_DIR="$HOME/.claude-sessions"
mkdir -p "$CLAUDE_SESSION_DIR"

# Remove any existing claude alias to ensure our function takes precedence
unalias claude 2>/dev/null || true
unalias dsp 2>/dev/null || true
unalias DSP 2>/dev/null || true
unalias dsb 2>/dev/null || true
unalias DSB 2>/dev/null || true

# Claude Code function - runs with --dangerously-skip-permissions
# Using a function instead of alias for better reliability
# Note: --session-dir removed as it's not supported in Claude Code 2.0.27+
claude() {
    command claude --dangerously-skip-permissions "$@"
}
export -f claude

# Convenience aliases for dangerously-skip-permissions mode
# All aliases work the same way: dsp, DSP, dsb, DSB
alias dsp='claude'
alias DSP='claude'
alias dsb='claude'
alias DSB='claude'

# ═══════════════════════════════════════════════════════════════════
# ENVIRONMENT VARIABLES & API KEYS
# ═══════════════════════════════════════════════════════════════════

# 🚨 CRITICAL AUTHENTICATION SEPARATION:
#
# Claude Code CLI Authentication:
#   - Uses Claude Code Max subscription (via 'claude setup-token')
#   - DOES NOT use ANTHROPIC_API_KEY (to avoid pay-per-token charges)
#   - First-time setup: run 'dsp setup-token' and login with Claude.ai account
#
# Application API Access:
#   - ANTHROPIC_API_KEY is available from GitHub Codespaces secrets
#   - Applications can access it when needed for runtime operations
#   - NOT exported to prevent Claude Code CLI from using it
#
# To access API key in your applications:
#   - Use: $ANTHROPIC_API_KEY directly in your app code
#   - GitHub Codespaces injects it as an environment variable
#   - Configure at: https://github.com/settings/codespaces

# Helper function to show API key for apps (debugging only)
show_api_key() {
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "✅ ANTHROPIC_API_KEY is set (available for applications)"
        echo "   First 10 chars: ${ANTHROPIC_API_KEY:0:10}..."
    else
        echo "❌ ANTHROPIC_API_KEY not set"
        echo "   Configure at: https://github.com/settings/codespaces"
    fi
}

# Note: We do NOT export ANTHROPIC_API_KEY here to prevent Claude Code CLI
# from using it. Applications can still access it from the environment.

# ═══════════════════════════════════════════════════════════════════
# AUTO-UPDATE MECHANISM (WITH TIMEOUT PROTECTION - NEW!)
# ═══════════════════════════════════════════════════════════════════

# Auto-update function (runs once per day max, non-blocking)
# NEW: Added timeout protection to prevent hangs
auto_update_tools() {
    local update_marker="$HOME/.cache/claude_tools_updated"
    local update_log="$HOME/.cache/claude_update.log"
    local current_date=$(date +%Y-%m-%d)
    local timeout_seconds=300  # 5 minutes max for updates

    # Create cache directory if it doesn't exist
    mkdir -p "$HOME/.cache"

    # Check if we've already updated today
    if [ -f "$update_marker" ]; then
        local last_update=$(cat "$update_marker" 2>/dev/null || echo "never")
        if [ "$last_update" = "$current_date" ]; then
            return 0
        fi
    fi

    # Run updates in background silently (no user notification)
    # Run updates in background to not block shell startup
    {
        echo "=== Update started at $(date) ===" > "$update_log"

        # Update Claude Code (with timeout)
        echo "Updating Claude Code..." >> "$update_log"
        timeout $timeout_seconds npm update -g @anthropic-ai/claude-code@latest --force >> "$update_log" 2>&1 || echo "Claude Code update timed out or failed" >> "$update_log"

        # Update SuperClaude (with timeout)
        echo "Updating SuperClaude..." >> "$update_log"
        if command -v pipx &> /dev/null; then
            timeout $timeout_seconds pipx upgrade SuperClaude >> "$update_log" 2>&1 || echo "SuperClaude update timed out or failed" >> "$update_log"
        else
            timeout $timeout_seconds pip install --break-system-packages --user --upgrade --force-reinstall SuperClaude >> "$update_log" 2>&1 || echo "SuperClaude update timed out or failed" >> "$update_log"
        fi

        # Update Claude Flow @alpha (with timeout)
        echo "Updating Claude Flow @alpha..." >> "$update_log"
        timeout $timeout_seconds npx claude-flow@alpha init --force >> "$update_log" 2>&1 || echo "Claude Flow update timed out or failed" >> "$update_log"

        # Update MCP servers (with timeout for each)
        echo "Updating MCP servers..." >> "$update_log"
        timeout $timeout_seconds npm update -g mcp-installer@latest --force >> "$update_log" 2>&1
        timeout $timeout_seconds npm update -g @modelcontextprotocol/server-brave-search@latest --force >> "$update_log" 2>&1
        timeout $timeout_seconds npm update -g @modelcontextprotocol/server-github@latest --force >> "$update_log" 2>&1
        timeout $timeout_seconds npm update -g @modelcontextprotocol/server-filesystem@latest --force >> "$update_log" 2>&1
        timeout $timeout_seconds npm update -g @playwright/mcp@latest --force >> "$update_log" 2>&1
        timeout $timeout_seconds npm update -g @modelcontextprotocol/server-sequential-thinking@latest --force >> "$update_log" 2>&1
        timeout $timeout_seconds npm update -g @modelcontextprotocol/server-gdrive@latest --force >> "$update_log" 2>&1
        timeout $timeout_seconds npm update -g @huggingface/mcp-server-huggingface@latest --force >> "$update_log" 2>&1
        timeout $timeout_seconds pip install --break-system-packages --user --upgrade --force-reinstall mcp-server-fetch >> "$update_log" 2>&1

        echo "=== Update completed at $(date) ===" >> "$update_log"

        # Mark as updated today
        echo "$current_date" > "$update_marker"

        # Silent completion (no user notification)
    } &

    # Don't wait for background process
    disown
}

# Run auto-update only in Codespaces (not on local machine)
if [ -n "$CODESPACES" ]; then
    auto_update_tools
fi

# ═══════════════════════════════════════════════════════════════════
# HELPFUL ALIASES & FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

# Quick command to check if secrets are loaded
check_secrets() {
    echo "Checking GitHub Codespaces Secrets..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    declare -a SECRETS=(
        "ANTHROPIC_API_KEY"
        "CLAUDE_API_KEY"
        "BRAVE_API_KEY"
        "OPENAI_API_KEY"
        "GITHUB_ACCESS_TOKEN"
        "GITHUB_TOKEN"
        "GOOGLE_GEMINI_API_KEY"
        "GROQ_API_KEY"
        "GROK_AI_KEY"
        "APIFY_KEY"
        "GOOGLE_MAPS_API_KEY"
        "IMGBB_API_KEY"
        "NETLIFY_AUTH_TOKEN"
        "HUGGINGFACE_API_KEY"
    )

    for secret in "${SECRETS[@]}"; do
        if [ -n "${!secret}" ]; then
            echo "✅ $secret is set"
        else
            echo "❌ $secret is NOT set"
        fi
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "To add secrets: https://github.com/settings/codespaces"
}

# Quick command to check installed versions
check_versions() {
    echo "Installed Tool Versions:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Claude Code: $(claude --version 2>/dev/null || echo 'Not installed')"
    echo "SuperClaude: $(python3 -m SuperClaude --version 2>/dev/null || echo 'Not installed')"
    echo "Claude Flow: $(npx --yes claude-flow@alpha --version 2>/dev/null || echo 'Not installed')"
    echo "Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
    echo "Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# NEW: Check Claude session directory
check_sessions() {
    echo "Claude Sessions:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ -d "$CLAUDE_SESSION_DIR" ]; then
        echo "Session directory: $CLAUDE_SESSION_DIR"
        echo "Sessions found: $(ls -1 "$CLAUDE_SESSION_DIR" 2>/dev/null | wc -l)"
        echo ""
        echo "Recent sessions:"
        ls -lt "$CLAUDE_SESSION_DIR" 2>/dev/null | head -6
    else
        echo "No session directory found"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# System status monitoring with resource usage
check_status() {
    echo "System Status Monitor:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Repository information
    if [ -n "$GITHUB_REPOSITORY" ]; then
        local repo_name=$(basename "$GITHUB_REPOSITORY" 2>/dev/null)
        echo "📁 Repository: $repo_name"
    elif [ -d ".git" ]; then
        local repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
        echo "📁 Repository: $repo_name"
    else
        echo "📁 Repository: Not in a git repository"
    fi

    # CPU information
    local cpu_cores=$(nproc 2>/dev/null || echo "N/A")
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "N/A")
    echo "💻 CPU Cores: $cpu_cores"
    echo "⚡ CPU Usage: ${cpu_usage}%"

    # Memory information
    if command -v free >/dev/null 2>&1; then
        local mem_total=$(free -h | awk '/^Mem:/ {print $2}')
        local mem_used=$(free -h | awk '/^Mem:/ {print $3}')
        local mem_percent=$(free | awk '/^Mem:/ {printf "%.1f", ($3/$2) * 100}')
        echo "🧠 Memory: ${mem_used} / ${mem_total} (${mem_percent}%)"
    else
        echo "🧠 Memory: N/A"
    fi

    # Disk information
    if [ -n "$CODESPACES" ]; then
        local disk_usage=$(df -h /workspaces 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
        echo "💾 Disk: ${disk_usage}"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Note about Claude Code context
    echo ""
    echo "💡 For Claude Code context window info:"
    echo "   Use 'npx ccstatusline@latest' within Claude Code session"
    echo "   Or check Claude Code's status bar in VS Code"
}

# Rename Codespace to match repository name
rename-codespace() {
    if [ -z "$CODESPACES" ]; then
        echo "❌ Not running in a Codespace"
        return 1
    fi

    local repo_name=$(basename "$GITHUB_REPOSITORY" 2>/dev/null)

    if [ -z "$repo_name" ]; then
        echo "❌ Could not detect repository name"
        return 1
    fi

    if [ -z "$CODESPACE_NAME" ]; then
        echo "❌ Could not detect Codespace name"
        return 1
    fi

    echo "🏷️  Renaming Codespace..."
    echo "   From: $CODESPACE_NAME"
    echo "   To: $repo_name"

    if gh codespace edit --codespace "$CODESPACE_NAME" --display-name "$repo_name" 2>/dev/null; then
        echo "   ✅ Successfully renamed to: $repo_name"
    else
        echo "   ❌ Rename failed. Make sure gh CLI is authenticated."
        return 1
    fi
}

# Welcome message (only in Codespaces)
if [ -n "$CODESPACES" ]; then
    echo ""
    echo "🚀 Codespace Ready!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Show repository and codespace info
    if [ -n "$GITHUB_REPOSITORY" ]; then
        REPO_NAME=$(basename "$GITHUB_REPOSITORY" 2>/dev/null)
        echo "📁 Repository: $REPO_NAME"
    fi

    echo "✅ Claude Code ready (type 'dsp' or 'claude' to start)"
    echo "✅ MCP servers configured (4 essential + 90+ via Claude Flow)"
    echo ""
    echo "💡 Helpful commands:"
    echo "   • dsp / claude      - Start Claude Code (skip permissions)"
    echo "   • check_status      - System monitor (repo, memory, CPU)"
    echo "   • check_secrets     - Verify API keys are loaded"
    echo "   • check_versions    - Show installed versions"
    echo "   • check_sessions    - View Claude sessions"
    echo "   • rename-codespace  - Rename to match repository"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi
