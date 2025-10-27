#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# MANUAL DOTFILES INSTALLATION FOR EXISTING CODESPACE
# Use this if you created a codespace WITHOUT dotfiles enabled
# ═══════════════════════════════════════════════════════════════════

set -e

echo "🔧 Manual Dotfiles Installation"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Clone dotfiles if not present
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "📥 Cloning dotfiles repository..."
    git clone https://github.com/stuinfla/dotfiles.git "$HOME/.dotfiles"
    echo "✅ Dotfiles cloned"
else
    echo "✅ Dotfiles directory already exists"
fi

# Step 2: Copy .bashrc
echo "📋 Installing .bashrc..."
cp "$HOME/.dotfiles/.bashrc" "$HOME/.bashrc"
echo "✅ .bashrc installed"

# Step 3: Copy .claude.json
echo "📋 Installing .claude.json..."
cp "$HOME/.dotfiles/.claude.json" "$HOME/.claude.json"
chmod 600 "$HOME/.claude.json"
echo "✅ .claude.json installed"

# Step 4: Run main installation script
echo "🚀 Running full installation..."
cd "$HOME/.dotfiles"
bash install.sh

# Step 5: Reload shell configuration
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Installation complete!"
echo ""
echo "📌 IMPORTANT: Run this command to activate changes:"
echo "   source ~/.bashrc"
echo ""
echo "Then test with:"
echo "   dsp --version"
echo "   check_secrets"
echo "════════════════════════════════════════════════════════════════"
