#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# CLAUDE FLOW AUTO-OPTIMIZER ALIASES
# Quick commands for resource optimization
# ═══════════════════════════════════════════════════════════════════

# Quick optimize - run the optimizer
alias cf-optimize='bash ~/scripts/optimize-claude-flow.sh'
alias cfo='bash ~/scripts/optimize-claude-flow.sh'

# Auto-optimize before starting swarm (recommended)
alias cf-swarm='bash ~/scripts/optimize-claude-flow.sh && npx claude-flow@alpha swarm init'

# Show current resource usage
alias cf-resources='echo "🖥️  CPU Cores: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null)" && \
                    echo "💾 Memory: $(free -h 2>/dev/null | awk '\''NR==2{print $3"/"$2}'\'' || echo "N/A")" && \
                    echo "⚙️  CPU Load: $(uptime | awk -F'\''load average:'\'' '\''{print $2}'\'' | awk '\''{print $1}'\'')" && \
                    [ -f .claude-flow/swarm-config.json ] && \
                    echo "🤖 Max Agents: $(jq -r '\''.maxAgents // "not configured"'\'' .claude-flow/swarm-config.json 2>/dev/null)" && \
                    echo "⚡ Topology: $(jq -r '\''.topology // "not configured"'\'' .claude-flow/swarm-config.json 2>/dev/null)"'

# Show optimization recommendations (non-interactive)
alias cf-recommend='CPU=$(nproc 2>/dev/null || echo 4); \
                     MEM=$(free 2>/dev/null | awk '\''NR==2{printf "%.0f", $3/$2*100}'\'' || echo 50); \
                     if [ $MEM -lt 50 ] && [ $(uptime | awk -F'\''load average:'\'' '\''{print $2}'\'' | awk '\''{printf "%.0f", $1*100}'\'') -lt 30 ]; then \
                         echo "🚀 RECOMMENDATION: Use aggressive mode - abundant resources"; \
                         echo "   Max agents: $((CPU * 2)), Topology: mesh"; \
                     elif [ $MEM -lt 70 ]; then \
                         echo "✅ RECOMMENDATION: Use balanced mode - good resources"; \
                         echo "   Max agents: $((CPU * 3 / 2)), Topology: hierarchical"; \
                     else \
                         echo "⚠️  RECOMMENDATION: Use conservative mode - limited resources"; \
                         echo "   Max agents: $((CPU / 2)), Topology: star"; \
                     fi'

# Function to auto-optimize based on current metrics (silent)
cf_auto_optimize() {
    local FLOW_DIR="${PWD}/.claude-flow"

    # Only auto-optimize if in a project with Claude Flow
    if [ ! -d "$FLOW_DIR" ]; then
        return
    fi

    # Check if optimization is stale (> 1 hour)
    local CONFIG_FILE="${FLOW_DIR}/swarm-config.json"
    if [ -f "$CONFIG_FILE" ]; then
        local OPTIMIZED_AT=$(jq -r '.optimizedAt // empty' "$CONFIG_FILE" 2>/dev/null)
        if [ -n "$OPTIMIZED_AT" ]; then
            local NOW=$(date +%s)
            local THEN=$(date -d "$OPTIMIZED_AT" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${OPTIMIZED_AT:0:19}" +%s 2>/dev/null || echo 0)
            local AGE=$(( (NOW - THEN) / 60 ))

            if [ "$AGE" -lt 60 ]; then
                # Configuration is fresh, skip
                return
            fi
        fi
    fi

    # Run quick optimization in background
    (bash ~/scripts/optimize-claude-flow.sh --auto 2>/dev/null &)
}

# Auto-optimize on directory change to Claude Flow projects
if command -v add-zsh-hook &> /dev/null; then
    # Zsh
    add-zsh-hook chpwd cf_auto_optimize
elif [[ "$PROMPT_COMMAND" ]]; then
    # Bash
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }cf_auto_optimize"
fi
