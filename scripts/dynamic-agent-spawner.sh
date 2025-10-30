#!/usr/bin/env bash
# Dynamic Agent Spawning System
# Spawns optimal number of agents based on system resources

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MIN_AGENTS=2
MAX_AGENTS_MULTIPLIER=0.75
CPU_USAGE_THRESHOLD=50
MEMORY_USAGE_THRESHOLD=80
CONTEXT_USAGE_THRESHOLD=75
CHECK_INTERVAL=5  # seconds

# ============================================================================
# SYSTEM RESOURCE DETECTION
# ============================================================================

get_cpu_cores() {
    local cores
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cores=$(sysctl -n hw.ncpu)
    else
        cores=$(nproc)
    fi
    echo "$cores"
}

get_cpu_usage() {
    local usage
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Get CPU usage from top (idle percentage)
        local idle=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | sed 's/%//')
        usage=$(echo "100 - $idle" | bc)
    else
        # Linux: use mpstat or top
        if command -v mpstat &> /dev/null; then
            usage=$(mpstat 1 1 | awk '/Average/ {print 100 - $NF}')
        else
            local idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
            usage=$idle
        fi
    fi
    printf "%.0f" "$usage"
}

get_memory_usage() {
    local usage
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: vm_stat
        local vm_stat=$(vm_stat)
        local pages_free=$(echo "$vm_stat" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        local pages_active=$(echo "$vm_stat" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        local pages_inactive=$(echo "$vm_stat" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
        local pages_speculative=$(echo "$vm_stat" | grep "Pages speculative" | awk '{print $3}' | sed 's/\.//')
        local pages_wired=$(echo "$vm_stat" | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')

        local page_size=$(pagesize)
        local total_pages=$((pages_free + pages_active + pages_inactive + pages_speculative + pages_wired))
        local used_pages=$((pages_active + pages_wired))

        usage=$(echo "scale=0; ($used_pages * 100) / $total_pages" | bc)
    else
        # Linux: free command
        usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    fi
    echo "$usage"
}

get_context_usage() {
    # Check if context usage is available from environment or config
    local context=${CLAUDE_CONTEXT_USAGE:-0}

    # Try to read from metrics file if available
    if [[ -f ".claude-flow/metrics/system-metrics.json" ]]; then
        context=$(jq -r '.context_usage // 0' .claude-flow/metrics/system-metrics.json 2>/dev/null || echo 0)
    fi

    echo "$context"
}

# ============================================================================
# AGENT CALCULATION
# ============================================================================

calculate_optimal_agents() {
    local cpu_cores=$1
    local cpu_usage=$2
    local memory_usage=$3
    local context_usage=$4

    # Start with base calculation: 75% of CPU cores
    local optimal=$(echo "$cpu_cores * $MAX_AGENTS_MULTIPLIER" | bc | awk '{print int($1)}')

    # Reduce if CPU usage is high
    if [[ $cpu_usage -gt $CPU_USAGE_THRESHOLD ]]; then
        echo -e "${YELLOW}⚠️  High CPU usage ($cpu_usage%), reducing agents${NC}" >&2
        optimal=$(echo "$optimal * 0.6" | bc | awk '{print int($1)}')
    fi

    # Reduce if memory usage is high
    if [[ $memory_usage -gt $MEMORY_USAGE_THRESHOLD ]]; then
        echo -e "${YELLOW}⚠️  High memory usage ($memory_usage%), reducing agents${NC}" >&2
        optimal=$(echo "$optimal * 0.5" | bc | awk '{print int($1)}')
    fi

    # Reduce if context usage is high
    if [[ $context_usage -gt $CONTEXT_USAGE_THRESHOLD ]]; then
        echo -e "${YELLOW}⚠️  High context usage ($context_usage%), reducing agents${NC}" >&2
        optimal=$(echo "$optimal * 0.7" | bc | awk '{print int($1)}')
    fi

    # Enforce min/max bounds
    if [[ $optimal -lt $MIN_AGENTS ]]; then
        optimal=$MIN_AGENTS
    fi

    local max_agents=$cpu_cores
    if [[ $optimal -gt $max_agents ]]; then
        optimal=$max_agents
    fi

    echo "$optimal"
}

# ============================================================================
# RESOURCE MONITORING
# ============================================================================

display_system_resources() {
    local cpu_cores=$1
    local cpu_usage=$2
    local memory_usage=$3
    local context_usage=$4
    local optimal_agents=$5

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 SYSTEM RESOURCES${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}CPU Cores:${NC}    $cpu_cores"
    echo -e "  ${GREEN}CPU Usage:${NC}    $cpu_usage%"
    echo -e "  ${GREEN}Memory Usage:${NC} $memory_usage%"
    echo -e "  ${GREEN}Context:${NC}      $context_usage%"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}Optimal Agents:${NC} ${YELLOW}$optimal_agents${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

monitor_resources_continuously() {
    local check_count=${1:-3}  # Number of checks
    local interval=${2:-$CHECK_INTERVAL}

    echo -e "${BLUE}🔍 Monitoring system resources...${NC}"

    for ((i=1; i<=check_count; i++)); do
        local cpu_cores=$(get_cpu_cores)
        local cpu_usage=$(get_cpu_usage)
        local memory_usage=$(get_memory_usage)
        local context_usage=$(get_context_usage)
        local optimal=$(calculate_optimal_agents "$cpu_cores" "$cpu_usage" "$memory_usage" "$context_usage")

        echo -e "${BLUE}Check $i/$check_count:${NC} CPU: $cpu_usage%, Memory: $memory_usage%, Context: $context_usage% → ${GREEN}$optimal agents${NC}"

        if [[ $i -lt $check_count ]]; then
            sleep "$interval"
        fi
    done

    echo ""
}

# ============================================================================
# AGENT SPAWNING
# ============================================================================

generate_agent_tasks() {
    local num_agents=$1
    local task_description="$2"
    local agent_type="${3:-coder}"

    echo "# Generated Agent Tasks (Claude Code Task Tool Syntax)"
    echo "# Spawn all agents in a SINGLE MESSAGE for parallel execution"
    echo ""
    echo "[Single Message - Parallel Agent Execution]:"

    for ((i=1; i<=num_agents; i++)); do
        echo "  Task(\"Agent $i\", \"$task_description - Part $i of $num_agents. Use hooks for coordination.\", \"$agent_type\")"
    done

    echo ""
    echo "  # Batch ALL todos together"
    echo "  TodoWrite { todos: ["
    for ((i=1; i<=num_agents; i++)); do
        local comma=","
        [[ $i -eq $num_agents ]] && comma=""
        echo "    {id: \"agent-$i\", content: \"Agent $i task\", status: \"in_progress\", priority: \"high\"}$comma"
    done
    echo "  ]}"
}

spawn_agents_based_on_resources() {
    local task_description="$1"
    local agent_type="${2:-coder}"
    local force_agents="${3:-0}"

    # Get current system resources
    local cpu_cores=$(get_cpu_cores)
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local context_usage=$(get_context_usage)

    # Calculate optimal agents
    local optimal_agents
    if [[ $force_agents -gt 0 ]]; then
        optimal_agents=$force_agents
        echo -e "${YELLOW}⚡ Force spawning $optimal_agents agents${NC}"
    else
        optimal_agents=$(calculate_optimal_agents "$cpu_cores" "$cpu_usage" "$memory_usage" "$context_usage")
    fi

    # Display resources
    display_system_resources "$cpu_cores" "$cpu_usage" "$memory_usage" "$context_usage" "$optimal_agents"

    # Generate agent tasks
    echo -e "${GREEN}🚀 Generating agent spawn configuration...${NC}"
    echo ""
    generate_agent_tasks "$optimal_agents" "$task_description" "$agent_type"

    # Save to file for reference
    local output_file="scripts/generated-agent-tasks.txt"
    generate_agent_tasks "$optimal_agents" "$task_description" "$agent_type" > "$output_file"
    echo -e "${GREEN}✅ Agent configuration saved to: $output_file${NC}"

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📋 NEXT STEPS:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  1. Copy the generated Task() calls above"
    echo -e "  2. Paste into a SINGLE MESSAGE to Claude Code"
    echo -e "  3. All $optimal_agents agents will spawn in parallel"
    echo -e "  4. Monitor progress with: ${YELLOW}watch -n 5 'ps aux | grep claude'${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================================================
# PARALLEL INSTALLATION INTEGRATION
# ============================================================================

spawn_installers_based_on_resources() {
    local packages_file="$1"

    if [[ ! -f "$packages_file" ]]; then
        echo -e "${RED}❌ Package file not found: $packages_file${NC}"
        return 1
    fi

    # Get current system resources
    local cpu_cores=$(get_cpu_cores)
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local context_usage=$(get_context_usage)

    # Calculate optimal agents
    local optimal_agents=$(calculate_optimal_agents "$cpu_cores" "$cpu_usage" "$memory_usage" "$context_usage")

    # Display resources
    display_system_resources "$cpu_cores" "$cpu_usage" "$memory_usage" "$context_usage" "$optimal_agents"

    # Read packages
    local packages=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        packages+=("$line")
    done < "$packages_file"

    local total_packages=${#packages[@]}
    local packages_per_agent=$(( (total_packages + optimal_agents - 1) / optimal_agents ))

    echo -e "${GREEN}🚀 Spawning $optimal_agents installer agents for $total_packages packages${NC}"
    echo -e "   Each agent handles ~$packages_per_agent packages"
    echo ""

    echo "[Single Message - Parallel Installation Agents]:"

    local agent_num=1
    for ((i=0; i<total_packages; i+=packages_per_agent)); do
        local end=$((i + packages_per_agent))
        [[ $end -gt $total_packages ]] && end=$total_packages

        local agent_packages="${packages[@]:$i:$packages_per_agent}"
        echo "  Task(\"Installer Agent $agent_num\", \"Install packages: $agent_packages. Use hooks for coordination.\", \"coder\")"

        ((agent_num++))
    done

    echo ""
    echo "  TodoWrite { todos: ["
    for ((i=1; i<=optimal_agents; i++)); do
        local comma=","
        [[ $i -eq $optimal_agents ]] && comma=""
        echo "    {id: \"installer-$i\", content: \"Installer Agent $i\", status: \"in_progress\", priority: \"high\"}$comma"
    done
    echo "  ]}"
}

# ============================================================================
# MAIN CLI
# ============================================================================

show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  resources              Display current system resources"
    echo "  monitor [checks]       Monitor resources continuously (default: 3 checks)"
    echo "  calculate              Calculate optimal agent count"
    echo "  spawn <task> [type]    Generate agent spawn configuration"
    echo "  install <file>         Generate installer agents for package list"
    echo ""
    echo "Options:"
    echo "  --force-agents N       Force specific number of agents"
    echo ""
    echo "Examples:"
    echo "  $0 resources"
    echo "  $0 monitor 5"
    echo "  $0 spawn \"Implement authentication\" coder"
    echo "  $0 spawn \"Implement authentication\" --force-agents 8"
    echo "  $0 install packages.txt"
}

main() {
    local command="${1:-}"

    case "$command" in
        resources)
            local cpu_cores=$(get_cpu_cores)
            local cpu_usage=$(get_cpu_usage)
            local memory_usage=$(get_memory_usage)
            local context_usage=$(get_context_usage)
            local optimal=$(calculate_optimal_agents "$cpu_cores" "$cpu_usage" "$memory_usage" "$context_usage")
            display_system_resources "$cpu_cores" "$cpu_usage" "$memory_usage" "$context_usage" "$optimal"
            ;;

        monitor)
            local checks="${2:-3}"
            monitor_resources_continuously "$checks"
            ;;

        calculate)
            local cpu_cores=$(get_cpu_cores)
            local cpu_usage=$(get_cpu_usage)
            local memory_usage=$(get_memory_usage)
            local context_usage=$(get_context_usage)
            local optimal=$(calculate_optimal_agents "$cpu_cores" "$cpu_usage" "$memory_usage" "$context_usage")
            echo "$optimal"
            ;;

        spawn)
            local task_description="${2:-Build feature}"
            local agent_type="${3:-coder}"
            local force_agents=0

            # Check for --force-agents flag
            if [[ "${3:-}" == "--force-agents" ]]; then
                force_agents="${4:-0}"
                agent_type="coder"
            elif [[ "${4:-}" == "--force-agents" ]]; then
                force_agents="${5:-0}"
            fi

            spawn_agents_based_on_resources "$task_description" "$agent_type" "$force_agents"
            ;;

        install)
            local packages_file="${2:-}"
            if [[ -z "$packages_file" ]]; then
                echo -e "${RED}❌ Package file required${NC}"
                show_usage
                exit 1
            fi
            spawn_installers_based_on_resources "$packages_file"
            ;;

        help|--help|-h)
            show_usage
            ;;

        *)
            echo -e "${RED}❌ Unknown command: $command${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
