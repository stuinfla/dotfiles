#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# DAILY AUTO-UPDATE SCRIPT
# Updates: Claude Code, SuperClaude, Claude Flow, VS Code Extensions
# Runs: Daily on first shell start (if >24hrs since last update)
# Logging: ~/.cache/claude_update.log
# ═══════════════════════════════════════════════════════════════════

# Silent operation - all output goes to log
LOGFILE="$HOME/.cache/claude_update.log"
LOCKFILE="$HOME/.cache/claude_update.lock"
TIMESTAMP_FILE="$HOME/.cache/claude_update_last"

# Create log directory if needed
mkdir -p "$HOME/.cache"

# Redirect all output to log file
exec >> "$LOGFILE" 2>&1

# ═══════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Check if update is needed (once per day)
should_update() {
    # If timestamp file doesn't exist, update needed
    if [ ! -f "$TIMESTAMP_FILE" ]; then
        return 0
    fi

    # Get last update time
    LAST_UPDATE=$(cat "$TIMESTAMP_FILE" 2>/dev/null || echo "0")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))

    # Update if more than 24 hours (86400 seconds)
    if [ $TIME_DIFF -gt 86400 ]; then
        return 0
    else
        return 1
    fi
}

# Acquire lock to prevent multiple updates
acquire_lock() {
    if [ -f "$LOCKFILE" ]; then
        # Check if lock is stale (older than 30 minutes)
        LOCK_AGE=$(($(date +%s) - $(stat -f %m "$LOCKFILE" 2>/dev/null || echo "0")))
        if [ $LOCK_AGE -gt 1800 ]; then
            log "Removing stale lock file (age: ${LOCK_AGE}s)"
            rm -f "$LOCKFILE"
        else
            log "Update already in progress (lock file exists)"
            return 1
        fi
    fi

    # Create lock file
    touch "$LOCKFILE"
    return 0
}

# Release lock
release_lock() {
    rm -f "$LOCKFILE"
}

# Update timestamp
update_timestamp() {
    date +%s > "$TIMESTAMP_FILE"
}

# ═══════════════════════════════════════════════════════════════════
# UPDATE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

update_claude_code() {
    log "Updating Claude Code..."
    if npm update -g @anthropic-ai/claude-code 2>&1 | tail -2; then
        if command -v claude &> /dev/null; then
            NEW_VERSION=$(claude --version 2>&1 | head -1)
            log "✅ Claude Code updated: $NEW_VERSION"
            return 0
        fi
    fi
    log "⚠️  Claude Code update failed (non-critical)"
    return 1
}

update_superclaude() {
    log "Updating SuperClaude..."

    # Try pipx first (preferred)
    if command -v pipx &> /dev/null; then
        if pipx upgrade SuperClaude 2>&1 | tail -2; then
            if python3 -m SuperClaude --version &> /dev/null; then
                NEW_VERSION=$(python3 -m SuperClaude --version 2>&1 | head -1)
                log "✅ SuperClaude updated (pipx): $NEW_VERSION"
                return 0
            fi
        fi
    fi

    # Fall back to pip
    if pip install --break-system-packages --user --upgrade SuperClaude 2>&1 | tail -3; then
        if python3 -m SuperClaude --version &> /dev/null; then
            NEW_VERSION=$(python3 -m SuperClaude --version 2>&1 | head -1)
            log "✅ SuperClaude updated (pip): $NEW_VERSION"
            return 0
        fi
    fi

    log "⚠️  SuperClaude update failed (non-critical)"
    return 1
}

update_claude_flow() {
    log "Updating Claude Flow..."
    if npm update -g claude-flow@alpha 2>&1 | tail -2; then
        if command -v claude-flow &> /dev/null; then
            NEW_VERSION=$(claude-flow --version 2>&1 | head -1)
            log "✅ Claude Flow updated: $NEW_VERSION"

            # Re-initialize to ensure compatibility
            log "Re-initializing Claude Flow..."
            if claude-flow init --force 2>&1 | tail -2; then
                log "✅ Claude Flow re-initialized"
            fi
            return 0
        fi
    fi
    log "⚠️  Claude Flow update failed (non-critical)"
    return 1
}

update_vscode_extensions() {
    log "Updating VS Code extensions..."

    if ! command -v code &> /dev/null; then
        log "⚠️  VS Code CLI not available - skipping extension updates"
        return 1
    fi

    # Get list of installed extensions
    EXTENSIONS=$(code --list-extensions 2>/dev/null)

    if [ -z "$EXTENSIONS" ]; then
        log "ℹ️  No VS Code extensions to update"
        return 0
    fi

    UPDATED=0
    FAILED=0

    # Update each extension
    while IFS= read -r ext; do
        if code --install-extension "$ext" --force 2>&1 | grep -q "successfully"; then
            ((UPDATED++))
        else
            ((FAILED++))
        fi
    done <<< "$EXTENSIONS"

    if [ $UPDATED -gt 0 ]; then
        log "✅ Updated $UPDATED VS Code extensions"
    fi
    if [ $FAILED -gt 0 ]; then
        log "⚠️  Failed to update $FAILED VS Code extensions"
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════
# MAIN UPDATE PROCESS
# ═══════════════════════════════════════════════════════════════════

main() {
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Starting daily update check..."

    # Check if update is needed
    if ! should_update; then
        log "✅ Updates already run today - skipping"
        return 0
    fi

    # Acquire lock
    if ! acquire_lock; then
        log "⚠️  Could not acquire lock - another update in progress"
        return 1
    fi

    # Ensure lock is released on exit
    trap release_lock EXIT

    log "Running background updates..."

    # Update all tools (in background, non-blocking)
    SUCCESS=0
    TOTAL=4

    # Claude Code
    if update_claude_code; then
        ((SUCCESS++))
    fi

    # SuperClaude
    if update_superclaude; then
        ((SUCCESS++))
    fi

    # Claude Flow
    if update_claude_flow; then
        ((SUCCESS++))
    fi

    # VS Code Extensions
    if update_vscode_extensions; then
        ((SUCCESS++))
    fi

    # Update timestamp
    update_timestamp

    # Final summary
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Update complete: $SUCCESS/$TOTAL successful"
    log "Next update: $(date -v+1d +'%Y-%m-%d')"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return 0
}

# Run main function
main

# Exit successfully (don't block shell startup on errors)
exit 0
