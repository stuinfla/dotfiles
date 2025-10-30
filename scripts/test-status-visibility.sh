#!/bin/bash
# Test Status Visibility System
# Run this script to validate that status updates work correctly

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
STATUS_FILE="$HOME/DOTFILES_STATUS.txt"
STATUS_LOG="$HOME/DOTFILES_STATUS.log"
TEST_RESULTS=()

# Source the status update functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/status-update.sh"

# Helper functions
pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    TEST_RESULTS+=("PASS: $1")
}

fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    TEST_RESULTS+=("FAIL: $1")
}

warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    TEST_RESULTS+=("WARN: $1")
}

# Test 1: File Creation Speed
test_file_creation_speed() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 1: File Creation Speed (Target: <1 second)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Clean up any existing files
    rm -f "$STATUS_FILE" "$STATUS_LOG"

    # Measure creation time
    start_time=$(date +%s.%N)
    init_status
    end_time=$(date +%s.%N)

    # Calculate elapsed time
    elapsed=$(echo "$end_time - $start_time" | bc)

    if [ -f "$STATUS_FILE" ]; then
        if (( $(echo "$elapsed < 1.0" | bc -l) )); then
            pass "Status file created in ${elapsed}s (target: <1s)"
        else
            warn "Status file created in ${elapsed}s (slower than target: 1s)"
        fi
    else
        fail "Status file was not created"
    fi
}

# Test 2: File Path Validity
test_file_path_validity() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 2: File Path Validity (Must be in home directory)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if file is in home directory
    if [[ "$STATUS_FILE" == "$HOME"* ]]; then
        pass "Status file is in home directory: $STATUS_FILE"
    else
        fail "Status file is NOT in home directory: $STATUS_FILE"
    fi

    # Check if HOME is defined
    if [ -n "$HOME" ]; then
        pass "\$HOME is defined: $HOME"
    else
        fail "\$HOME is not defined"
    fi

    # Check file exists and is readable
    if [ -r "$STATUS_FILE" ]; then
        pass "Status file exists and is readable"
    else
        fail "Status file is not readable"
    fi
}

# Test 3: Update Functionality
test_update_functionality() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 3: Update Functionality (Real-time updates)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test update_status function
    update_status "1/5" "🧪 Test update 1"
    sleep 1

    if grep -q "Test update 1" "$STATUS_FILE"; then
        pass "Status update 1 written successfully"
    else
        fail "Status update 1 not found in file"
    fi

    # Test log_step function
    log_step "Test step 1 completed"
    update_status "2/5" "🧪 Test update 2"
    sleep 1

    if grep -q "Test step 1 completed" "$STATUS_FILE"; then
        pass "Step logging works correctly"
    else
        fail "Step logging failed"
    fi

    # Test multiple updates
    for i in {3..5}; do
        update_status "$i/5" "🧪 Test update $i"
        sleep 0.5
    done

    if grep -q "Test update 5" "$STATUS_FILE"; then
        pass "Multiple sequential updates work"
    else
        fail "Sequential updates failed"
    fi
}

# Test 4: Content Format
test_content_format() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 4: Content Format (Readable output)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check for required sections
    if grep -q "DOTFILES INSTALLATION PROGRESS" "$STATUS_FILE"; then
        pass "Title section present"
    else
        fail "Title section missing"
    fi

    if grep -q "Last Updated:" "$STATUS_FILE"; then
        pass "Timestamp present"
    else
        fail "Timestamp missing"
    fi

    if grep -q "Current Step:" "$STATUS_FILE"; then
        pass "Step indicator present"
    else
        fail "Step indicator missing"
    fi

    if grep -q "Completed Steps:" "$STATUS_FILE"; then
        pass "Completed steps section present"
    else
        fail "Completed steps section missing"
    fi
}

# Test 5: Completion Status
test_completion_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 5: Completion Status (Success message)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test complete_status function
    complete_status

    if grep -q "INSTALLATION COMPLETE" "$STATUS_FILE"; then
        pass "Completion message displayed"
    else
        fail "Completion message missing"
    fi

    if grep -q "Next Steps:" "$STATUS_FILE"; then
        pass "Next steps instructions present"
    else
        fail "Next steps instructions missing"
    fi
}

# Test 6: Error Handling
test_error_handling() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 6: Error Handling (Failure messages)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test fail_status function
    fail_status "Test error message"

    if grep -q "INSTALLATION FAILED" "$STATUS_FILE"; then
        pass "Failure message displayed"
    else
        fail "Failure message missing"
    fi

    if grep -q "Test error message" "$STATUS_FILE"; then
        pass "Error message included in status"
    else
        fail "Error message not included"
    fi

    if grep -q "Troubleshooting:" "$STATUS_FILE"; then
        pass "Troubleshooting section present"
    else
        fail "Troubleshooting section missing"
    fi
}

# Test 7: VS Code Integration (Manual Check)
test_vscode_integration() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST 7: VS Code Integration (Manual verification required)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Attempt to open in VS Code
    echo "Attempting to open status file in VS Code..."

    if command -v code &> /dev/null; then
        code "$STATUS_FILE" &
        sleep 2

        if [ $? -eq 0 ]; then
            warn "VS Code open command executed (verify file opened in editor)"
        else
            fail "VS Code open command failed"
        fi
    else
        warn "VS Code CLI not available in this environment"
    fi

    # Print manual verification instructions
    echo ""
    echo "📋 Manual Verification Required:"
    echo "   1. Check if file is visible in VS Code Explorer"
    echo "   2. Verify file appears under 'home' or '~' directory"
    echo "   3. Confirm file updates are visible in real-time"
    echo "   4. Check if file opened automatically in editor"
    echo ""
}

# Main test execution
main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     STATUS VISIBILITY SYSTEM - AUTOMATED TESTS            ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    # Run all tests
    test_file_creation_speed
    test_file_path_validity
    test_update_functionality
    test_content_format
    test_completion_status
    test_error_handling
    test_vscode_integration

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local pass_count=0
    local fail_count=0
    local warn_count=0

    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == PASS:* ]]; then
            ((pass_count++))
        elif [[ $result == FAIL:* ]]; then
            ((fail_count++))
        elif [[ $result == WARN:* ]]; then
            ((warn_count++))
        fi
    done

    echo "Total Tests: ${#TEST_RESULTS[@]}"
    echo -e "${GREEN}Passed: $pass_count${NC}"
    echo -e "${RED}Failed: $fail_count${NC}"
    echo -e "${YELLOW}Warnings: $warn_count${NC}"

    echo ""
    echo "📄 Status file location: $STATUS_FILE"
    echo "📋 View status file: cat $STATUS_FILE"
    echo "🗑️  Clean up test files: rm -f $STATUS_FILE $STATUS_LOG"

    # Exit with appropriate code
    if [ $fail_count -gt 0 ]; then
        echo ""
        echo -e "${RED}❌ TESTS FAILED${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
        exit 0
    fi
}

# Run main function
main
