# ═══════════════════════════════════════════════════════════════════
# CODESPACES BASHRC - Stuart's Development Environment
# Auto-updates daily: Claude Code, SuperClaude, Claude Flow, VS Code
# ═══════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# DAILY AUTO-UPDATE SYSTEM (Silent Background Updates)
# ═══════════════════════════════════════════════════════════════════

# Run auto-update script in background (non-blocking, silent)
if [ -f "$HOME/.dotfiles/scripts/auto-update.sh" ]; then
    bash "$HOME/.dotfiles/scripts/auto-update.sh" &
    disown
elif [ -f "$HOME/dotfiles/scripts/auto-update.sh" ]; then
    bash "$HOME/dotfiles/scripts/auto-update.sh" &
    disown
fi

# Run auto-git-save script in background (5-minute auto-commit/push)
if [ -f "$HOME/.dotfiles/scripts/auto-git-save.sh" ]; then
    bash "$HOME/.dotfiles/scripts/auto-git-save.sh" &
    disown
elif [ -f "$HOME/dotfiles/scripts/auto-git-save.sh" ]; then
    bash "$HOME/dotfiles/scripts/auto-git-save.sh" &
    disown
fi

# ═══════════════════════════════════════════════════════════════════
# CLAUDE CODE ALIASES
# ═══════════════════════════════════════════════════════════════════

# DSP/dsp - Start Claude Code (skip permissions with ANTHROPIC_CLAUDE_CODE_SKIP_PERMISSIONS)
# Supports /c flag for --continue
dsp() {
  if [ "$1" = "/c" ]; then
    ANTHROPIC_CLAUDE_CODE_SKIP_PERMISSIONS=true claude --continue "${@:2}"
  else
    ANTHROPIC_CLAUDE_CODE_SKIP_PERMISSIONS=true claude "$@"
  fi
}
DSP() { dsp "$@"; }

# DSB/dsb - Start Claude Code in background
dsb() { ANTHROPIC_CLAUDE_CODE_SKIP_PERMISSIONS=true claude "$@" & }
DSB() { dsb "$@"; }

# ═══════════════════════════════════════════════════════════════════
# AUTHENTICATION CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

# Claude Code CLI uses subscription (NOT pay-per-token)
# Run 'dsp setup-token' once to authenticate with your Claude Code Max subscription
# Applications use $ANTHROPIC_API_KEY from GitHub Codespaces Secrets

# Make API key available to applications but NOT exported to Claude Code CLI
if [ -n "$ANTHROPIC_API_KEY" ]; then
    # API key is available for apps to access via environment
    # Do NOT export to Claude Code CLI to ensure it uses subscription
    true
fi

# ═══════════════════════════════════════════════════════════════════
# SESSION MANAGEMENT
# ═══════════════════════════════════════════════════════════════════

# Enable session resume (store sessions in ~/.claude-sessions)
export CLAUDE_CODE_SESSION_DIR="$HOME/.claude-sessions"
mkdir -p "$CLAUDE_CODE_SESSION_DIR"

# ═══════════════════════════════════════════════════════════════════
# HELPFUL COMMANDS
# ═══════════════════════════════════════════════════════════════════

# System status checker
check_status() {
    echo "════════════════════════════════════════════════════════════════"
    echo "📊 SYSTEM STATUS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    # Git repository info
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "📁 Repository: $(basename "$(git rev-parse --show-toplevel)")"
        echo "🌿 Branch: $(git branch --show-current)"
        echo "📝 Status: $(git status --short | wc -l | tr -d ' ') files modified"
    else
        echo "📁 Not a git repository"
    fi

    echo ""

    # Memory usage
    echo "💾 Memory: $(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " / " $2}' || echo 'N/A')"

    # CPU load
    echo "⚡ CPU Load: $(uptime | awk -F'load average:' '{print $2}' || echo 'N/A')"

    echo ""
    echo "════════════════════════════════════════════════════════════════"
}

