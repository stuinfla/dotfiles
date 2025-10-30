#!/bin/bash

# Real-time Log Viewer for Dotfiles Installation
# Provides live monitoring and analysis of installation progress

# ==============================================================================
# CONFIGURATION
# ==============================================================================

LOG_DIR="${HOME}/.dotfiles-logs"
LATEST_LOG="${LOG_DIR}/latest.log"
STATUS_FILE="/tmp/dotfiles-status.txt"
ERROR_REPORT="/tmp/dotfiles-errors.txt"

# Display settings
REFRESH_INTERVAL=1
MAX_LINES=20

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ==============================================================================
# DISPLAY FUNCTIONS
# ==============================================================================

# Clear screen and reset cursor
clear_screen() {
    clear
    tput cup 0 0
}

# Draw header
draw_header() {
    echo -e "${BOLD}${BLUE}┌─────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${BLUE}│${RESET}  ${BOLD}Dotfiles Installation Monitor${RESET}                                   ${BOLD}${BLUE}│${RESET}"
    echo -e "${BOLD}${BLUE}│${RESET}  $(date +"%Y-%m-%d %H:%M:%S")                                            ${BOLD}${BLUE}│${RESET}"
    echo -e "${BOLD}${BLUE}└─────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

# Draw section separator
draw_separator() {
    local title="$1"
    echo -e "${BOLD}${CYAN}━━━ $title ━━━${RESET}"
    echo ""
}

# Display current status
display_status() {
    draw_separator "Current Status"

    if [[ -f "$STATUS_FILE" ]]; then
        while IFS= read -r line; do
            # Colorize based on log level
            if [[ "$line" =~ \[ERROR\] ]]; then
                echo -e "${RED}$line${RESET}"
            elif [[ "$line" =~ \[WARN\] ]]; then
                echo -e "${YELLOW}$line${RESET}"
            elif [[ "$line" =~ \[INFO\] ]]; then
                echo -e "${GREEN}$line${RESET}"
            else
                echo "$line"
            fi
        done < "$STATUS_FILE"
    else
        echo -e "${YELLOW}No status file found. Installation may not have started yet.${RESET}"
    fi

    echo ""
}

# Display recent log entries
display_recent_logs() {
    local num_lines="${1:-10}"

    draw_separator "Recent Logs (Last $num_lines lines)"

    if [[ -f "$LATEST_LOG" ]]; then
        tail -n "$num_lines" "$LATEST_LOG" | while IFS= read -r line; do
            # Colorize based on log level
            if [[ "$line" =~ ERROR ]]; then
                echo -e "${RED}$line${RESET}"
            elif [[ "$line" =~ WARN ]]; then
                echo -e "${YELLOW}$line${RESET}"
            elif [[ "$line" =~ INFO ]]; then
                echo -e "${GREEN}$line${RESET}"
            elif [[ "$line" =~ DEBUG ]]; then
                echo -e "${CYAN}$line${RESET}"
            else
                echo "$line"
            fi
        done
    else
        echo -e "${YELLOW}No log file found. Installation may not have started yet.${RESET}"
    fi

    echo ""
}

# Display statistics
display_statistics() {
    draw_separator "Statistics"

    if [[ -f "$LATEST_LOG" ]]; then
        local total_lines=$(wc -l < "$LATEST_LOG")
        local errors=$(grep -c "\[ERROR\]" "$LATEST_LOG" 2>/dev/null || echo "0")
        local warnings=$(grep -c "\[WARN\]" "$LATEST_LOG" 2>/dev/null || echo "0")
        local info=$(grep -c "\[INFO\]" "$LATEST_LOG" 2>/dev/null || echo "0")

        echo -e "${BOLD}Total log entries:${RESET} $total_lines"
        echo -e "${GREEN}${BOLD}INFO messages:${RESET}     $info"
        echo -e "${YELLOW}${BOLD}Warnings:${RESET}          $warnings"
        echo -e "${RED}${BOLD}Errors:${RESET}            $errors"

        # Calculate progress
        if [[ $total_lines -gt 0 ]]; then
            local progress=$((info * 100 / total_lines))
            echo -e "${BOLD}Progress:${RESET}          ${progress}%"
        fi
    else
        echo -e "${YELLOW}No statistics available yet.${RESET}"
    fi

    echo ""
}

# Display error summary
display_errors() {
    draw_separator "Error Summary"

    if [[ -f "$ERROR_REPORT" ]] && [[ -s "$ERROR_REPORT" ]]; then
        # Show first 10 lines of error report
        head -n 15 "$ERROR_REPORT"

        local total_errors=$(grep -c "^ERROR:" "$ERROR_REPORT" 2>/dev/null || echo "0")
        if [[ $total_errors -gt 5 ]]; then
            echo ""
            echo -e "${YELLOW}... and $((total_errors - 5)) more errors${RESET}"
            echo -e "View full report: ${BOLD}cat $ERROR_REPORT${RESET}"
        fi
    else
        echo -e "${GREEN}✓ No errors recorded${RESET}"
    fi

    echo ""
}

# Display help commands
display_help() {
    draw_separator "Available Commands"

    echo -e "${BOLD}q${RESET}       - Quit viewer"
    echo -e "${BOLD}r${RESET}       - Refresh display"
    echo -e "${BOLD}e${RESET}       - View full error report"
    echo -e "${BOLD}l${RESET}       - View full log file"
    echo -e "${BOLD}+/-${RESET}     - Increase/decrease log lines shown"
    echo -e "${BOLD}s${RESET}       - Show statistics"
    echo -e "${BOLD}f${RESET}       - Follow mode (auto-refresh)"
    echo ""
}

# ==============================================================================
# VIEWER MODES
# ==============================================================================

# Static snapshot mode
static_view() {
    clear_screen
    draw_header
    display_status
    display_recent_logs "$MAX_LINES"
    display_statistics
    display_errors
    display_help
}

# Follow mode (auto-refresh)
follow_mode() {
    echo -e "${BOLD}${GREEN}Follow mode enabled${RESET} (Press Ctrl+C to exit)"
    echo ""

    while true; do
        clear_screen
        draw_header
        display_status
        display_recent_logs "$MAX_LINES"
        display_statistics

        echo -e "${CYAN}Refreshing in ${REFRESH_INTERVAL}s... (Ctrl+C to stop)${RESET}"
        sleep "$REFRESH_INTERVAL"
    done
}

# Show full log file
view_full_log() {
    if [[ -f "$LATEST_LOG" ]]; then
        less -R "$LATEST_LOG"
    else
        echo -e "${RED}Log file not found: $LATEST_LOG${RESET}"
        sleep 2
    fi
}

# Show full error report
view_error_report() {
    if [[ -f "$ERROR_REPORT" ]]; then
        less -R "$ERROR_REPORT"
    else
        echo -e "${YELLOW}No error report found${RESET}"
        sleep 2
    fi
}

# ==============================================================================
# INTERACTIVE MODE
# ==============================================================================

interactive_mode() {
    while true; do
        static_view

        # Read single character
        read -rsn1 -p "Command: " input
        echo ""

        case "$input" in
            q|Q)
                echo "Exiting viewer..."
                exit 0
                ;;
            r|R)
                # Refresh (just loop again)
                continue
                ;;
            e|E)
                view_error_report
                ;;
            l|L)
                view_full_log
                ;;
            f|F)
                follow_mode
                ;;
            +)
                MAX_LINES=$((MAX_LINES + 5))
                ;;
            -)
                if [[ $MAX_LINES -gt 5 ]]; then
                    MAX_LINES=$((MAX_LINES - 5))
                fi
                ;;
            s|S)
                clear_screen
                draw_header
                display_statistics
                echo ""
                read -rsn1 -p "Press any key to continue..."
                ;;
            *)
                # Unknown command, just refresh
                continue
                ;;
        esac
    done
}

# ==============================================================================
# MAIN
# ==============================================================================

# Parse command line arguments
case "${1:-}" in
    --follow|-f)
        follow_mode
        ;;
    --log|-l)
        view_full_log
        ;;
    --errors|-e)
        view_error_report
        ;;
    --stats|-s)
        clear_screen
        draw_header
        display_statistics
        display_errors
        ;;
    --help|-h)
        echo "Dotfiles Installation Log Viewer"
        echo ""
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  --follow, -f     Follow mode (auto-refresh)"
        echo "  --log, -l        View full log file"
        echo "  --errors, -e     View error report"
        echo "  --stats, -s      Show statistics only"
        echo "  --help, -h       Show this help"
        echo ""
        echo "Interactive mode (default): Run without arguments"
        ;;
    *)
        # Default: interactive mode
        interactive_mode
        ;;
esac
