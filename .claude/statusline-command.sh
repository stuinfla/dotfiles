
#!/bin/bash

# Read JSON input from stdin
INPUT=$(cat)
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd')
DIR=$(basename "$CWD")

# Replace claude-code-flow with branded name
if [ "$DIR" = "claude-code-flow" ]; then
  DIR="🌊 Claude Flow"
fi

# Get git branch
BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null)

# Start building statusline
printf "\033[1m$MODEL\033[0m in \033[36m$DIR\033[0m"
[ -n "$BRANCH" ] && printf " on \033[33m⎇ $BRANCH\033[0m"

# Context Window Usage (ALWAYS shown - critical for token awareness)
CONTEXT_USED=$(echo "$INPUT" | jq -r '.context.used // 0')
CONTEXT_TOTAL=$(echo "$INPUT" | jq -r '.context.total // 200000')

if [ "$CONTEXT_TOTAL" -gt 0 ]; then
  CONTEXT_PCT=$(awk "BEGIN {printf \"%.0f\", ($CONTEXT_USED / $CONTEXT_TOTAL) * 100}")
  CONTEXT_REMAINING=$(awk "BEGIN {printf \"%.0f\", $CONTEXT_TOTAL - $CONTEXT_USED}")

  # Format tokens with K suffix for readability
  if [ "$CONTEXT_USED" -gt 1000 ]; then
    CONTEXT_USED_K=$(awk "BEGIN {printf \"%.1fK\", $CONTEXT_USED / 1000}")
  else
    CONTEXT_USED_K="${CONTEXT_USED}"
  fi

  if [ "$CONTEXT_TOTAL" -gt 1000 ]; then
    CONTEXT_TOTAL_K=$(awk "BEGIN {printf \"%.0fK\", $CONTEXT_TOTAL / 1000}")
  else
    CONTEXT_TOTAL_K="${CONTEXT_TOTAL}"
  fi

  if [ "$CONTEXT_REMAINING" -gt 1000 ]; then
    CONTEXT_REMAINING_K=$(awk "BEGIN {printf \"%.0fK\", $CONTEXT_REMAINING / 1000}")
  else
    CONTEXT_REMAINING_K="${CONTEXT_REMAINING}"
  fi

  # Color-coded context (green <60%, yellow 60-85%, red >85%)
  if [ "$CONTEXT_PCT" -lt 60 ]; then
    CONTEXT_COLOR="\033[32m"  # Green - plenty available
  elif [ "$CONTEXT_PCT" -lt 85 ]; then
    CONTEXT_COLOR="\033[33m"  # Yellow - getting full
  else
    CONTEXT_COLOR="\033[31m"  # Red - nearly full
  fi

  printf " │ ${CONTEXT_COLOR}📝 ${CONTEXT_USED_K}/${CONTEXT_TOTAL_K} (${CONTEXT_PCT}%% • ${CONTEXT_REMAINING_K} left)\033[0m"
fi

# Claude-Flow integration
FLOW_DIR="$CWD/.claude-flow"

