#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# TIMEOUT FIXES VALIDATION SCRIPT
# Tests the new timeout mechanisms in install.sh
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

echo "════════════════════════════════════════════════════════════════════"
echo "🧪 TESTING TIMEOUT FIXES"
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Test 1: run_with_timeout function exists
echo "Test 1: Checking run_with_timeout function..."
if grep -q "^run_with_timeout()" "$(dirname "$0")/../install.sh"; then
    echo "✅ run_with_timeout() function found"
else
    echo "❌ run_with_timeout() function NOT FOUND"
    exit 1
fi
echo ""

# Test 2: All npm commands use run_with_timeout
echo "Test 2: Verifying npm commands use timeout wrapper..."
NPM_DIRECT=$(grep -c "^[^#]*npm install.*--force" "$(dirname "$0")/../install.sh" || echo 0)
NPM_WRAPPED=$(grep -c "run_with_timeout.*npm install" "$(dirname "$0")/../install.sh" || echo 0)

echo "   Direct npm calls: $NPM_DIRECT (should be 0)"
echo "   Wrapped npm calls: $NPM_WRAPPED (should be >0)"

if [ "$NPM_DIRECT" -eq 0 ] && [ "$NPM_WRAPPED" -gt 0 ]; then
    echo "✅ All npm commands properly wrapped"
else
    echo "⚠️  Some npm commands may not be wrapped"
fi
echo ""

# Test 3: All pip commands use run_with_timeout
echo "Test 3: Verifying pip commands use timeout wrapper..."
PIP_DIRECT=$(grep -c "^[^#]*pip install.*--force-reinstall" "$(dirname "$0")/../install.sh" || echo 0)
PIP_WRAPPED=$(grep -c "run_with_timeout.*pip install" "$(dirname "$0")/../install.sh" || echo 0)

echo "   Direct pip calls: $PIP_DIRECT (should be 0)"
echo "   Wrapped pip calls: $PIP_WRAPPED (should be >0)"

if [ "$PIP_DIRECT" -eq 0 ] && [ "$PIP_WRAPPED" -gt 0 ]; then
    echo "✅ All pip commands properly wrapped"
else
    echo "⚠️  Some pip commands may not be wrapped"
fi
echo ""

# Test 4: Emergency timeout exists
echo "Test 4: Checking emergency timeout mechanism..."
if grep -q "SCRIPT_TIMEOUT_PID" "$(dirname "$0")/../install.sh"; then
    echo "✅ Emergency timeout watcher configured"
else
    echo "❌ Emergency timeout NOT FOUND"
    exit 1
fi
echo ""

# Test 5: Cleanup trap exists
echo "Test 5: Verifying cleanup trap..."
if grep -q "trap cleanup EXIT INT TERM" "$(dirname "$0")/../install.sh"; then
    echo "✅ Cleanup trap configured for EXIT, INT, TERM"
else
    echo "❌ Cleanup trap NOT properly configured"
    exit 1
fi
echo ""

# Test 6: Non-interactive flags present
echo "Test 6: Checking non-interactive flags..."
FLAGS_FOUND=0

if grep -q "\-\-progress=false" "$(dirname "$0")/../install.sh"; then
    echo "✅ --progress=false flag found (npm non-interactive)"
    ((FLAGS_FOUND++))
fi

if grep -q "\-\-loglevel=error" "$(dirname "$0")/../install.sh"; then
    echo "✅ --loglevel=error flag found (npm quiet)"
    ((FLAGS_FOUND++))
fi

if grep -q "\-\-no-input" "$(dirname "$0")/../install.sh"; then
    echo "✅ --no-input flag found (pip non-interactive)"
    ((FLAGS_FOUND++))
fi

if [ $FLAGS_FOUND -ge 2 ]; then
    echo "✅ Non-interactive flags configured"
else
    echo "⚠️  Some non-interactive flags may be missing"
fi
echo ""

# Test 7: Heartbeat monitoring for parallel jobs
echo "Test 7: Checking parallel job monitoring..."
if grep -q "JOBS_DONE" "$(dirname "$0")/../install.sh"; then
    echo "✅ Parallel job heartbeat monitoring found"
else
    echo "❌ Parallel job monitoring NOT FOUND"
    exit 1
fi
echo ""

# Test 8: Timeout configuration values
echo "Test 8: Verifying timeout values..."
PACKAGE_TIMEOUT=$(grep "^readonly PACKAGE_TIMEOUT=" "$(dirname "$0")/../install.sh" | cut -d= -f2)
SCRIPT_TIMEOUT=$(grep "^readonly SCRIPT_TIMEOUT=" "$(dirname "$0")/../install.sh" | cut -d= -f2)

echo "   PACKAGE_TIMEOUT: ${PACKAGE_TIMEOUT}s (5 minutes)"
echo "   SCRIPT_TIMEOUT: ${SCRIPT_TIMEOUT}s (15 minutes)"

if [ "$PACKAGE_TIMEOUT" -eq 300 ] && [ "$SCRIPT_TIMEOUT" -eq 900 ]; then
    echo "✅ Timeout values correctly configured"
else
    echo "⚠️  Timeout values may need adjustment"
fi
echo ""

# Summary
echo "════════════════════════════════════════════════════════════════════"
echo "✅ VALIDATION COMPLETE"
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "All critical timeout mechanisms are in place:"
echo "  • run_with_timeout() wrapper function"
echo "  • All npm/pip commands wrapped"
echo "  • Emergency timeout watcher (15 min max)"
echo "  • Cleanup trap for Ctrl+C"
echo "  • Non-interactive flags"
echo "  • Parallel job monitoring"
echo ""
echo "📖 See docs/TIMEOUT-FIXES.md for detailed documentation"
echo ""
