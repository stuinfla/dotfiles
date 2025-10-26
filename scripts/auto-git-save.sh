#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# AUTO-GIT-SAVE - Background auto-commit and push every 5 minutes
# ═══════════════════════════════════════════════════════════════════

LOG_FILE="$HOME/.cache/auto-git-save.log"
LOCK_FILE="$HOME/.cache/auto-git-save.lock"
INTERVAL=300  # 5 minutes in seconds

# Create cache directory if it doesn't exist
mkdir -p "$HOME/.cache"

# Check if already running
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Auto-git-save already running (PID: $PID)" >> "$LOG_FILE"
        exit 0
    else
        # Stale lock file, remove it
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Cleanup on exit
cleanup() {
    rm -f "$LOCK_FILE"
    exit 0
}
trap cleanup EXIT INT TERM

# Log startup
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto-git-save started (PID: $$)" >> "$LOG_FILE"

# Main loop
while true; do
    # Only run if we're in a git repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Check if there are changes
        if git status --porcelain | grep -q .; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Changes detected, committing..." >> "$LOG_FILE"

            # Add all changes
            git add -A >> "$LOG_FILE" 2>&1

            # Create commit with timestamp
            git commit -m "Auto-save: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE" 2>&1

            # Push to origin
            BRANCH=$(git branch --show-current)
            if git push origin "$BRANCH" >> "$LOG_FILE" 2>&1; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Successfully pushed to origin/$BRANCH" >> "$LOG_FILE"
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to push to origin/$BRANCH" >> "$LOG_FILE"
            fi
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] No changes to commit" >> "$LOG_FILE"
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Not in a git repository, skipping" >> "$LOG_FILE"
    fi

    # Wait for next interval
    sleep $INTERVAL
done