if [ -d "$FLOW_DIR" ]; then
  printf " │"

  # 1. Swarm Configuration & Topology
  if [ -f "$FLOW_DIR/swarm-config.json" ]; then
    STRATEGY=$(jq -r '.defaultStrategy // empty' "$FLOW_DIR/swarm-config.json" 2>/dev/null)
    if [ -n "$STRATEGY" ]; then
      # Map strategy to topology icon
      case "$STRATEGY" in
        "balanced") TOPO_ICON="⚡mesh" ;;
        "conservative") TOPO_ICON="⚡hier" ;;
        "aggressive") TOPO_ICON="⚡ring" ;;
        *) TOPO_ICON="⚡$STRATEGY" ;;
      esac
      printf " \033[35m$TOPO_ICON\033[0m"

      # Count agent profiles as "configured agents"
      AGENT_COUNT=$(jq -r '.agentProfiles | length' "$FLOW_DIR/swarm-config.json" 2>/dev/null)
      if [ -n "$AGENT_COUNT" ] && [ "$AGENT_COUNT" != "null" ] && [ "$AGENT_COUNT" -gt 0 ]; then
        printf "  \033[35m🤖 $AGENT_COUNT\033[0m"
      fi
    fi
  fi

  # 2. Real-time System Metrics (showing used/total for clarity)
  if [ -f "$FLOW_DIR/metrics/system-metrics.json" ]; then
    # Get latest metrics (last entry in array)
    LATEST=$(jq -r '.[-1]' "$FLOW_DIR/metrics/system-metrics.json" 2>/dev/null)

    if [ -n "$LATEST" ] && [ "$LATEST" != "null" ]; then
      # CPU cores: Show cores in use / total cores
      CPU_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "?")
      CPU_LOAD=$(echo "$LATEST" | jq -r '.cpuLoad // 0' | awk '{printf "%.2f", $1}')

      if [ "$CPU_LOAD" != "0" ] && [ "$CPU_LOAD" != "null" ]; then
        # Estimate cores in use based on load average
        CORES_USED=$(awk "BEGIN {printf \"%.1f\", $CPU_LOAD * $CPU_CORES}")
        printf "  \033[35m🖥️  ${CORES_USED}/${CPU_CORES}\033[0m"
      else
        printf "  \033[35m🖥️  ${CPU_CORES}c\033[0m"
      fi

      # Memory: Show used/total in GB
      MEM_USED_PCT=$(echo "$LATEST" | jq -r '.memoryUsagePercent // 0' | awk '{printf "%.0f", $1}')
      if [ -n "$MEM_USED_PCT" ] && [ "$MEM_USED_PCT" != "null" ]; then
        # Get total memory in GB
        TOTAL_MEM=$(free -g 2>/dev/null | awk '/^Mem:/ {print $2}' || sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}' || echo "?")
        USED_MEM=$(awk "BEGIN {printf \"%.1f\", $TOTAL_MEM * $MEM_USED_PCT / 100}")

        # Color-coded memory (green <60% used, yellow 60-80%, red >80%)
        if [ "$MEM_USED_PCT" -lt 60 ]; then
          MEM_COLOR="\033[32m"  # Green - plenty available
        elif [ "$MEM_USED_PCT" -lt 80 ]; then
          MEM_COLOR="\033[33m"  # Yellow - moderate usage
        else
          MEM_COLOR="\033[31m"  # Red - high usage
        fi
        printf "  ${MEM_COLOR}💾 ${USED_MEM}/${TOTAL_MEM}GB\033[0m"
      fi

      # CPU load: Show percentage used
      CPU_LOAD_PCT=$(echo "$LATEST" | jq -r '.cpuLoad // 0' | awk '{printf "%.0f", $1 * 100}')
      if [ -n "$CPU_LOAD_PCT" ] && [ "$CPU_LOAD_PCT" != "null" ]; then
        # Color-coded CPU (green <50%, yellow 50-75%, red >75%)
        if [ "$CPU_LOAD_PCT" -lt 50 ]; then
          CPU_COLOR="\033[32m"  # Green - low load
        elif [ "$CPU_LOAD_PCT" -lt 75 ]; then
          CPU_COLOR="\033[33m"  # Yellow - moderate load
        else
          CPU_COLOR="\033[31m"  # Red - high load
        fi
        printf "  ${CPU_COLOR}⚙ ${CPU_LOAD_PCT}%\033[0m"
      fi
    fi
  fi

  # 3. Session State
  if [ -f "$FLOW_DIR/session-state.json" ]; then
    SESSION_ID=$(jq -r '.sessionId // empty' "$FLOW_DIR/session-state.json" 2>/dev/null)
    ACTIVE=$(jq -r '.active // false' "$FLOW_DIR/session-state.json" 2>/dev/null)

    if [ "$ACTIVE" = "true" ] && [ -n "$SESSION_ID" ]; then
      # Show abbreviated session ID
      SHORT_ID=$(echo "$SESSION_ID" | cut -d'-' -f1)
      printf "  \033[34m🔄 $SHORT_ID\033[0m"
    fi
  fi

  # 4. Performance Metrics from task-metrics.json
  if [ -f "$FLOW_DIR/metrics/task-metrics.json" ]; then
    # Parse task metrics for success rate, avg time, and streak
    METRICS=$(jq -r '
      # Calculate metrics
      (map(select(.success == true)) | length) as $successful |
      (length) as $total |
      (if $total > 0 then ($successful / $total * 100) else 0 end) as $success_rate |
      (map(.duration // 0) | add / length) as $avg_duration |
      # Calculate streak (consecutive successes from end)
      (reverse |
        reduce .[] as $task (0;
          if $task.success == true then . + 1 else 0 end
        )
      ) as $streak |
      {
        success_rate: $success_rate,
        avg_duration: $avg_duration,
        streak: $streak,
        total: $total
      } | @json
    ' "$FLOW_DIR/metrics/task-metrics.json" 2>/dev/null)

    if [ -n "$METRICS" ] && [ "$METRICS" != "null" ]; then
      # Success Rate
      SUCCESS_RATE=$(echo "$METRICS" | jq -r '.success_rate // 0' | awk '{printf "%.0f", $1}')
      TOTAL_TASKS=$(echo "$METRICS" | jq -r '.total // 0')

      if [ -n "$SUCCESS_RATE" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
        # Color-code: Green (>80%), Yellow (60-80%), Red (<60%)
        if [ "$SUCCESS_RATE" -gt 80 ]; then
          SUCCESS_COLOR="\033[32m"  # Green
        elif [ "$SUCCESS_RATE" -ge 60 ]; then
          SUCCESS_COLOR="\033[33m"  # Yellow
        else
          SUCCESS_COLOR="\033[31m"  # Red
        fi
        printf "  ${SUCCESS_COLOR}🎯 ${SUCCESS_RATE}%\033[0m"
      fi

      # Average Time
      AVG_TIME=$(echo "$METRICS" | jq -r '.avg_duration // 0')
      if [ -n "$AVG_TIME" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
        # Format smartly: seconds, minutes, or hours
        if [ $(echo "$AVG_TIME < 60" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
          TIME_STR=$(echo "$AVG_TIME" | awk '{printf "%.1fs", $1}')
        elif [ $(echo "$AVG_TIME < 3600" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
          TIME_STR=$(echo "$AVG_TIME" | awk '{printf "%.1fm", $1/60}')
        else
          TIME_STR=$(echo "$AVG_TIME" | awk '{printf "%.1fh", $1/3600}')
        fi
        printf "  \033[36m⏱️  $TIME_STR\033[0m"
      fi

      # Streak (only show if > 0)
      STREAK=$(echo "$METRICS" | jq -r '.streak // 0')
      if [ -n "$STREAK" ] && [ "$STREAK" -gt 0 ]; then
        printf "  \033[91m🔥 $STREAK\033[0m"
      fi
    fi
  fi

  # 5. Active Tasks (check for task files)
  if [ -d "$FLOW_DIR/tasks" ]; then
    TASK_COUNT=$(find "$FLOW_DIR/tasks" -name "*.json" -type f 2>/dev/null | wc -l)
    if [ "$TASK_COUNT" -gt 0 ]; then
      printf "  \033[36m📋 $TASK_COUNT\033[0m"
    fi
  fi

  # 6. Check for hooks activity
  if [ -f "$FLOW_DIR/hooks-state.json" ]; then
    HOOKS_ACTIVE=$(jq -r '.enabled // false' "$FLOW_DIR/hooks-state.json" 2>/dev/null)
    if [ "$HOOKS_ACTIVE" = "true" ]; then
      printf " \033[35m🔗\033[0m"
    fi
  fi
fi

echo
