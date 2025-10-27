#!/usr/bin/env bash

# ════════════════════════════════════════════════════════════════════
# Kombai Extension Reset Script
#
# Purpose: Reset Kombai to show workspace files (not previous documents)
# Clears cached state so Kombai opens in a clean state showing file explorer
# ════════════════════════════════════════════════════════════════════

set -e

# Only run in codespaces
if [ -z "$CODESPACES" ]; then
    exit 0
fi

# VS Code directories
VSCODE_SERVER_DIR="$HOME/.vscode-server"
USER_DATA="$VSCODE_SERVER_DIR/data/User"

# Kombai-specific paths
KOMBAI_GLOBAL="$USER_DATA/globalStorage/kombai.kombai"
KOMBAI_STATE="$USER_DATA/workspaceStorage"

# Clear Kombai global storage
if [ -d "$KOMBAI_GLOBAL" ]; then
    rm -rf "$KOMBAI_GLOBAL"/* 2>/dev/null || true
fi

# Clear Kombai workspace-specific state
if [ -d "$KOMBAI_STATE" ]; then
    find "$KOMBAI_STATE" -type d -name "*kombai*" -exec rm -rf {} + 2>/dev/null || true
fi

# Clear any cached Kombai preferences that would restore previous state
KOMBAI_PREFS="$USER_DATA/settings.json"
if [ -f "$KOMBAI_PREFS" ]; then
    # Remove Kombai-specific settings (if any)
    # This is a placeholder - actual Kombai settings may vary
    true
fi

# Exit silently
exit 0