# Check API keys
check_secrets() {
    echo "════════════════════════════════════════════════════════════════"
    echo "🔑 SECRETS CHECK"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "✅ ANTHROPIC_API_KEY: Set (${#ANTHROPIC_API_KEY} chars)"
    else
        echo "❌ ANTHROPIC_API_KEY: Not set"
    fi

    if [ -n "$GITHUB_TOKEN" ]; then
        echo "✅ GITHUB_TOKEN: Set (${#GITHUB_TOKEN} chars)"
    elif [ -n "$GITHUB_ACCESS_TOKEN" ]; then
        echo "✅ GITHUB_ACCESS_TOKEN: Set (${#GITHUB_ACCESS_TOKEN} chars)"
    else
        echo "❌ GITHUB_TOKEN: Not set"
    fi

    echo ""
    echo "════════════════════════════════════════════════════════════════"
}

# Check tool versions
check_versions() {
    echo "════════════════════════════════════════════════════════════════"
    echo "🔧 INSTALLED VERSIONS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    echo "Claude Code:"
    claude --version 2>&1 | head -1 || echo "  Not installed"
    echo ""

    echo "SuperClaude:"
    python3 -m SuperClaude --version 2>&1 | head -1 || echo "  Not installed"
    echo ""

    echo "Claude Flow:"
    claude-flow --version 2>&1 | head -1 || echo "  Not installed"
    echo ""

    echo "Node.js:"
    node --version 2>&1 || echo "  Not installed"
    echo ""

    echo "Python:"
    python3 --version 2>&1 || echo "  Not installed"
    echo ""

    echo "════════════════════════════════════════════════════════════════"
}

# Check Claude sessions
check_sessions() {
    echo "════════════════════════════════════════════════════════════════"
    echo "📁 CLAUDE CODE SESSIONS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    if [ -d "$CLAUDE_CODE_SESSION_DIR" ]; then
        SESSION_COUNT=$(find "$CLAUDE_CODE_SESSION_DIR" -type f -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
        echo "Sessions directory: $CLAUDE_CODE_SESSION_DIR"
        echo "Active sessions: $SESSION_COUNT"
        echo ""

        if [ "$SESSION_COUNT" -gt 0 ]; then
            echo "Recent sessions:"
            find "$CLAUDE_CODE_SESSION_DIR" -type f -name "*.json" -exec ls -lh {} \; | head -5
        fi
    else
        echo "❌ Sessions directory not found"
    fi

    echo ""
    echo "════════════════════════════════════════════════════════════════"
}

# Rename codespace to match repository
rename-codespace() {
    if [ -n "$CODESPACES" ] && [ -n "$GITHUB_REPOSITORY" ] && [ -n "$CODESPACE_NAME" ]; then
        REPO_NAME=$(basename "$GITHUB_REPOSITORY" 2>/dev/null)

        if [ -n "$REPO_NAME" ]; then
            echo "Renaming codespace to: $REPO_NAME"
            gh codespace edit --codespace "$CODESPACE_NAME" --display-name "$REPO_NAME"
        else
            echo "❌ Could not determine repository name"
        fi
    else
        echo "❌ Not running in GitHub Codespaces"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# CODESPACE WELCOME MESSAGE
# ═══════════════════════════════════════════════════════════════════

# Show welcome message on first shell (only once)
if [ -z "$CODESPACE_WELCOME_SHOWN" ]; then
    export CODESPACE_WELCOME_SHOWN=1

    if [ -n "$CODESPACES" ]; then
        echo ""
        echo "🚀 Codespace Ready!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if git rev-parse --git-dir > /dev/null 2>&1; then
            REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
            echo "📁 Repository: $REPO_NAME"
        fi

        echo "✅ Claude Code ready (type 'dsp' or 'claude' to start)"
        echo "✅ MCP servers configured (Claude Flow + 4 essential)"
        echo ""
        echo "💡 Helpful commands:"
        echo "   • dsp / claude      - Start Claude Code (skip permissions)"
        echo "   • check_secrets     - Verify API keys are loaded"
        echo "   • check_versions    - Show installed versions"
        echo "   • check_sessions    - View Claude sessions"
        echo "   • rename-codespace  - Rename to match repository"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
fi

# ═══════════════════════════════════════════════════════════════════
# STANDARD BASHRC (Load system defaults)
# ═══════════════════════════════════════════════════════════════════

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Load system bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# Enable bash completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Make less more friendly
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
