#!/bin/bash
# Completion Signal Script - Makes installation completion IMPOSSIBLE to miss

set -euo pipefail

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Completion file path
COMPLETION_FILE="/workspaces/🎉-INSTALLATION-COMPLETE-🎉.txt"
WORKSPACE_ROOT="/workspaces/$(basename "$PWD")"

# Function to create the completion file
create_completion_file() {
    cat > "$COMPLETION_FILE" << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║           🎉 CODESPACE INSTALLATION COMPLETE! 🎉                  ║
║                                                                   ║
║                   YOUR ENVIRONMENT IS READY!                      ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

✅ What Was Installed:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Core Tools:
   • Claude Code (Desktop CLI)
   • SuperClaude Framework
   • Claude Flow Orchestration

🔌 MCP Servers (9 Total):
   • claude-flow - Multi-agent orchestration
   • ruv-swarm - Enhanced swarm coordination
   • flow-nexus - Cloud-based features
   • context7 - Documentation lookup
   • sequential - Complex reasoning
   • magic - UI component generation
   • playwright - Browser automation
   • serena - Session persistence
   • tavily - Web search

🎯 What To Do Now:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 📂 Close this file (or keep it open for reference)

2. 🖥️  Open a NEW terminal:
   • Click Terminal menu → New Terminal
   • Or press: Ctrl+` (backtick)

3. 🧪 Test your installation:

   dsp --version

   ✅ If you see a version number → YOU'RE READY!
   ❌ If command not found → Run: source ~/.bashrc

4. 🚀 Start using Claude Code:

   dsp "create a simple React component"

📋 Quick Reference Commands:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

dsp --version              Check Claude Code version
dsp --help                 View all available commands
dsp "your task here"       Run Claude Code with a task
claude mcp list            List all MCP servers

🔧 Troubleshooting:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issue: "dsp: command not found"
Fix:   source ~/.bashrc
       (This reloads your shell configuration)

Issue: MCP servers not working
Fix:   Check status with: claude mcp list
       Restart if needed: ./scripts/restart-mcp.sh

Issue: Need to reinstall
Fix:   Run: ./install.sh

📚 Documentation:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• README.md - Full documentation
• docs/QUICK-REFERENCE.md - Command reference
• docs/STATUS-VISIBILITY-ARCHITECTURE.md - Architecture details

🎉 Happy Coding! 🎉

Need help? Check the docs or open an issue on GitHub.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Installation completed at: $(date)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Function to display completion banner in terminal
show_terminal_banner() {
    echo -e "\n\n\n"
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║${YELLOW}           🎉 CODESPACE INSTALLATION COMPLETE! 🎉${GREEN}                  ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}║${BOLD}                   YOUR ENVIRONMENT IS READY!${NC}${GREEN}                      ║${NC}"
    echo -e "${GREEN}║                                                                   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n"
    echo -e "${BLUE}✅ Installation Summary:${NC}"
    echo -e "   • Claude Code installed"
    echo -e "   • SuperClaude framework configured"
    echo -e "   • Claude Flow orchestration ready"
    echo -e "   • 9 MCP servers configured"
    echo -e "\n"
    echo -e "${YELLOW}🎯 Next Steps:${NC}"
    echo -e "   1. Open a new terminal (Ctrl+\`)"
    echo -e "   2. Test with: ${BOLD}dsp --version${NC}"
    echo -e "   3. If needed, run: ${BOLD}source ~/.bashrc${NC}"
    echo -e "\n"
    echo -e "${GREEN}📂 A completion file has been created and opened in VS Code.${NC}"
    echo -e "${GREEN}   Location: /workspaces/🎉-INSTALLATION-COMPLETE-🎉.txt${NC}"
    echo -e "\n"
}

# Function to play completion sound (ASCII bell)
play_completion_sound() {
    # ASCII bell character - should trigger system notification sound
    echo -e "\a"
    sleep 0.2
    echo -e "\a"
    sleep 0.2
    echo -e "\a"
}

# Function to send desktop notification (if notify-send is available)
send_desktop_notification() {
    if command -v notify-send &> /dev/null; then
        notify-send "🎉 Codespace Ready!" "Installation complete. Your environment is ready to use." -u critical
    fi
}

# Function to open completion file in VS Code
open_completion_file() {
    # Try multiple methods to open the file
    if command -v code &> /dev/null; then
        code "$COMPLETION_FILE" 2>/dev/null || true
    fi

    # Also try the 'code-insiders' command (for Codespaces)
    if command -v code-insiders &> /dev/null; then
        code-insiders "$COMPLETION_FILE" 2>/dev/null || true
    fi
}

# Function to update the visible status file
update_status_file() {
    local status_file="$WORKSPACE_ROOT/scripts/status/INSTALLATION-STATUS.txt"
    if [ -f "$status_file" ]; then
        echo "" >> "$status_file"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$status_file"
        echo "🎉 INSTALLATION COMPLETE! 🎉" >> "$status_file"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$status_file"
        echo "" >> "$status_file"
        echo "✅ All components installed successfully" >> "$status_file"
        echo "✅ Environment is ready to use" >> "$status_file"
        echo "" >> "$status_file"
        echo "📋 Next step: Open a new terminal and test with: dsp --version" >> "$status_file"
        echo "" >> "$status_file"
        echo "Completed at: $(date)" >> "$status_file"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$status_file"
    fi
}

# Main execution
main() {
    echo "Creating completion indicators..."

    # Create the completion file
    create_completion_file

    # Display terminal banner
    show_terminal_banner

    # Play completion sound
    play_completion_sound

    # Send desktop notification (if available)
    send_desktop_notification

    # Update status file
    update_status_file

    # Open completion file in VS Code
    open_completion_file

    # Final message
    echo -e "${GREEN}${BOLD}Installation complete! Check the opened file for next steps.${NC}\n"
}

# Run main function
main
