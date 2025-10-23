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

# SESSION RESUME SUPPORT - NEW!
# This allows Claude to remember context between sessions
export CLAUDE_SESSION_DIR="$HOME/.claude-sessions"
mkdir -p "$CLAUDE_SESSION_DIR"

# Remove any existing claude alias to ensure our function takes precedence
unalias claude 2>/dev/null || true
unalias dsp 2>/dev/null || true
unalias DSP 2>/dev/null || true

# Claude Code function - runs with --dangerously-skip-permissions AND session support
# Using a function instead of alias for better reliability
claude() {
    command claude --dangerously-skip-permissions --session-dir "$CLAUDE_SESSION_DIR" "$@"
}
export -f claude

# Convenience aliases for dangerously-skip-permissions mode
# Both 'dsp' and 'DSP' work the same way
alias dsp='claude'
alias DSP='claude'

# ═══════════════════════════════════════════════════════════════════
# ENVIRONMENT VARIABLES & API KEYS
# ═══════════════════════════════════════════════════════════════════

# GitHub Codespaces automatically injects secrets as environment variables
# These are set via: https://github.com/settings/codespaces
# No need to explicitly export them - they're already available!

# Verify key environment variables are set (for debugging)
if [ -n "$CODESPACES" ]; then
    # We're in a Codespace - secrets should be available

    # CLAUDE_API_KEY and ANTHROPIC_API_KEY are the same thing
    # If one is set, use it for both names for compatibility
    if [ -n "$CLAUDE_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
        export ANTHROPIC_API_KEY="$CLAUDE_API_KEY"
    elif [ -n "$ANTHROPIC_API_KEY" ] && [ -z "$CLAUDE_API_KEY" ]; then
        export CLAUDE_API_KEY="$ANTHROPIC_API_KEY"
    fi

    # Warn only if neither is set
    if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$CLAUDE_API_KEY" ]; then
        echo "⚠️  WARNING: ANTHROPIC_API_KEY/CLAUDE_API_KEY not set. Configure at https://github.com/settings/codespaces"
    fi
fi

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

    echo "🔄 Checking for updates (running in background with ${timeout_seconds}s timeout)..."

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

        echo "✅ Background updates completed! Check $update_log for details."
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

    echo "✅ Claude Code installed (type 'dsp' or 'claude' to start)"
    echo "✅ SuperClaude installed (use /sc: commands)"
    echo "✅ Claude Flow @alpha installed (npx claude-flow@alpha)"
    echo "✅ MCP servers configured (9 servers available)"
    echo "✅ Session resume enabled ($CLAUDE_SESSION_DIR)"
    echo ""
    echo "💡 Helpful commands:"
    echo "   • dsp / claude      - Start Claude Code (skip permissions)"
    echo "   • check_secrets     - Verify API keys are loaded"
    echo "   • check_versions    - Show installed versions"
    echo "   • check_sessions    - View Claude sessions"
    echo "   • rename-codespace  - Rename to match repository"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi
