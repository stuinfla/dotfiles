#!/bin/bash
# Progress Visibility Testing Framework
# Tests status file updates and terminal output clarity

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the status update script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if status-update.sh exists
if [ ! -f "$SCRIPT_DIR/../scripts/status-update.sh" ]; then
    echo -e "${RED}ERROR: status-update.sh not found${NC}"
    exit 1
fi

# Source with proper error handling
if ! source "$SCRIPT_DIR/../scripts/status-update.sh" 2>/dev/null; then
    echo -e "${RED}ERROR: Failed to source status-update.sh${NC}"
    exit 1
fi

# Verify VISIBLE_STATUS_FILE is set
if [ -z "${VISIBLE_STATUS_FILE:-}" ]; then
    echo -e "${YELLOW}WARNING: VISIBLE_STATUS_FILE not set, using default${NC}"
    export VISIBLE_STATUS_FILE="/tmp/test-status-$$"
fi

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
    ((TESTS_RUN++))
}

print_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Test Category: Status File Updates
test_status_file_updates() {
    print_header "Testing Status File Updates"

    # Test 1: Status file creation
    print_test "Status file is created on first update"
    rm -f "$VISIBLE_STATUS_FILE"
    update_status "TEST" "Test message"

    if [ -f "$VISIBLE_STATUS_FILE" ]; then
        print_pass "Status file created successfully"
    else
        print_fail "Status file was not created"
    fi

    # Test 2: Status file content
    print_test "Status file contains correct content"
    update_status "STEP" "Testing step content"

    if grep -q "STEP" "$VISIBLE_STATUS_FILE" && grep -q "Testing step content" "$VISIBLE_STATUS_FILE"; then
        print_pass "Status file content is correct"
    else
        print_fail "Status file content is incorrect"
    fi

    # Test 3: Multiple updates
    print_test "Status file handles multiple updates"
    update_status "STEP1" "First step"
    update_status "STEP2" "Second step"
    update_status "STEP3" "Third step"

    local line_count=$(wc -l < "$VISIBLE_STATUS_FILE")
    if [ "$line_count" -ge 3 ]; then
        print_pass "Status file handles multiple updates"
    else
        print_fail "Status file does not handle multiple updates correctly"
    fi

    # Test 4: Timestamp format
    print_test "Status updates include timestamps"
    update_status "TIME_TEST" "Testing timestamp"

    if grep -E '\[[0-9]{2}:[0-9]{2}:[0-9]{2}\]' "$VISIBLE_STATUS_FILE"; then
        print_pass "Timestamps are present and formatted correctly"
    else
        print_fail "Timestamps are missing or incorrectly formatted"
    fi

    # Test 5: Step indicators
    print_test "Step indicators are present"
    update_status "INDICATOR_TEST" "Testing indicators"

    if grep -q "◆" "$VISIBLE_STATUS_FILE" || grep -q "▶" "$VISIBLE_STATUS_FILE"; then
        print_pass "Step indicators are present"
    else
        print_fail "Step indicators are missing"
    fi
}

# Test Category: Terminal Output
test_terminal_output() {
    print_header "Testing Terminal Output Clarity"

    # Test 6: Output formatting
    print_test "Terminal output is properly formatted"
    local output=$(update_status "FORMAT_TEST" "Testing format" 2>&1)

    if echo "$output" | grep -q "FORMAT_TEST"; then
        print_pass "Terminal output is formatted"
    else
        print_fail "Terminal output is not formatted correctly"
    fi

    # Test 7: No spam output
    print_test "Updates don't produce excessive output"
    local output=$(update_status "SPAM_TEST" "Testing spam" 2>&1)
    local line_count=$(echo "$output" | wc -l)

    if [ "$line_count" -le 3 ]; then
        print_pass "Output is concise"
    else
        print_fail "Output is too verbose ($line_count lines)"
    fi

    # Test 8: Error messages are visible
    print_test "Error messages are visible"
    local error_output=$(update_status "ERROR" "Error message" 2>&1)

    if echo "$error_output" | grep -q "Error"; then
        print_pass "Error messages are visible"
    else
        print_fail "Error messages are not visible"
    fi
}

# Test Category: Status File Location
test_status_file_location() {
    print_header "Testing Status File Location"

    # Test 9: Correct directory
    print_test "Status file is in correct location"
    local expected_dir="/workspaces/.codespaces/.persistedshare"

    if [[ "$VISIBLE_STATUS_FILE" == "$expected_dir"* ]]; then
        print_pass "Status file is in correct location"
    else
        print_fail "Status file is not in expected location"
    fi

    # Test 10: Directory permissions
    print_test "Status file directory is writable"
    local status_dir=$(dirname "$VISIBLE_STATUS_FILE")

    if [ -w "$status_dir" ] || mkdir -p "$status_dir" 2>/dev/null; then
        print_pass "Status file directory is writable"
    else
        print_fail "Status file directory is not writable"
    fi
}

