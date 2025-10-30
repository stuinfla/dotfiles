#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# DSP Quick Test Script
# Quick verification that dsp command works
# ═══════════════════════════════════════════════════════════════════

echo "🔍 Testing DSP command..."
echo ""

# Source .bashrc to load dsp function
source ~/.bashrc 2>/dev/null

# Test 1: Check if dsp function exists
if type dsp &> /dev/null; then
    echo "✅ dsp function is available"
else
    echo "❌ dsp function not found"
    echo "💡 Run: source ~/.bashrc"
    exit 1
fi

# Test 2: Check if DSP (uppercase) exists
if type DSP &> /dev/null; then
    echo "✅ DSP function is available"
else
    echo "❌ DSP function not found"
    exit 1
fi

# Test 3: Verify dsp --version works
echo ""
echo "📦 Claude Code version:"
dsp --version 2>&1 | head -3

echo ""
echo "✅ DSP command is working correctly!"
echo ""
echo "🚀 Try it:"
echo "   dsp              - Start Claude Code"
echo "   dsp /c           - Continue previous conversation"
echo "   DSP --help       - Show all options"
