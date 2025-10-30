#!/bin/bash
# Status Update Helper Functions
# Source this file in install.sh: source "$(dirname "$0")/scripts/status-update.sh"

set -euo pipefail

# Configuration
STATUS_FILE="${STATUS_FILE:-$HOME/DOTFILES_STATUS.txt}"
STATUS_LOG="${STATUS_LOG:-$HOME/DOTFILES_STATUS.log}"

# Initialize status system
init_status() {
    # Create empty log
    : > "$STATUS_LOG"

    # Layer 1: Terminal output
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  🚀 DOTFILES INSTALLATION STARTING                        ║"
    echo "║  📋 Status file: $STATUS_FILE                            ║"
    echo "║  ⏱️  Watch for real-time updates                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Layer 2: Create initial status file
    update_status "0/5" "⚙️  Initializing installation..."
}

# Update status file with current progress
update_status() {
    local step=$1
    local message=$2
    local timestamp=$(date '+%H:%M:%S')

    cat > "$STATUS_FILE" << EOF
╔════════════════════════════════════════════════════════════╗
║           DOTFILES INSTALLATION PROGRESS                   ║
╚════════════════════════════════════════════════════════════╝

🕐 Last Updated: $timestamp
📊 Current Step: $step

$message

════════════════════════════════════════════════════════════

📋 Completed Steps:
EOF

    # Append completed steps from log
    if [ -f "$STATUS_LOG" ]; then
        cat "$STATUS_LOG" >> "$STATUS_FILE"
    else
        echo "No steps completed yet" >> "$STATUS_FILE"
    fi

    echo "" >> "$STATUS_FILE"
    echo "⏳ Installation in progress..." >> "$STATUS_FILE"
    echo "This file updates automatically every few seconds" >> "$STATUS_FILE"
}

# Log a completed step
log_step() {
    local description=$1
    local timestamp=$(date '+%H:%M:%S')
    echo "✅ $description ($timestamp)" >> "$STATUS_LOG"
}

# Mark installation as complete
complete_status() {
    local timestamp=$(date '+%H:%M:%S')

    cat > "$STATUS_FILE" << EOF
╔════════════════════════════════════════════════════════════╗
║           DOTFILES INSTALLATION COMPLETE! 🎉              ║
╚════════════════════════════════════════════════════════════╝

✅ Completed at: $timestamp

════════════════════════════════════════════════════════════

📋 All Steps Completed:
EOF

    cat "$STATUS_LOG" >> "$STATUS_FILE"

    cat >> "$STATUS_FILE" << EOF

════════════════════════════════════════════════════════════

🎊 SUCCESS! Your development environment is ready!

🔄 Next Steps:
   1. Close this file
   2. Open a new terminal (Ctrl+\`)
   3. Run: source ~/.zshrc

💡 Your terminal now has:
   • Zsh with Oh-My-Zsh
   • Syntax highlighting
   • Auto-suggestions
   • Custom theme and plugins

════════════════════════════════════════════════════════════

EOF

    # Terminal output
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  ✅ INSTALLATION COMPLETE!                                 ║"
    echo "║  🔄 Restart your terminal to apply changes                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Mark installation as failed
fail_status() {
    local error_message=$1
    local timestamp=$(date '+%H:%M:%S')

    cat > "$STATUS_FILE" << EOF
╔════════════════════════════════════════════════════════════╗
║           INSTALLATION FAILED ❌                           ║
╚════════════════════════════════════════════════════════════╝

⏰ Failed at: $timestamp

════════════════════════════════════════════════════════════

❌ ERROR: $error_message

════════════════════════════════════════════════════════════

📋 Steps Completed Before Failure:
EOF

    cat "$STATUS_LOG" >> "$STATUS_FILE"

    cat >> "$STATUS_FILE" << EOF

════════════════════════════════════════════════════════════

🔧 Troubleshooting:
   1. Check the error message above
   2. Review /tmp/dotfiles-install-output.log for details
   3. Try running install.sh manually: bash ~/dotfiles/install.sh
   4. Report issue: https://github.com/YOUR_USERNAME/dotfiles/issues

════════════════════════════════════════════════════════════

EOF

    # Terminal output
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  ❌ INSTALLATION FAILED                                    ║"
    echo "║  📋 Check $STATUS_FILE for details                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Export functions for use in install.sh
export -f init_status
export -f update_status
export -f log_step
export -f complete_status
export -f fail_status
