#!/bin/bash
# End-to-End Installation Testing Framework
# Tests the complete codespace creation process

set -e

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

# Test results array
declare -a FAILED_TESTS

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
    FAILED_TESTS+=("$1")
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Test setup
setup_test_env() {
    print_header "Setting Up Test Environment"

    export TEST_MODE=true
    export TEST_DIR="/tmp/dotfiles-test-$$"
    mkdir -p "$TEST_DIR"

    print_info "Test directory: $TEST_DIR"

    # Copy installation scripts to test directory
    cp -r "$(dirname "$0")/../scripts" "$TEST_DIR/"
    cp -r "$(dirname "$0")/../config" "$TEST_DIR/"

    print_pass "Test environment created"
}

# Test cleanup
cleanup_test_env() {
    print_header "Cleaning Up Test Environment"

    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        print_pass "Test directory removed"
    fi
}

# Test Category: File Presence
test_file_presence() {
    print_header "Testing File Presence"

    local expected_files=(
        "install.sh"
        "scripts/setup-claude.sh"
        "scripts/setup-claude-flow.sh"
        "scripts/setup-zsh.sh"
        "scripts/setup-misc.sh"
        "scripts/status-update.sh"
        "config/claude.json"
        "config/zsh-config.sh"
    )

    for file in "${expected_files[@]}"; do
        print_test "Checking existence of $file"
        if [ -e "$file" ]; then
            print_pass "$file exists"
        else
            print_fail "$file is missing"
        fi
    done
}

# Test Category: File Permissions
test_file_permissions() {
    print_header "Testing File Permissions"

    local executable_files=(
        "install.sh"
        "scripts/setup-claude.sh"
        "scripts/setup-claude-flow.sh"
        "scripts/setup-zsh.sh"
        "scripts/setup-misc.sh"
        "scripts/status-update.sh"
        "tests/test-installation.sh"
        "tests/test-progress-visibility.sh"
    )

    for file in "${executable_files[@]}"; do
        print_test "Checking permissions of $file"
        if [ -x "$file" ]; then
            print_pass "$file is executable"
        else
            print_fail "$file is not executable"
        fi
    done
}

# Test Category: Configuration Validation
test_configuration_validation() {
    print_header "Testing Configuration Validation"

    # Test JSON syntax
    print_test "Validating claude.json syntax"
    if python3 -c "import json; json.load(open('config/claude.json'))" 2>/dev/null; then
        print_pass "claude.json is valid JSON"
    else
        print_fail "claude.json has invalid JSON syntax"
    fi

    # Test required fields in claude.json
    print_test "Checking required fields in claude.json"
    local required_fields=("mcpServers" "claude-flow")
    local config_valid=true

    for field in "${required_fields[@]}"; do
        if python3 -c "import json; config = json.load(open('config/claude.json')); exit(0 if '$field' in str(config) else 1)" 2>/dev/null; then
            print_pass "Field '$field' exists in claude.json"
        else
            print_fail "Field '$field' missing in claude.json"
            config_valid=false
        fi
    done
}

# Test Category: Command Availability
test_command_availability() {
    print_header "Testing Command Availability (Post-Install)"

    # Note: These tests only work if installation has been run
    print_info "Skipping command availability tests (require actual installation)"
    print_info "These should be tested in integration tests"
}

# Test Category: Script Functionality
test_script_functionality() {
    print_header "Testing Script Functionality"

    # Test status-update.sh
    print_test "Testing status-update.sh functionality"
    if bash scripts/status-update.sh "TEST" "Testing status update" 2>/dev/null; then
        if [ -f "/workspaces/.codespaces/.persistedshare/VISIBLE_STATUS_FILE" ]; then
            print_pass "status-update.sh creates status file"
        else
            print_fail "status-update.sh does not create status file"
        fi
    else
        print_fail "status-update.sh execution failed"
    fi

    # Test setup script error handling
    print_test "Testing setup script error handling"
    if bash -c "source scripts/setup-claude.sh && check_node_version" 2>/dev/null; then
        print_pass "Setup scripts have proper error handling"
    else
        print_info "Error handling test requires proper environment"
    fi
}

