#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# CODESPACES HEALTH CHECK SCRIPT
# Created: 2025-10-16
# Purpose: Verify all tools, configurations, and services are working
# ═══════════════════════════════════════════════════════════════════

set -u  # Error on undefined variables

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Helper functions
success() {
    echo -e "${GREEN}✅ $*${NC}"
    ((PASS_COUNT++))
}

error() {
    echo -e "${RED}❌ $*${NC}"
    ((FAIL_COUNT++))
}

warn() {
    echo -e "${YELLOW}⚠️  $*${NC}"
    ((WARN_COUNT++))
}

info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

header() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "$1"
    echo "═══════════════════════════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════════════════════
# START HEALTH CHECK
# ═══════════════════════════════════════════════════════════════════

clear
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         GITHUB CODESPACES HEALTH CHECK                        ║"
echo "║         $(date +'%Y-%m-%d %H:%M:%S')                                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"

# ═══════════════════════════════════════════════════════════════════
# 1. ENVIRONMENT CHECK
# ═══════════════════════════════════════════════════════════════════

header "1. ENVIRONMENT"

if [ -n "${CODESPACES:-}" ]; then
    success "Running in GitHub Codespaces"
    info "   Codespace: ${CODESPACE_NAME:-unknown}"
    info "   Repository: ${GITHUB_REPOSITORY:-unknown}"
else
    warn "Not running in Codespaces (local environment)"
fi

if [ -n "${GITHUB_TOKEN:-}" ]; then
    success "GitHub token available"
else
    warn "GitHub token not set"
fi

# ═══════════════════════════════════════════════════════════════════
# 2. CORE TOOLS
# ═══════════════════════════════════════════════════════════════════

header "2. CORE TOOLS"

# Claude Code
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -1 || echo "unknown")
    success "Claude Code: $CLAUDE_VERSION"

    # Note: Session directory feature removed in Claude Code 2.0.27+
else
    error "Claude Code: NOT INSTALLED"
fi

# SuperClaude
if python3 -m SuperClaude --version &> /dev/null 2>&1; then
    SUPERCLAUDE_VERSION=$(python3 -m SuperClaude --version 2>&1 | head -1 || echo "unknown")
    success "SuperClaude: $SUPERCLAUDE_VERSION"
else
    warn "SuperClaude: Not installed (optional)"
fi

# Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    success "Node.js: $NODE_VERSION"
else
    error "Node.js: NOT INSTALLED"
fi

# Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    success "Python: $PYTHON_VERSION"
else
    error "Python: NOT INSTALLED"
fi

# GitHub CLI
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -1)
    success "GitHub CLI: $GH_VERSION"
else
    error "GitHub CLI: NOT INSTALLED"
fi

# ═══════════════════════════════════════════════════════════════════
# 3. CONFIGURATION FILES
# ═══════════════════════════════════════════════════════════════════

header "3. CONFIGURATION FILES"

# .bashrc
if [ -f "$HOME/.bashrc" ]; then
    success ".bashrc: Present"
    if grep -q "alias dsp" "$HOME/.bashrc" 2>/dev/null; then
        success "   DSP alias configured"
    else
        warn "   DSP alias NOT configured"
    fi
else
    error ".bashrc: MISSING"
fi

