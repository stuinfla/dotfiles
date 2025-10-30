#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# DSP Command Diagnostic Tool
# Verifies that dsp/DSP aliases work correctly
# ═══════════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════"
echo "🔍 DSP COMMAND DIAGNOSTICS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check 1: Is claude command available?
echo "1️⃣  Checking claude command..."
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -1)
    echo "   ✅ Claude found: $CLAUDE_VERSION"
    CLAUDE_PATH=$(which claude)
    echo "   📍 Location: $CLAUDE_PATH"
else
    echo "   ❌ Claude command not found in PATH"
    echo "   💡 Install with: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

echo ""

# Check 2: Is .bashrc being loaded?
echo "2️⃣  Checking .bashrc configuration..."
if [ -f ~/.bashrc ]; then
    echo "   ✅ .bashrc exists"

    # Check if dsp function is defined
    if grep -q "^dsp()" ~/.bashrc || grep -q "^dsp ()" ~/.bashrc; then
        echo "   ✅ dsp function defined in .bashrc"
    else
        echo "   ⚠️  dsp function NOT found in .bashrc"
    fi

    # Check if DSP function is defined
    if grep -q "^DSP()" ~/.bashrc || grep -q "^DSP ()" ~/.bashrc; then
        echo "   ✅ DSP function defined in .bashrc"
    else
        echo "   ⚠️  DSP function NOT found in .bashrc"
    fi
else
    echo "   ❌ .bashrc not found"
    exit 1
fi

echo ""

# Check 3: Is .bash_profile sourcing .bashrc?
echo "3️⃣  Checking .bash_profile..."
if [ -f ~/.bash_profile ]; then
    if grep -q "\.bashrc" ~/.bash_profile; then
        echo "   ✅ .bash_profile sources .bashrc"
    else
        echo "   ⚠️  .bash_profile exists but doesn't source .bashrc"
    fi
else
    echo "   ⚠️  .bash_profile not found (may be okay on some systems)"
fi

echo ""

# Check 4: Test if dsp function works in current shell
echo "4️⃣  Testing dsp function in current shell..."

# Source .bashrc to load the function
source ~/.bashrc 2>/dev/null

if type dsp &> /dev/null; then
    echo "   ✅ dsp function is available"

    # Test the function
    if dsp --version &> /dev/null; then
        echo "   ✅ dsp --version works correctly"
    else
        echo "   ⚠️  dsp function exists but may have issues"
    fi
else
    echo "   ❌ dsp function not available"
    echo "   💡 Run: source ~/.bashrc"
fi

echo ""

# Check 5: Test DSP (uppercase) function
echo "5️⃣  Testing DSP (uppercase) function..."
if type DSP &> /dev/null; then
    echo "   ✅ DSP function is available"
else
    echo "   ❌ DSP function not available"
fi

echo ""

# Check 6: Environment variables
echo "6️⃣  Checking environment configuration..."
if [ -n "$ANTHROPIC_CLAUDE_CODE_SKIP_PERMISSIONS" ]; then
    echo "   ✅ ANTHROPIC_CLAUDE_CODE_SKIP_PERMISSIONS is set"
else
    echo "   ℹ️  ANTHROPIC_CLAUDE_CODE_SKIP_PERMISSIONS not set (will be set by dsp function)"
fi

if [ -n "$CLAUDE_CODE_SESSION_DIR" ]; then
    echo "   ✅ CLAUDE_CODE_SESSION_DIR: $CLAUDE_CODE_SESSION_DIR"
    if [ -d "$CLAUDE_CODE_SESSION_DIR" ]; then
        echo "   ✅ Session directory exists"
    else
        echo "   ⚠️  Session directory doesn't exist yet"
    fi
else
    echo "   ⚠️  CLAUDE_CODE_SESSION_DIR not set"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📋 SUMMARY"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Final verdict
ALL_GOOD=true

if ! command -v claude &> /dev/null; then
    echo "❌ Claude command not installed"
    ALL_GOOD=false
fi

if ! type dsp &> /dev/null; then
    echo "❌ dsp function not available - run: source ~/.bashrc"
    ALL_GOOD=false
fi

if ! type DSP &> /dev/null; then
    echo "❌ DSP function not available - run: source ~/.bashrc"
    ALL_GOOD=false
fi

if [ "$ALL_GOOD" = true ]; then
    echo "✅ All checks passed! DSP command is working correctly"
    echo ""
    echo "🚀 Quick start:"
    echo "   dsp              - Start Claude Code"
    echo "   dsp /c           - Continue previous conversation"
    echo "   dsp --version    - Show Claude Code version"
else
    echo ""
    echo "⚠️  Some issues detected. See diagnostics above."
    echo ""
    echo "🔧 Quick fixes:"
    echo "   source ~/.bashrc          - Reload shell configuration"
    echo "   bash verify-dsp.sh        - Re-run this diagnostic"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
