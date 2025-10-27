#!/usr/bin/env bash

# ════════════════════════════════════════════════════════════════════
# VS Code State Cleanup Script
#
# Purpose: Clear VS Code workspace state to ensure clean startup
# Ensures extensions like Kombai don't restore previous session state
# ════════════════════════════════════════════════════════════════════

set -e

# Only run in codespaces
if [ -z "$CODESPACES" ]; then
    exit 0
fi

# VS Code workspace state directories
VSCODE_SERVER_DIR="$HOME/.vscode-server"
VSCODE_REMOTE_DIR="$HOME/.vscode-remote"
WORKSPACE_STORAGE="$VSCODE_SERVER_DIR/data/Machine/workspaceStorage"

# Extension-specific state directories
KOMBAI_STATE="$VSCODE_SERVER_DIR/data/User/globalStorage/kombai.kombai"

# Clear workspace storage (forces clean state)
if [ -d "$WORKSPACE_STORAGE" ]; then
    rm -rf "$WORKSPACE_STORAGE"/* 2>/dev/null || true
fi

# Clear Kombai state if it exists
if [ -d "$KOMBAI_STATE" ]; then
    rm -rf "$KOMBAI_STATE" 2>/dev/null || true
fi

# Clear any cached session files
find "$VSCODE_SERVER_DIR" -name "*.session" -delete 2>/dev/null || true
find "$VSCODE_REMOTE_DIR" -name "*.session" -delete 2>/dev/null || true

# Exit silently (no output unless errors)
exit 0
