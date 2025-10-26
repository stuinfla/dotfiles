#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# SUPPRESS ALL VS CODE AND EXTENSION WELCOME SCREENS
# Runs at codespace creation to ensure clean, distraction-free startup
# ═══════════════════════════════════════════════════════════════════

echo "🔧 Suppressing all welcome screens and setup prompts..."

# VS Code global state directory
VSCODE_STATE_DIR="$HOME/.vscode-remote/data/User"
GLOBAL_STATE="$VSCODE_STATE_DIR/globalState.json"

# Create directory if it doesn't exist
mkdir -p "$VSCODE_STATE_DIR"

# Create or update global state to mark all walkthroughs as completed
# This prevents VS Code from showing "Getting Started" screens
cat > "$GLOBAL_STATE" <<'EOF'
{
  "walkthroughs.walkthroughsCompleted": true,
  "workbench.welcomePage.walkthroughsCompleted": true,
  "gettingStarted.stepCompleted": true,
  "kombai.welcomeShown": true,
  "kombai.gettingStartedCompleted": true,
  "python.showStartPageShown": true,
  "jupyter.startPageShown": true,
  "gitlens.welcomeShown": true,
  "gitlens.whatsNewShown": true,
  "workbench.activity.pinnedViewlets2": "workbench.view.explorer",
  "workbench.welcomePage.shown": true,
  "workbench.startupEditor": "none"
}
EOF

echo "✅ Global state configured to suppress welcome screens"

# Suppress Kombai-specific welcome screens
KOMBAI_STATE="$VSCODE_STATE_DIR/kombai-state.json"
cat > "$KOMBAI_STATE" <<'EOF'
{
  "welcomeShown": true,
  "gettingStartedCompleted": true,
  "skipGettingStarted": true
}
EOF

echo "✅ Kombai welcome screens suppressed"

# Create a marker file to prevent repeated welcome screens
touch "$VSCODE_STATE_DIR/.welcome-screens-suppressed"

echo "✅ All welcome screens and setup prompts have been suppressed"
echo "   VS Code will start with file explorer view and no interruptions"
