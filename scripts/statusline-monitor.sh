#!/usr/bin/env bash
# VS Code Status Line Monitor
# Displays CPU cores, memory usage, and context window percentage

set -euo pipefail

# Output file for VS Code status line
OUTPUT_FILE="${OUTPUT_FILE:-/tmp/statusline.txt}"
CONTEXT_FILE="${CONTEXT_FILE:-/tmp/context-usage.txt}"

# Color codes for terminal output (optional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
OS_TYPE="$(uname -s)"

#######################################
# Get CPU information
#######################################
get_cpu_info() {
    local total_cores used_cores cpu_usage

    case "$OS_TYPE" in
        Darwin)
            # macOS
            total_cores=$(sysctl -n hw.ncpu)
            cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
            used_cores=$(echo "scale=1; $total_cores * $cpu_usage / 100" | bc)
            ;;
        Linux)
            # Linux
            total_cores=$(nproc)
            cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
            used_cores=$(echo "scale=1; $total_cores * $cpu_usage / 100" | bc)
            ;;
        *)
            total_cores="N/A"
            used_cores="N/A"
            ;;
    esac

    echo "${used_cores}/${total_cores}"
}

#######################################
# Get memory information
#######################################
get_memory_info() {
    local used_gb total_gb

    case "$OS_TYPE" in
        Darwin)
            # macOS - using vm_stat
            local pages_free pages_active pages_inactive pages_wired page_size
            page_size=$(pagesize)
            pages_free=$(vm_stat | awk '/Pages free/ {print $3}' | sed 's/\.//')
            pages_active=$(vm_stat | awk '/Pages active/ {print $3}' | sed 's/\.//')
            pages_inactive=$(vm_stat | awk '/Pages inactive/ {print $3}' | sed 's/\.//')
            pages_wired=$(vm_stat | awk '/Pages wired down/ {print $4}' | sed 's/\.//')

            # Calculate memory in GB
            local used_bytes=$((($pages_active + $pages_wired) * $page_size))
            local total_bytes=$(sysctl -n hw.memsize)
            used_gb=$(echo "scale=1; $used_bytes / 1073741824" | bc)
            total_gb=$(echo "scale=0; $total_bytes / 1073741824" | bc)
            ;;
        Linux)
            # Linux - using free
            local mem_info
            mem_info=$(free -g | awk '/^Mem:/ {print $3 "/" $2}')
            used_gb=$(echo "$mem_info" | cut -d'/' -f1)
            total_gb=$(echo "$mem_info" | cut -d'/' -f2)
            ;;
        *)
            used_gb="N/A"
            total_gb="N/A"
            ;;
    esac

    echo "${used_gb}/${total_gb}GB"
}

#######################################
# Get context window usage
#######################################
get_context_usage() {
    if [[ -f "$CONTEXT_FILE" ]]; then
        cat "$CONTEXT_FILE"
    else
        echo "N/A"
    fi
}

#######################################
# Format status line
#######################################
format_status_line() {
    local cpu_info memory_info context_usage
    cpu_info="$1"
    memory_info="$2"
    context_usage="$3"

    # Build status line with emojis
    echo "🖥️  CPU: ${cpu_info} | 💾 RAM: ${memory_info} | 📊 Context: ${context_usage}"
}

#######################################
# Get color based on percentage
#######################################
get_color() {
    local value=$1
    if (( $(echo "$value < 60" | bc -l) )); then
        echo "$GREEN"
    elif (( $(echo "$value < 80" | bc -l) )); then
        echo "$YELLOW"
    else
        echo "$RED"
    fi
}

#######################################
# Main monitoring loop
#######################################
monitor() {
    local interval="${1:-5}"

    echo "Starting VS Code status line monitor..."
    echo "Output file: $OUTPUT_FILE"
    echo "Context file: $CONTEXT_FILE"
    echo "Update interval: ${interval}s"
    echo "Press Ctrl+C to stop"
    echo ""

    while true; do
        cpu_info=$(get_cpu_info)
        memory_info=$(get_memory_info)
        context_usage=$(get_context_usage)

        status_line=$(format_status_line "$cpu_info" "$memory_info" "$context_usage")

        # Write to output file
        echo "$status_line" > "$OUTPUT_FILE"

        # Optional: Print to console with colors
        if [[ -t 1 ]]; then
            echo -ne "\r${status_line}${NC}"
        fi

        sleep "$interval"
    done
}

#######################################
# Update context usage
#######################################
update_context() {
    local used="${1:-0}"
    local total="${2:-200000}"
    local percentage

    percentage=$(echo "scale=1; $used * 100 / $total" | bc)
    echo "${percentage}%"
}

#######################################
# Main script
#######################################
main() {
    case "${1:-monitor}" in
        monitor)
            monitor "${2:-5}"
            ;;
        once)
            cpu_info=$(get_cpu_info)
            memory_info=$(get_memory_info)
            context_usage=$(get_context_usage)
            format_status_line "$cpu_info" "$memory_info" "$context_usage"
            ;;
        context)
            update_context "${2:-0}" "${3:-200000}" > "$CONTEXT_FILE"
            ;;
        help)
            cat <<EOF
VS Code Status Line Monitor

Usage:
    $0 [command] [options]

Commands:
    monitor [interval]    Start monitoring (default interval: 5s)
    once                  Get status once and exit
    context <used> <total> Update context usage
    help                  Show this help message

Environment Variables:
    OUTPUT_FILE          Output file path (default: /tmp/statusline.txt)
    CONTEXT_FILE         Context tracking file (default: /tmp/context-usage.txt)

Examples:
    # Start monitoring with 5s interval
    $0 monitor 5

    # Get status once
    $0 once

    # Update context usage (113000 used / 200000 total)
    $0 context 113000 200000

    # Run in background
    $0 monitor 5 &

Setup VS Code:
    1. Install extension: "Custom Status Bar"
    2. Add to settings.json:
       {
         "customStatusBar.items": [
           {
             "text": "\$(file-code) Status",
             "tooltip": "System Status",
             "command": "workbench.action.terminal.toggleTerminal",
             "alignment": "right",
             "priority": 100,
             "interval": 5000,
             "textSource": "file:///tmp/statusline.txt"
           }
         ]
       }
EOF
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
