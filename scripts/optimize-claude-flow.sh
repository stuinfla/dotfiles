#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# CLAUDE FLOW RESOURCE OPTIMIZER
# Monitors system resources and dynamically optimizes Claude Flow settings
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration file
FLOW_DIR="${PWD}/.claude-flow"
METRICS_FILE="${FLOW_DIR}/metrics/system-metrics.json"
CONFIG_FILE="${FLOW_DIR}/swarm-config.json"

# ═══════════════════════════════════════════════════════════════════
# SYSTEM METRICS COLLECTION
# ═══════════════════════════════════════════════════════════════════

get_cpu_cores() {
    nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4"
}

get_memory_percent() {
    if [ -f "$METRICS_FILE" ]; then
        jq -r '.[-1].memoryUsagePercent // 0' "$METRICS_FILE" 2>/dev/null | awk '{printf "%.0f", $1}'
    else
        # Fallback: calculate directly
        if command -v free &> /dev/null; then
            free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}'
        else
            echo "50"  # Conservative default
        fi
    fi
}

get_cpu_load() {
    if [ -f "$METRICS_FILE" ]; then
        jq -r '.[-1].cpuLoad // 0' "$METRICS_FILE" 2>/dev/null | awk '{printf "%.0f", $1 * 100}'
    else
        # Fallback: use uptime
        uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' | awk '{printf "%.0f", $1 * 100}'
    fi
}

get_available_memory_gb() {
    if command -v free &> /dev/null; then
        free -g | awk '/^Mem:/ {print $2}'
    else
        sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}' || echo "8"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# RESOURCE THRESHOLDS & OPTIMIZATION RULES
# ═══════════════════════════════════════════════════════════════════

calculate_optimal_settings() {
    local cpu_cores=$1
    local mem_percent=$2
    local cpu_load=$3
    local total_mem_gb=$4

    # Calculate resource availability scores (0-100)
    local mem_available=$((100 - mem_percent))
    local cpu_available=$((100 - cpu_load))

    # Overall resource score (weighted average)
    local resource_score=$(( (mem_available * 60 + cpu_available * 40) / 100 ))

    # ═══════════════════════════════════════════════════════════════
    # AGENT COUNT OPTIMIZATION
    # ═══════════════════════════════════════════════════════════════

    local max_agents
    if [ "$resource_score" -ge 80 ]; then
        # Abundant resources: Use more agents
        max_agents=$((cpu_cores * 2))
    elif [ "$resource_score" -ge 60 ]; then
        # Good resources: Use ~1.5x cores
        max_agents=$((cpu_cores * 3 / 2))
    elif [ "$resource_score" -ge 40 ]; then
        # Moderate resources: Use cores 1:1
        max_agents=$cpu_cores
    else
        # Constrained resources: Use fewer agents
        max_agents=$((cpu_cores / 2))
        [ "$max_agents" -lt 2 ] && max_agents=2
    fi

    # Cap based on memory (minimum 512MB per agent)
    local mem_based_max=$((total_mem_gb * 2))
    [ "$max_agents" -gt "$mem_based_max" ] && max_agents=$mem_based_max

    # Absolute caps
    [ "$max_agents" -lt 2 ] && max_agents=2
    [ "$max_agents" -gt 50 ] && max_agents=50

    # ═══════════════════════════════════════════════════════════════
    # TOPOLOGY SELECTION
    # ═══════════════════════════════════════════════════════════════

    local topology
    if [ "$resource_score" -ge 70 ]; then
        topology="mesh"  # Best for parallel processing when resources available
    elif [ "$resource_score" -ge 50 ]; then
        topology="hierarchical"  # Balanced approach
    else
        topology="star"  # Most efficient for constrained resources
    fi

    # ═══════════════════════════════════════════════════════════════
    # STRATEGY SELECTION
    # ═══════════════════════════════════════════════════════════════

    local strategy
    if [ "$cpu_load" -lt 30 ] && [ "$mem_percent" -lt 50 ]; then
        strategy="aggressive"  # Maximize throughput
    elif [ "$cpu_load" -lt 60 ] && [ "$mem_percent" -lt 70 ]; then
        strategy="balanced"  # Standard approach
    else
        strategy="conservative"  # Protect system stability
    fi

    # ═══════════════════════════════════════════════════════════════
    # CONCURRENCY OPTIMIZATION
    # ═══════════════════════════════════════════════════════════════

    local concurrency
    if [ "$resource_score" -ge 80 ]; then
        concurrency=$((cpu_cores))
    elif [ "$resource_score" -ge 60 ]; then
        concurrency=$((cpu_cores * 3 / 4))
    else
        concurrency=$((cpu_cores / 2))
        [ "$concurrency" -lt 2 ] && concurrency=2
    fi

    # Return results as JSON
    cat <<EOF
{
  "maxAgents": $max_agents,
  "topology": "$topology",
  "strategy": "$strategy",
  "concurrency": $concurrency,
  "resourceScore": $resource_score,
  "reasoning": {
    "cpuCores": $cpu_cores,
    "memoryPercent": $mem_percent,
    "cpuLoad": $cpu_load,
    "totalMemoryGB": $total_mem_gb,
    "memoryAvailable": $mem_available,
    "cpuAvailable": $cpu_available
  }
}
EOF
}

