# Claude Code alias - runs with dangerously-skip-permissions
alias claude='claude --dangerously-skip-permissions'

# Keep npm global packages updated
export PATH="$HOME/.npm-global/bin:$PATH"

# Auto-update function (runs once per day max)
auto_update_tools() {
    local update_marker="/tmp/claude_tools_updated"
    local current_date=$(date +%Y-%m-%d)
    
    # Check if we've already updated today
    if [ -f "$update_marker" ]; then
        local last_update=$(cat "$update_marker")
        if [ "$last_update" = "$current_date" ]; then
            return 0
        fi
    fi
    
    echo "🔄 Checking for updates (forcing latest versions)..."
    
    # Update Claude Code (FORCE LATEST)
    npm update -g @anthropic-ai/claude-code@latest --force &>/dev/null &
    
    # Update SuperClaude (FORCE LATEST)
    if command -v pipx &> /dev/null; then
        pipx upgrade SuperClaude &>/dev/null &
    else
        pip install --break-system-packages --user --upgrade --force-reinstall SuperClaude &>/dev/null &
    fi
    
    # Update MCP servers (FORCE LATEST)
    npm update -g mcp-installer@latest --force &>/dev/null &
    npm update -g @modelcontextprotocol/server-brave-search@latest --force &>/dev/null &
    npm update -g @modelcontextprotocol/server-github@latest --force &>/dev/null &
    npm update -g @modelcontextprotocol/server-filesystem@latest --force &>/dev/null &
    npm update -g @playwright/mcp@latest --force &>/dev/null &
    npm update -g @modelcontextprotocol/server-sequential-thinking@latest --force &>/dev/null &
    pip install --break-system-packages --user --upgrade --force-reinstall mcp-server-fetch &>/dev/null &
    
    # Mark as updated today
    echo "$current_date" > "$update_marker"
    echo "✅ Update check complete (all packages set to latest)!"
}

# Run auto-update in background (once per day)
auto_update_tools
