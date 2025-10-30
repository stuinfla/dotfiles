#!/bin/bash
# Quick push script for dotfiles updates

set -e

echo "════════════════════════════════════════════════════════════"
echo "  PUSHING DOTFILES TO GITHUB"
echo "════════════════════════════════════════════════════════════"
echo ""

cd /Users/stuartkerr/Code/dotfiles

echo "📦 Staging all changes..."
git add .

echo ""
echo "📝 Files to be committed:"
git status --short | head -30

echo ""
echo "💬 Committing with message..."
git commit -F COMMIT-MESSAGE.txt || git commit -m "MASSIVE UPDATE: Complete dotfiles overhaul with Claude Flow"

echo ""
echo "🚀 Pushing to GitHub..."
git push origin main

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ SUCCESSFULLY PUSHED TO GITHUB!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🎯 Next Steps:"
echo "   1. Go to https://github.com/stuinfla/dotfiles"
echo "   2. Verify the files are there"
echo "   3. Create a new codespace to test"
echo ""
echo "Test codespace creation:"
echo "   • Watch for: Step 1/5... Step 2/5..."
echo "   • Wait for: 🎉 INSTALLATION COMPLETE! 🎉"
echo "   • Test command: dsp --version"
echo ""