# ═══════════════════════════════════════════════════════════════════
# MAIN OPTIMIZATION LOGIC
# ═══════════════════════════════════════════════════════════════════

main() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       CLAUDE FLOW RESOURCE OPTIMIZER                              ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Collect system metrics
    echo -e "${BLUE}📊 Collecting system metrics...${NC}"
    CPU_CORES=$(get_cpu_cores)
    MEM_PERCENT=$(get_memory_percent)
    CPU_LOAD=$(get_cpu_load)
    TOTAL_MEM_GB=$(get_available_memory_gb)

    echo -e "   ${MAGENTA}🖥️  CPU Cores:${NC} $CPU_CORES"
    echo -e "   ${GREEN}💾 Memory Used:${NC} ${MEM_PERCENT}%"
    echo -e "   ${YELLOW}⚙  CPU Load:${NC} ${CPU_LOAD}%"
    echo -e "   ${BLUE}📦 Total Memory:${NC} ${TOTAL_MEM_GB}GB"
    echo ""

    # Calculate optimal settings
    echo -e "${BLUE}🧮 Calculating optimal settings...${NC}"
    OPTIMAL=$(calculate_optimal_settings "$CPU_CORES" "$MEM_PERCENT" "$CPU_LOAD" "$TOTAL_MEM_GB")

    # Parse results
    MAX_AGENTS=$(echo "$OPTIMAL" | jq -r '.maxAgents')
    TOPOLOGY=$(echo "$OPTIMAL" | jq -r '.topology')
    STRATEGY=$(echo "$OPTIMAL" | jq -r '.strategy')
    CONCURRENCY=$(echo "$OPTIMAL" | jq -r '.concurrency')
    RESOURCE_SCORE=$(echo "$OPTIMAL" | jq -r '.resourceScore')

    # Display recommendations
    echo -e "${GREEN}✨ Recommended Configuration:${NC}"
    echo -e "   ${CYAN}Max Agents:${NC} $MAX_AGENTS"
    echo -e "   ${CYAN}Topology:${NC} $TOPOLOGY"
    echo -e "   ${CYAN}Strategy:${NC} $STRATEGY"
    echo -e "   ${CYAN}Concurrency:${NC} $CONCURRENCY"
    echo -e "   ${CYAN}Resource Score:${NC} ${RESOURCE_SCORE}/100"
    echo ""

    # Resource score interpretation
    if [ "$RESOURCE_SCORE" -ge 80 ]; then
        echo -e "${GREEN}🚀 EXCELLENT: Abundant resources - maximizing parallelization${NC}"
    elif [ "$RESOURCE_SCORE" -ge 60 ]; then
        echo -e "${CYAN}✅ GOOD: Healthy resources - balanced configuration${NC}"
    elif [ "$RESOURCE_SCORE" -ge 40 ]; then
        echo -e "${YELLOW}⚠️  MODERATE: Limited resources - conservative approach${NC}"
    else
        echo -e "${RED}🚨 CONSTRAINED: Low resources - minimal configuration${NC}"
    fi
    echo ""

    # Ask for confirmation
    read -p "$(echo -e ${YELLOW}Apply these settings? [y/N]:${NC} )" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create or update swarm config
        mkdir -p "$FLOW_DIR"

        if [ -f "$CONFIG_FILE" ]; then
            # Update existing config
            TMP_CONFIG=$(mktemp)
            jq --arg maxAgents "$MAX_AGENTS" \
               --arg topology "$TOPOLOGY" \
               --arg strategy "$STRATEGY" \
               --arg concurrency "$CONCURRENCY" \
               '.maxAgents = ($maxAgents | tonumber) |
                .topology = $topology |
                .defaultStrategy = $strategy |
                .concurrency = ($concurrency | tonumber)' \
               "$CONFIG_FILE" > "$TMP_CONFIG"
            mv "$TMP_CONFIG" "$CONFIG_FILE"
        else
            # Create new config
            cat > "$CONFIG_FILE" <<EOF
{
  "maxAgents": $MAX_AGENTS,
  "topology": "$TOPOLOGY",
  "defaultStrategy": "$STRATEGY",
  "concurrency": $CONCURRENCY,
  "optimizedAt": "$(date -Iseconds)",
  "resourceScore": $RESOURCE_SCORE
}
EOF
        fi

        echo -e "${GREEN}✅ Configuration applied to $CONFIG_FILE${NC}"
        echo ""
        echo -e "${CYAN}💡 To use these settings with Claude Flow:${NC}"
        echo -e "   ${MAGENTA}npx claude-flow@alpha swarm init --topology $TOPOLOGY --max-agents $MAX_AGENTS${NC}"
        echo ""
    else
        echo -e "${YELLOW}⏭️  Configuration not applied${NC}"
    fi

    # Save optimization report
    REPORT_FILE="${FLOW_DIR}/optimization-report.json"
    echo "$OPTIMAL" > "$REPORT_FILE"
    echo -e "${BLUE}📊 Full report saved to: $REPORT_FILE${NC}"
}

# Run optimizer
main
