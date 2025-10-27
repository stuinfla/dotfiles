#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# DOTFILES CONFIGURATION CHECKER
# Diagnose why dotfiles aren't loading in codespaces
# ═══════════════════════════════════════════════════════════════════

echo "🔍 Dotfiles Configuration Diagnostic"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check 1: Are we in a Codespace?
echo "1️⃣ Codespace Environment Check"
if [ -n "$CODESPACES" ]; then
    echo "   ✅ Running in GitHub Codespace"
    echo "   📋 Codespace Name: $CODESPACE_NAME"
    echo "   📋 Repository: $GITHUB_REPOSITORY"
else
    echo "   ❌ NOT running in a Codespace"
    echo "   ⚠️  This script is designed for GitHub Codespaces"
fi
echo ""

# Check 2: Dotfiles directory exists?
echo "2️⃣ Dotfiles Directory Check"
if [ -d "$HOME/.dotfiles" ]; then
    echo "   ✅ Dotfiles directory exists: $HOME/.dotfiles"
    echo "   📋 Contents:"
    ls -la "$HOME/.dotfiles" | head -10
else
    echo "   ❌ Dotfiles directory NOT found"
    echo "   💡 This means dotfiles were never auto-installed"
    echo "   🔧 Fix: Run ./manual-install.sh"
fi
echo ""

# Check 3: .bashrc exists and has our configuration?
echo "3️⃣ .bashrc Check"
if [ -f "$HOME/.bashrc" ]; then
    echo "   ✅ .bashrc exists"

    if grep -q "alias dsp" "$HOME/.bashrc" 2>/dev/null; then
        echo "   ✅ DSP alias configured in .bashrc"
    else
        echo "   ❌ DSP alias NOT found in .bashrc"
        echo "   💡 .bashrc exists but doesn't have our configuration"
    fi

    if grep -q "CLAUDE_SESSION_DIR" "$HOME/.bashrc" 2>/dev/null; then
        echo "   ✅ Claude session directory configured"
    else
        echo "   ❌ Claude session directory NOT configured"
    fi
else
    echo "   ❌ .bashrc NOT found"
fi
echo ""

# Check 4: Is DSP alias active in current shell?
echo "4️⃣ Current Shell Configuration Check"
if type dsp &>/dev/null; then
    echo "   ✅ 'dsp' command is available"
    echo "   📋 Type: $(type dsp)"
else
    echo "   ❌ 'dsp' command NOT available"
    echo "   💡 Run: source ~/.bashrc"
fi

if type claude &>/dev/null; then
    echo "   ✅ 'claude' command is available"
else
    echo "   ❌ 'claude' command NOT available"
    echo "   💡 Claude Code may not be installed"
fi
echo ""

# Check 5: Claude Code installed?
echo "5️⃣ Claude Code Installation Check"
if command -v claude &>/dev/null; then
    VERSION=$(claude --version 2>&1 | head -1 || echo "unknown")
    echo "   ✅ Claude Code installed: $VERSION"
else
    echo "   ❌ Claude Code NOT installed"
    echo "   💡 Run: npm install -g @anthropic-ai/claude-code@latest"
fi
echo ""

# Check 6: .claude.json exists?
echo "6️⃣ Claude Configuration Check"
if [ -f "$HOME/.claude.json" ]; then
    echo "   ✅ .claude.json exists"
    MCP_COUNT=$(grep -c '"command"' "$HOME/.claude.json" 2>/dev/null || echo "0")
    echo "   📋 MCP servers configured: $MCP_COUNT"
else
    echo "   ❌ .claude.json NOT found"
fi
echo ""

# Check 7: API Keys configured?
echo "7️⃣ API Keys Check"
if [ -n "$ANTHROPIC_API_KEY" ] || [ -n "$CLAUDE_API_KEY" ]; then
    echo "   ✅ Claude API key is set"
else
    echo "   ❌ No Claude API key found"
    echo "   💡 Configure at: https://github.com/settings/codespaces"
fi
echo ""

# Summary
echo "════════════════════════════════════════════════════════════════"
echo "📊 DIAGNOSTIC SUMMARY"
echo "════════════════════════════════════════════════════════════════"

if [ ! -d "$HOME/.dotfiles" ]; then
    echo ""
    echo "🚨 ROOT CAUSE: Dotfiles were NEVER installed"
    echo ""
    echo "This happens when:"
    echo "  • Codespace was created BEFORE enabling dotfiles in GitHub"
    echo "  • Dotfiles setting was not configured correctly"
    echo ""
    echo "🔧 SOLUTION OPTIONS:"
    echo ""
    echo "  Option A (Recommended):"
    echo "    1. Delete this codespace"
    echo "    2. Enable dotfiles at: https://github.com/settings/codespaces"
    echo "    3. Set repository to: stuinfla/dotfiles"
    echo "    4. Create NEW codespace"
    echo ""
    echo "  Option B (Fix Current Codespace):"
    echo "    1. Run: bash manual-install.sh"
    echo "    2. Run: source ~/.bashrc"
    echo "    3. Test: dsp --version"
    echo ""
elif ! type dsp &>/dev/null; then
    echo ""
    echo "⚠️  ISSUE: Dotfiles exist but shell not configured"
    echo ""
    echo "🔧 QUICK FIX:"
    echo "    source ~/.bashrc"
    echo ""
else
    echo ""
    echo "✅ Everything looks good!"
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
