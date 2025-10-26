#!/bin/bash

# CONTINUOUS EXTENSION WATCHDOG
# Monitors and removes unwanted extensions every 10 seconds for 5 minutes
# Runs AFTER codespace opens, not during postCreateCommand

VSCODE_EXT_DIR="$HOME/.vscode-remote/extensions"
LOG_FILE="/tmp/extension-watchdog.log"
CHECK_INTERVAL=10
DURATION=300  # 5 minutes

echo "========================================" >> "$LOG_FILE"
echo "[$(date)] Watchdog started - will monitor for ${DURATION}s" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

START_TIME=$(date +%s)
REMOVAL_COUNT=0

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED -ge $DURATION ]; then
        echo "[$(date)] Watchdog completed after ${ELAPSED}s" >> "$LOG_FILE"
        echo "[$(date)] Total removals: $REMOVAL_COUNT" >> "$LOG_FILE"
        break
    fi

    echo "[$(date)] Check ${ELAPSED}s - Looking for extensions..." >> "$LOG_FILE"

    # Check if extensions directory exists
    if [ ! -d "$VSCODE_EXT_DIR" ]; then
        echo "[$(date)] Extensions directory not found yet" >> "$LOG_FILE"
        sleep $CHECK_INTERVAL
        continue
    fi

    # List all extensions
    EXTENSIONS=$(ls -1 "$VSCODE_EXT_DIR" 2>/dev/null)
    if [ -n "$EXTENSIONS" ]; then
        echo "[$(date)] Found extensions:" >> "$LOG_FILE"
        echo "$EXTENSIONS" >> "$LOG_FILE"
    fi

    # Remove Kombai
    KOMBAI_DIRS=$(find "$VSCODE_EXT_DIR" -maxdepth 1 -type d -name "kombai.kombai-*" 2>/dev/null)
    if [ -n "$KOMBAI_DIRS" ]; then
        echo "[$(date)] ⚠️  FOUND KOMBAI - REMOVING NOW!" >> "$LOG_FILE"
        for dir in $KOMBAI_DIRS; do
            rm -rf "$dir" && echo "[$(date)] ✅ Removed: $dir" >> "$LOG_FILE"
            REMOVAL_COUNT=$((REMOVAL_COUNT + 1))
        done
    fi

    # Remove Test Explorer
    TEST_DIRS=$(find "$VSCODE_EXT_DIR" -maxdepth 1 -type d -name "hbenl.vscode-test-explorer-*" 2>/dev/null)
    if [ -n "$TEST_DIRS" ]; then
        echo "[$(date)] ⚠️  FOUND TEST EXPLORER - REMOVING NOW!" >> "$LOG_FILE"
        for dir in $TEST_DIRS; do
            rm -rf "$dir" && echo "[$(date)] ✅ Removed: $dir" >> "$LOG_FILE"
            REMOVAL_COUNT=$((REMOVAL_COUNT + 1))
        done
    fi

    # Remove Cline/Claude Dev
    CLINE_DIRS=$(find "$VSCODE_EXT_DIR" -maxdepth 1 -type d -name "*claude-dev-*" 2>/dev/null)
    if [ -n "$CLINE_DIRS" ]; then
        echo "[$(date)] ⚠️  FOUND CLINE - REMOVING NOW!" >> "$LOG_FILE"
        for dir in $CLINE_DIRS; do
            rm -rf "$dir" && echo "[$(date)] ✅ Removed: $dir" >> "$LOG_FILE"
            REMOVAL_COUNT=$((REMOVAL_COUNT + 1))
        done
    fi

    if [ $REMOVAL_COUNT -eq 0 ]; then
        echo "[$(date)] No unwanted extensions found" >> "$LOG_FILE"
    fi

    sleep $CHECK_INTERVAL
done

echo "[$(date)] Watchdog finished - Final removal count: $REMOVAL_COUNT" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