# Test Category: Integration with Install Script
test_install_integration() {
    print_header "Testing Integration with Install Script"

    # Test 11: Install script sources status-update
    print_test "Install script sources status-update.sh"
    if grep -q "source.*status-update.sh" "$SCRIPT_DIR/../install.sh"; then
        print_pass "Install script sources status-update.sh"
    else
        print_fail "Install script does not source status-update.sh"
    fi

    # Test 12: Setup scripts use update_status
    print_test "Setup scripts use update_status function"
    local scripts_using_status=0

    for script in "$SCRIPT_DIR/../scripts"/setup-*.sh; do
        if grep -q "update_status" "$script"; then
            ((scripts_using_status++))
        fi
    done

    if [ $scripts_using_status -ge 3 ]; then
        print_pass "Setup scripts use update_status ($scripts_using_status scripts)"
    else
        print_fail "Not enough setup scripts use update_status ($scripts_using_status scripts)"
    fi
}

# Test Category: Progress Tracking
test_progress_tracking() {
    print_header "Testing Progress Tracking"

    # Test 13: Progress percentage calculation
    print_test "Progress can be tracked"
    update_status "PROG_1" "Step 1 of 4"
    update_status "PROG_2" "Step 2 of 4"
    update_status "PROG_3" "Step 3 of 4"

    local step_count=$(grep -c "PROG_" "$VISIBLE_STATUS_FILE")
    if [ "$step_count" -eq 3 ]; then
        print_pass "Progress steps are tracked correctly"
    else
        print_fail "Progress tracking is incorrect"
    fi

    # Test 14: Completion status
    print_test "Completion status is clear"
    update_status "COMPLETE" "Installation complete"

    if grep -q "COMPLETE" "$VISIBLE_STATUS_FILE"; then
        print_pass "Completion status is recorded"
    else
        print_fail "Completion status is not recorded"
    fi
}

# Test Category: Error State Visibility
test_error_visibility() {
    print_header "Testing Error State Visibility"

    # Test 15: Error state is visible
    print_test "Error states are prominently displayed"
    update_status "ERROR" "Test error occurred"

    if grep -q "ERROR" "$VISIBLE_STATUS_FILE"; then
        print_pass "Error state is visible in status file"
    else
        print_fail "Error state is not visible"
    fi

    # Test 16: Error messages are detailed
    print_test "Error messages include details"
    update_status "ERROR" "Failed to install package: node not found"

    if grep -q "Failed to install" "$VISIBLE_STATUS_FILE"; then
        print_pass "Error messages include details"
    else
        print_fail "Error messages lack details"
    fi
}

# Test Category: Real-time Updates
test_realtime_updates() {
    print_header "Testing Real-time Update Behavior"

    # Test 17: File is immediately written
    print_test "Status file is updated immediately"
    local before_time=$(stat -c %Y "$VISIBLE_STATUS_FILE" 2>/dev/null || stat -f %m "$VISIBLE_STATUS_FILE" 2>/dev/null)
    sleep 1
    update_status "REALTIME" "Testing real-time update"
    local after_time=$(stat -c %Y "$VISIBLE_STATUS_FILE" 2>/dev/null || stat -f %m "$VISIBLE_STATUS_FILE" 2>/dev/null)

    if [ "$after_time" -gt "$before_time" ]; then
        print_pass "Status file is updated immediately"
    else
        print_fail "Status file update is delayed"
    fi

    # Test 18: No buffering issues
    print_test "Updates are not buffered"
    for i in {1..5}; do
        update_status "BUFFER_TEST_$i" "Testing buffering $i"
    done

    local update_count=$(grep -c "BUFFER_TEST" "$VISIBLE_STATUS_FILE")
    if [ "$update_count" -eq 5 ]; then
        print_pass "All updates are written (no buffering)"
    else
        print_fail "Updates are being buffered ($update_count/5 written)"
    fi
}

# Test Summary
print_summary() {
    print_header "Progress Visibility Test Summary"

    echo -e "${BLUE}Total Tests Run:${NC}    $TESTS_RUN"
    echo -e "${GREEN}Tests Passed:${NC}      $TESTS_PASSED"
    echo -e "${RED}Tests Failed:${NC}      $TESTS_FAILED"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "\n${RED}Some tests failed. Review output above for details.${NC}\n"
        exit 1
    else
        echo -e "\n${GREEN}✓ All progress visibility tests passed!${NC}\n"
        exit 0
    fi
}

# Cleanup
cleanup() {
    print_info "Cleaning up test artifacts..."
    # Keep the status file for review if tests failed
    if [ $TESTS_FAILED -eq 0 ]; then
        rm -f "$VISIBLE_STATUS_FILE"
    else
        print_info "Status file preserved at: $VISIBLE_STATUS_FILE"
    fi
}

# Main execution
main() {
    print_header "Progress Visibility Test Suite"
    print_info "Testing status file updates and terminal output..."

    # Ensure clean state
    rm -f "$VISIBLE_STATUS_FILE"

    # Run all test categories
    test_status_file_updates
    test_terminal_output
    test_status_file_location
    test_install_integration
    test_progress_tracking
    test_error_visibility
    test_realtime_updates

    # Print summary
    print_summary
}

# Trap to ensure cleanup
trap cleanup EXIT

# Run tests
main "$@"
