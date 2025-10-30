#!/bin/bash

# Enhanced Logging System for Dotfiles Installer
# Provides comprehensive visibility into installation operations

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Log file locations
LOG_DIR="${HOME}/.dotfiles-logs"
CURRENT_LOG="${LOG_DIR}/installation-$(date +%Y%m%d-%H%M%S).log"
ERROR_REPORT="/tmp/dotfiles-errors.txt"
LATEST_LOG="${LOG_DIR}/latest.log"

# Status file for real-time display
VISIBLE_STATUS_FILE="/tmp/dotfiles-status.txt"

# Log level priorities (0=DEBUG, 1=INFO, 2=WARN, 3=ERROR)
# Using function for bash 3.x compatibility
get_log_level() {
    case "$1" in
        DEBUG) echo 0 ;;
        INFO) echo 1 ;;
        WARN) echo 2 ;;
        ERROR) echo 3 ;;
        *) echo 1 ;;  # Default to INFO
    esac
}

# Current minimum log level (set via environment or default to INFO)
CURRENT_LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Counters for summary
DEBUG_COUNT=0
INFO_COUNT=0
WARN_COUNT=0
ERROR_COUNT=0

# Color codes (using function for bash 3.x compatibility)
get_color() {
    case "$1" in
        DEBUG) echo "\033[0;36m" ;;   # Cyan
        INFO) echo "\033[0;32m" ;;    # Green
        WARN) echo "\033[0;33m" ;;    # Yellow
        ERROR) echo "\033[0;31m" ;;   # Red
        RESET) echo "\033[0m" ;;
        BOLD) echo "\033[1m" ;;
        *) echo "\033[0m" ;;
    esac
}

# ==============================================================================
# INITIALIZATION
# ==============================================================================

# Initialize logging system
init_logging() {
    # Create log directory
    mkdir -p "$LOG_DIR"

    # Create/clear status file
    echo "Installation starting..." > "$VISIBLE_STATUS_FILE"

    # Create/clear error report
    echo "Dotfiles Installation Error Report" > "$ERROR_REPORT"
    echo "Generated: $(date)" >> "$ERROR_REPORT"
    echo "========================================" >> "$ERROR_REPORT"
    echo "" >> "$ERROR_REPORT"

    # Create/clear current log
    {
        echo "=========================================="
        echo "Dotfiles Installation Log"
        echo "Started: $(date)"
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo "Log Level: $CURRENT_LOG_LEVEL"
        echo "=========================================="
        echo ""
    } > "$CURRENT_LOG"

    # Create symlink to latest log
    ln -sf "$CURRENT_LOG" "$LATEST_LOG"

    log_info "Logging system initialized"
    log_debug "Log file: $CURRENT_LOG"
    log_debug "Status file: $VISIBLE_STATUS_FILE"
}

# ==============================================================================
# CORE LOGGING FUNCTIONS
# ==============================================================================

# Check if message should be logged based on level
should_log() {
    local level="$1"
    local current_priority=$(get_log_level "$CURRENT_LOG_LEVEL")
    local message_priority=$(get_log_level "$level")

    [[ $message_priority -ge $current_priority ]]
}

# Write to log file
write_to_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    echo "[$timestamp] [$level] $message" >> "$CURRENT_LOG"
}

# Display to console
display_message() {
    local level="$1"
    local message="$2"
    local color=$(get_color "$level")
    local reset=$(get_color "RESET")
    local bold=$(get_color "BOLD")

    # Format based on level
    case "$level" in
        DEBUG)
            echo -e "${color}[DEBUG]${reset} $message"
            ;;
        INFO)
            echo -e "${color}✓${reset} $message"
            ;;
        WARN)
            echo -e "${bold}${color}⚠ WARNING:${reset} $message"
            ;;
        ERROR)
            echo -e "${bold}${color}✗ ERROR:${reset} $message" >&2
            ;;
    esac
}

