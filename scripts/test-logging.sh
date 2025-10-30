#!/bin/bash

# Test script for enhanced logging system
# Demonstrates all logging features and error handling

# ==============================================================================
# SETUP
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source logging system
# shellcheck source=scripts/enhanced-logging.sh
source "${SCRIPT_DIR}/enhanced-logging.sh"

START_TIME=$(date +%s)
export START_TIME

# Initialize
init_logging

# Set trap for cleanup
trap finalize_logging EXIT

# ==============================================================================
# TEST SCENARIOS
# ==============================================================================

test_basic_logging() {
    echo "Testing basic logging functions..."
    echo ""

    log_debug "This is a debug message"
    sleep 0.5

    log_info "This is an info message"
    sleep 0.5

    log_warn "This is a warning message"
    sleep 0.5

    log_error "This is an error message" "Additional error details go here"
    sleep 0.5

    echo ""
    echo "✓ Basic logging test complete"
    sleep 1
}

test_operations() {
    echo "Testing operation tracking..."
    echo ""

    # Successful operation
    start_operation "Sample successful operation"
    sleep 1
    safe_execute "echo 'Command executed successfully'" "Sample command"
    complete_operation "Sample successful operation"
    sleep 0.5

    # Failed operation
    start_operation "Sample failed operation"
    sleep 1
    if ! safe_execute "false" "Intentional failure"; then
        fail_operation "Sample failed operation" "This was meant to fail"
    fi
    sleep 0.5

    echo ""
    echo "✓ Operation tracking test complete"
    sleep 1
}

test_error_handling() {
    echo "Testing error handling..."
    echo ""

    # Simulate various errors
    catch_error "File not found" "Check if the file exists and has correct permissions"
    sleep 0.5

    catch_error "Network timeout" "Verify your internet connection and try again"
    sleep 0.5

    catch_error "Permission denied" "Run with appropriate permissions or use sudo"
    sleep 0.5

    echo ""
    echo "✓ Error handling test complete"
    sleep 1
}

test_real_world_scenario() {
    echo "Testing real-world installation scenario..."
    echo ""

    # Simulate package installation
    start_operation "Installing homebrew packages"
    sleep 1

    packages=("git" "zsh" "tmux" "neovim" "nonexistent-package")

    for package in "${packages[@]}"; do
        log_info "Installing $package..."
        sleep 0.3

        if [[ "$package" == "nonexistent-package" ]]; then
            log_error "Failed to install $package" "Package not found in repositories"
            catch_error "Package installation failed" "Check package name spelling"
        else
            log_info "$package installed successfully"
        fi
    done

    complete_operation "Installing homebrew packages"
    sleep 0.5

    # Simulate symlink creation
    start_operation "Creating configuration symlinks"
    sleep 1

    configs=(".zshrc" ".tmux.conf" ".vimrc")

    for config in "${configs[@]}"; do
        log_info "Creating symlink for $config"
        sleep 0.3

        if [[ "$config" == ".vimrc" ]]; then
            log_warn "Target file already exists, creating backup"
        fi

        log_info "Symlink created: ~/dotfiles/$config -> ~/$config"
    done

    complete_operation "Creating configuration symlinks"
    sleep 0.5

    echo ""
    echo "✓ Real-world scenario test complete"
    sleep 1
}

test_status_display() {
    echo "Testing status file updates..."
    echo ""

    log_info "Status updates should be visible in status file"
    sleep 0.5

    echo "Current status file contents:"
    show_status

    echo "✓ Status display test complete"
    sleep 1
}

test_concurrent_operations() {
    echo "Testing concurrent logging..."
    echo ""

    log_info "Starting multiple operations"

    # Simulate concurrent operations
    for i in {1..5}; do
        (
            log_debug "Background operation $i started"
            sleep 0.5
            log_info "Background operation $i completed"
        ) &
    done

    # Wait for all background jobs
    wait

    echo ""
    echo "✓ Concurrent operations test complete"
    sleep 1
}

# ==============================================================================
# MAIN TEST EXECUTION
# ==============================================================================

main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        Enhanced Logging System - Test Suite                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    log_info "Starting logging system tests"
    echo ""
    sleep 1

    # Run all tests
    test_basic_logging
    test_operations
    test_error_handling
    test_real_world_scenario
    test_status_display
    test_concurrent_operations

    # Show results
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        Test Suite Complete                                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    log_info "All tests completed"
    log_info "Log file: $CURRENT_LOG"
    log_info "Error report: $ERROR_REPORT"
    log_info "Status file: $VISIBLE_STATUS_FILE"

    echo ""
    echo "To view logs in real-time:"
    echo "  ${SCRIPT_DIR}/log-viewer.sh --follow"
    echo ""
    echo "To view the log file:"
    echo "  cat $CURRENT_LOG"
    echo ""
    echo "To view errors:"
    echo "  cat $ERROR_REPORT"
    echo ""

    return 0
}

# Run tests
main