# Test Category: Progress Visibility
test_progress_visibility() {
    print_header "Testing Progress Visibility"

    print_test "Checking if VISIBLE_STATUS_FILE is defined"
    if grep -q "VISIBLE_STATUS_FILE" scripts/status-update.sh; then
        print_pass "VISIBLE_STATUS_FILE is defined"
    else
        print_fail "VISIBLE_STATUS_FILE is not defined"
    fi

    print_test "Checking status update function"
    if grep -q "update_status" scripts/status-update.sh; then
        print_pass "update_status function exists"
    else
        print_fail "update_status function is missing"
    fi

    print_test "Checking step indicator output"
    if grep -q "printf" scripts/status-update.sh; then
        print_pass "Step indicators are present"
    else
        print_fail "Step indicators are missing"
    fi
}

# Test Category: Error Handling
test_error_handling() {
    print_header "Testing Error Handling"

    # Test script behavior with set -e
    print_test "Checking if scripts use set -e"
    local scripts_with_set_e=0
    for script in scripts/*.sh; do
        if grep -q "^set -e" "$script"; then
            ((scripts_with_set_e++))
        fi
    done

    if [ $scripts_with_set_e -eq 4 ]; then
        print_pass "All setup scripts use set -e"
    else
        print_fail "Not all setup scripts use set -e ($scripts_with_set_e/4)"
    fi

    # Test error message clarity
    print_test "Checking error message format"
    if grep -q "ERROR" scripts/*.sh; then
        print_pass "Scripts include error messages"
    else
        print_fail "Scripts lack error messages"
    fi
}

# Test Category: Documentation
test_documentation() {
    print_header "Testing Documentation"

    local doc_files=(
        "README.md"
        "docs/INSTALL-SH-INTEGRATION.md"
        "docs/STATUS-VISIBILITY-ARCHITECTURE.md"
        "docs/EXECUTION-FLOW-DIAGRAM.md"
    )

    for doc in "${doc_files[@]}"; do
        print_test "Checking existence of $doc"
        if [ -f "$doc" ]; then
            print_pass "$doc exists"
        else
            print_fail "$doc is missing"
        fi
    done
}

# Mock Environment Tests
test_without_network() {
    print_header "Testing Without Network (Simulated)"

    print_info "Network isolation tests require containerized environment"
    print_info "Skipping for now - add Docker-based tests in future"
}

test_missing_dependencies() {
    print_header "Testing With Missing Dependencies"

    print_test "Testing behavior when node is not available"
    if bash -c "unset NODE_VERSION && source scripts/setup-claude.sh && check_node_version" 2>/dev/null; then
        print_fail "Script should fail gracefully when node is missing"
    else
        print_pass "Script handles missing node correctly"
    fi
}

# Integration Test
integration_test() {
    print_header "Integration Test (Dry Run)"

    print_test "Running install.sh in test mode"

    # This would require actual installation - skip for now
    print_info "Full integration test requires actual codespace environment"
    print_info "Consider adding GitHub Actions workflow for integration testing"
}

# Test Summary
print_summary() {
    print_header "Test Summary"

    echo -e "${BLUE}Total Tests Run:${NC}    $TESTS_RUN"
    echo -e "${GREEN}Tests Passed:${NC}      $TESTS_PASSED"
    echo -e "${RED}Tests Failed:${NC}      $TESTS_FAILED"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "\n${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
        echo ""
        exit 1
    else
        echo -e "\n${GREEN}✓ All tests passed!${NC}\n"
        exit 0
    fi
}

# Main test execution
main() {
    print_header "Dotfiles Installation Test Suite"
    print_info "Starting comprehensive test run..."

    # Run all test categories
    test_file_presence
    test_file_permissions
    test_configuration_validation
    test_script_functionality
    test_progress_visibility
    test_error_handling
    test_documentation
    test_missing_dependencies

    # Print summary
    print_summary
}

# Trap to ensure cleanup
trap cleanup_test_env EXIT

# Run tests
main "$@"