# Update visible status file with recent logs
update_status_file() {
    local level="$1"
    local message="$2"

    # Add to status file (keep last 10 lines)
    # Use atomic write with lock for concurrent safety
    (
        # Simple lock mechanism
        local lockfile="${VISIBLE_STATUS_FILE}.lock"
        local lockfd=200

        # Try to acquire lock (with timeout)
        if command -v flock >/dev/null 2>&1; then
            exec 200>"$lockfile"
            flock -w 2 200 || return 1
        fi

        # Update status file
        {
            if [[ -f "$VISIBLE_STATUS_FILE" ]]; then
                tail -n 9 "$VISIBLE_STATUS_FILE" 2>/dev/null || true
            fi
            echo "[$(date +%H:%M:%S)] [$level] $message"
        } > "${VISIBLE_STATUS_FILE}.tmp"

        # Atomic move
        mv "${VISIBLE_STATUS_FILE}.tmp" "$VISIBLE_STATUS_FILE" 2>/dev/null || \
            cat "${VISIBLE_STATUS_FILE}.tmp" > "$VISIBLE_STATUS_FILE" 2>/dev/null

        # Release lock
        if command -v flock >/dev/null 2>&1; then
            flock -u 200
        fi
    )
}

# ==============================================================================
# PUBLIC LOGGING FUNCTIONS
# ==============================================================================

log_debug() {
    local message="$1"
    ((DEBUG_COUNT++))

    if should_log "DEBUG"; then
        write_to_log "DEBUG" "$message"
        display_message "DEBUG" "$message"
        update_status_file "DEBUG" "$message"
    else
        write_to_log "DEBUG" "$message"
    fi
}

log_info() {
    local message="$1"
    ((INFO_COUNT++))

    if should_log "INFO"; then
        write_to_log "INFO" "$message"
        display_message "INFO" "$message"
        update_status_file "INFO" "$message"
    fi
}

log_warn() {
    local message="$1"
    ((WARN_COUNT++))

    if should_log "WARN"; then
        write_to_log "WARN" "$message"
        display_message "WARN" "$message"
        update_status_file "WARN" "$message"

        # Add to error report
        echo "[WARNING] $message" >> "$ERROR_REPORT"
    fi
}

log_error() {
    local message="$1"
    local details="${2:-}"
    ((ERROR_COUNT++))

    write_to_log "ERROR" "$message"
    display_message "ERROR" "$message"
    update_status_file "ERROR" "$message"

    # Add to error report with details
    {
        echo ""
        echo "ERROR: $message"
        if [[ -n "$details" ]]; then
            echo "Details: $details"
        fi
        echo "Time: $(date)"
        echo "---"
    } >> "$ERROR_REPORT"
}

# ==============================================================================
# OPERATION TRACKING
# ==============================================================================

# Start tracking an operation
start_operation() {
    local operation="$1"
    local OPERATION_START=$(date +%s)
    export OPERATION_START

    log_info "Starting: $operation"
    update_status_file "INFO" "⏳ $operation"
}

# Complete an operation successfully
complete_operation() {
    local operation="$1"
    local duration=$(($(date +%s) - OPERATION_START))

    log_info "Completed: $operation (${duration}s)"
    update_status_file "INFO" "✓ $operation"
}

# Fail an operation
fail_operation() {
    local operation="$1"
    local error_msg="$2"
    local duration=$(($(date +%s) - OPERATION_START))

    log_error "Failed: $operation (${duration}s)" "$error_msg"
    update_status_file "ERROR" "✗ $operation"
}

# ==============================================================================
# ERROR HANDLING
# ==============================================================================