# .claude.json
if [ -f "$HOME/.claude.json" ]; then
    success ".claude.json: Present"

    # Check permissions (should be 600 for security)
    PERMS=$(stat -f "%OLp" "$HOME/.claude.json" 2>/dev/null || stat -c "%a" "$HOME/.claude.json" 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        success "   Permissions: $PERMS (secure)"
    else
        warn "   Permissions: $PERMS (should be 600)"
    fi

    # Count MCP servers
    MCP_COUNT=$(grep -c '"command"' "$HOME/.claude.json" 2>/dev/null || echo "0")
    info "   MCP servers configured: $MCP_COUNT"
else
    error ".claude.json: MISSING"
fi

# .devcontainer
if [ -d "$HOME/.dotfiles/.devcontainer" ]; then
    success ".devcontainer: Present"
else
    warn ".devcontainer: Not found (optional)"
fi

# ═══════════════════════════════════════════════════════════════════
# 4. MCP SERVERS
# ═══════════════════════════════════════════════════════════════════

header "4. MCP SERVERS"

declare -a NPM_MCPS=(
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-filesystem"
    "@playwright/mcp"
    "@modelcontextprotocol/server-sequential-thinking"
)

MCP_PASS=0
MCP_FAIL=0

for mcp in "${NPM_MCPS[@]}"; do
    if npm list -g "$mcp" &> /dev/null; then
        success "$(basename $mcp)"
        ((MCP_PASS++))
    else
        error "$(basename $mcp)"
        ((MCP_FAIL++))
    fi
done

info "Essential MCP Summary: $MCP_PASS installed, $MCP_FAIL missing"
info "Note: Additional MCPs available via Claude Flow @alpha"

# ═══════════════════════════════════════════════════════════════════
# 5. API KEYS / SECRETS
# ═══════════════════════════════════════════════════════════════════

header "5. API KEYS & SECRETS"

declare -a CRITICAL_SECRETS=(
    "ANTHROPIC_API_KEY:Claude API"
    "CLAUDE_API_KEY:Claude API (alt)"
)

declare -a OPTIONAL_SECRETS=(
    "BRAVE_API_KEY:Brave Search"
    "GITHUB_ACCESS_TOKEN:GitHub MCP"
    "HUGGINGFACE_API_KEY:Hugging Face"
    "GOOGLE_GEMINI_API_KEY:Google Gemini"
    "OPENAI_API_KEY:OpenAI"
    "GROQ_API_KEY:Groq"
    "GROK_AI_KEY:Grok AI"
)

# Check critical secrets
for item in "${CRITICAL_SECRETS[@]}"; do
    VAR="${item%%:*}"
    NAME="${item##*:}"
    if [ -n "${!VAR:-}" ]; then
        success "$NAME ($VAR): SET"
    else
        error "$NAME ($VAR): NOT SET"
    fi
done

# Check optional secrets
OPTIONAL_SET=0
OPTIONAL_MISSING=0

for item in "${OPTIONAL_SECRETS[@]}"; do
    VAR="${item%%:*}"
    NAME="${item##*:}"
    if [ -n "${!VAR:-}" ]; then
        ((OPTIONAL_SET++))
    else
        ((OPTIONAL_MISSING++))
    fi
done

info "Optional secrets: $OPTIONAL_SET set, $OPTIONAL_MISSING not set"

# ═══════════════════════════════════════════════════════════════════
# 6. MACHINE SPECS
# ═══════════════════════════════════════════════════════════════════

header "6. MACHINE SPECIFICATIONS"

# CPU
if command -v nproc &> /dev/null; then
    CPU_CORES=$(nproc)
    if [ "$CPU_CORES" -ge 16 ]; then
        success "CPU Cores: $CPU_CORES (16-core premium machine)"
    elif [ "$CPU_CORES" -ge 8 ]; then
        success "CPU Cores: $CPU_CORES (8-core machine)"
    elif [ "$CPU_CORES" -ge 4 ]; then
        success "CPU Cores: $CPU_CORES (4-core machine)"
    else
        warn "CPU Cores: $CPU_CORES (2-core machine - upgrade recommended)"
    fi
else
    info "CPU info not available"
fi

# Memory
if command -v free &> /dev/null; then
    MEM_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$MEM_GB" -ge 60 ]; then
        success "Memory: ${MEM_GB}GB (64GB premium machine)"
    elif [ "$MEM_GB" -ge 28 ]; then
        success "Memory: ${MEM_GB}GB (32GB machine)"
    elif [ "$MEM_GB" -ge 14 ]; then
        success "Memory: ${MEM_GB}GB (16GB machine)"
    else
        warn "Memory: ${MEM_GB}GB (smaller machine)"
    fi
else
    info "Memory info not available"
fi

# Disk space
if command -v df &> /dev/null; then
    DISK_AVAIL=$(df -h /workspaces 2>/dev/null | awk 'NR==2{print $4}' || echo "unknown")
    info "Disk available: $DISK_AVAIL"
fi

# ═══════════════════════════════════════════════════════════════════
# 7. NETWORK CONNECTIVITY
# ═══════════════════════════════════════════════════════════════════

header "7. NETWORK CONNECTIVITY"

# Test npm registry
if timeout 5 npm ping &> /dev/null; then
    success "npm registry: Reachable"
else
    warn "npm registry: Unreachable or slow"
fi

# Test PyPI
if timeout 5 pip search --no-cache-dir pip &> /dev/null 2>&1 || timeout 5 python3 -c "import urllib.request; urllib.request.urlopen('https://pypi.org', timeout=5)" &> /dev/null; then
    success "PyPI: Reachable"
else
    warn "PyPI: Unreachable or slow"
fi

# Test GitHub
if timeout 5 gh api /zen &> /dev/null; then
    success "GitHub API: Reachable"
else
    warn "GitHub API: Unreachable or authentication issue"
fi

# ═══════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════

header "HEALTH CHECK SUMMARY"

echo ""
echo "   ✅ Passed:   $PASS_COUNT checks"
echo "   ⚠️  Warnings: $WARN_COUNT checks"
echo "   ❌ Failed:   $FAIL_COUNT checks"
echo ""

# Overall status
if [ $FAIL_COUNT -eq 0 ] && [ $WARN_COUNT -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  🎉 PERFECT! Your Codespace is fully configured and ready!  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    exit 0
elif [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ✅ GOOD! Minor warnings but core functionality is ready     ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
    exit 0
elif [ $FAIL_COUNT -le 3 ]; then
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  PARTIAL: Some components missing. Review failures above  ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
    exit 1
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ CRITICAL: Multiple components failed. Reinstall needed    ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Try running: bash ~/.dotfiles/install.sh"
    exit 1
fi
