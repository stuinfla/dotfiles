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
    
    echo "🔄 Checking for updates to Claude Code and SuperClaude..."
    
    # Update Claude Code
    npm update -g @anthropic-ai/claude-code &>/dev/null &
    
    # Update SuperClaude
    if command -v pipx &> /dev/null; then
        pipx upgrade SuperClaude &>/dev/null &
    else
        pip install --break-system-packages --user SuperClaude --upgrade &>/dev/null &
    fi
    
    # Mark as updated today
    echo "$current_date" > "$update_marker"
    echo "✅ Update check complete!"
}

# Run auto-update in background (once per day)
auto_update_tools