# Execute command with error capture
safe_execute() {
    local cmd="$1"
    local operation="${2:-Command}"
    local output
    local exit_code

    log_debug "Executing: $cmd"

    # Capture output and exit code
    output=$(eval "$cmd" 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_debug "$operation succeeded"
        if [[ -n "$output" ]]; then
            log_debug "Output: $output"
        fi
        return 0
    else
        log_error "$operation failed (exit code: $exit_code)" "$output"
        return $exit_code
    fi
}

# Catch and log error with context
catch_error() {
    local error_msg="$1"
    local suggestion="${2:-Check the log file for details}"

    log_error "$error_msg"
    log_info "Suggestion: $suggestion"
}

# ==============================================================================
# REAL-TIME MONITORING
# ==============================================================================

# Display recent log entries
show_recent_logs() {
    local count="${1:-10}"

    echo ""
    echo "Recent log entries:"
    echo "==================="
    tail -n "$count" "$CURRENT_LOG"
    echo ""
}

# Show current status
show_status() {
    if [[ -f "$VISIBLE_STATUS_FILE" ]]; then
        echo ""
        echo "Current Status:"
        echo "==============="
        cat "$VISIBLE_STATUS_FILE"
        echo ""
    fi
}

# Monitor log file in real-time (for debugging)
monitor_logs() {
    echo "Monitoring installation logs (Ctrl+C to stop)..."
    tail -f "$CURRENT_LOG"
}

# ==============================================================================
# SUMMARY AND REPORTING
# ==============================================================================

# Generate installation summary
generate_summary() {
    local total_issues=$((WARN_COUNT + ERROR_COUNT))

    echo ""
    echo "=========================================="
    echo "Installation Summary"
    echo "=========================================="
    echo "Total operations: $INFO_COUNT"
    echo "Warnings: $WARN_COUNT"
    echo "Errors: $ERROR_COUNT"
    echo "Debug messages: $DEBUG_COUNT"
    echo ""

    if [[ $total_issues -gt 0 ]]; then
        echo "⚠ $total_issues issue(s) encountered"
        echo "Error report: $ERROR_REPORT"
        echo "Full log: $CURRENT_LOG"
        echo ""

        if [[ $ERROR_COUNT -gt 0 ]]; then
            echo "Critical errors occurred. Installation may be incomplete."
            show_error_solutions
        fi
    else
        echo "✓ Installation completed successfully!"
    fi

    echo "=========================================="
}

# Show solutions for common errors
show_error_solutions() {
    echo ""
    echo "Common Solutions:"
    echo "=================="
    echo "1. Check for missing dependencies"
    echo "2. Verify file permissions"
    echo "3. Ensure sufficient disk space"
    echo "4. Review error report for specific issues"
    echo ""
    echo "For detailed troubleshooting:"
    echo "  cat $ERROR_REPORT"
    echo "  tail -n 50 $CURRENT_LOG"
    echo ""
}

# Write summary to log
write_summary_to_log() {
    {
        echo ""
        echo "=========================================="
        echo "Installation Completed"
        echo "Finished: $(date)"
        echo "Duration: $(($(date +%s) - START_TIME))s"
        echo "Warnings: $WARN_COUNT"
        echo "Errors: $ERROR_COUNT"
        echo "=========================================="
    } >> "$CURRENT_LOG"
}

# ==============================================================================
# CLEANUP
# ==============================================================================

# Cleanup and finalize logging
finalize_logging() {
    write_summary_to_log
    generate_summary

    # Keep only last 10 log files
    find "$LOG_DIR" -name "installation-*.log" -type f | \
        sort -r | \
        tail -n +11 | \
        xargs rm -f 2>/dev/null || true
}

# ==============================================================================
# EXPORTS
# ==============================================================================

# Export all public functions and variables
export -f init_logging
export -f log_debug log_info log_warn log_error
export -f start_operation complete_operation fail_operation
export -f safe_execute catch_error
export -f show_recent_logs show_status monitor_logs
export -f generate_summary finalize_logging

export LOG_DIR CURRENT_LOG ERROR_REPORT VISIBLE_STATUS_FILE
export WARN_COUNT ERROR_COUNT INFO_COUNT DEBUG_COUNT
