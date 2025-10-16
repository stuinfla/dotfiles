#!/bin/bash

# Install Claude Code globally (latest version)
echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

# Check if pipx is available
if command -v pipx &> /dev/null; then
    echo "📦 Installing SuperClaude 4.2 with pipx..."
    pipx install SuperClaude
    pipx upgrade SuperClaude
    SuperClaude install
else
    echo "📦 Installing SuperClaude 4.2 with pip..."
    pip install --break-system-packages --user SuperClaude
    SuperClaude install
fi

echo "✅ Setup complete!"
echo "💡 Type 'claude' to start (includes --dangerously-skip-permissions)"
