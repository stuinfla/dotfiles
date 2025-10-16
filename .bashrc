# ═══════════════════════════════════════════════════════════════════
# GITHUB CODESPACES - DOTFILES CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

# Ensure PATH includes npm global packages
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ═══════════════════════════════════════════════════════════════════
# CLAUDE CODE CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

# Claude Code function - runs with --dangerously-skip-permissions
# Using a function instead of alias for better reliability
claude() {
    command claude --dangerously-skip-permissions "$@"
}
export -f claude

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
# AUTO-UPDATE MECHANISM
# ═══════════════════════════════════════════════════════════════════

# Auto-update function (runs once per day max, non-blocking)
auto_update_tools() {
    local update_marker="$HOME/.cache/claude_tools_updated"
    local update_log="$HOME/.cache/claude_update.log"
    local current_date=$(date +%Y-%m-%d)

    # Create cache directory if it doesn't exist
    mkdir -p "$HOME/.cache"

    # Check if we've already updated today
    if [ -f "$update_marker" ]; then
        local last_update=$(cat "$update_marker" 2>/dev/null || echo "never")
        if [ "$last_update" = "$current_date" ]; then
            return 0
        fi
    fi

    echo "🔄 Checking for updates (running in background)..."

    # Run updates in background to not block shell startup
    {
        echo "=== Update started at $(date) ===" > "$update_log"

        # Update Claude Code
        echo "Updating Claude Code..." >> "$update_log"
        npm update -g @anthropic-ai/claude-code@latest --force >> "$update_log" 2>&1

        # Update SuperClaude
        echo "Updating SuperClaude..." >> "$update_log"
        if command -v pipx &> /dev/null; then
            pipx upgrade SuperClaude >> "$update_log" 2>&1
        else
            pip install --break-system-packages --user --upgrade --force-reinstall SuperClaude >> "$update_log" 2>&1
        fi

        # Update MCP servers
        echo "Updating MCP servers..." >> "$update_log"
        npm update -g mcp-installer@latest --force >> "$update_log" 2>&1
        npm update -g @modelcontextprotocol/server-brave-search@latest --force >> "$update_log" 2>&1
        npm update -g @modelcontextprotocol/server-github@latest --force >> "$update_log" 2>&1
        npm update -g @modelcontextprotocol/server-filesystem@latest --force >> "$update_log" 2>&1
        npm update -g @playwright/mcp@latest --force >> "$update_log" 2>&1
        npm update -g @modelcontextprotocol/server-sequential-thinking@latest --force >> "$update_log" 2>&1
        npm update -g @modelcontextprotocol/server-gdrive@latest --force >> "$update_log" 2>&1
        npm update -g @huggingface/mcp-server-huggingface@latest --force >> "$update_log" 2>&1
        pip install --break-system-packages --user --upgrade --force-reinstall mcp-server-fetch >> "$update_log" 2>&1

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
    echo "Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
    echo "Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Welcome message (only in Codespaces)
if [ -n "$CODESPACES" ]; then
    echo ""
    echo "🚀 Codespace Ready!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Claude Code installed (type 'claude' to start)"
    echo "✅ SuperClaude installed (use /sc: commands)"
    echo "✅ MCP servers configured"
    echo ""
    echo "💡 Helpful commands:"
    echo "   • check_secrets  - Verify API keys are loaded"
    echo "   • check_versions - Show installed versions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi
