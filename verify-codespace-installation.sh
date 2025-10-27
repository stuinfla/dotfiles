#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# CODESPACE INSTALLATION VERIFICATION SCRIPT
# ═══════════════════════════════════════════════════════════════════
#
# PURPOSE: Comprehensive verification of dotfiles installation in GitHub Codespaces
# USAGE: bash verify-codespace-installation.sh
# LOCATION: Can be run in any fresh codespace after dotfiles installation
#
# This script checks:
# - Machine specifications (16 cores, 64GB RAM)
# - Claude Code installation and version
# - Claude Flow v2.7.0-alpha.10 availability
# - All aliases (dsp, DSP, dsb, DSB)
# - MCP server installation
# - Secrets security (no exposed secrets)
# - Installation log completion
# ═══════════════════════════════════════════════════════════════════

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Success/failure counters
PASSED=0
FAILED=0
WARNINGS=0

# Print section header
print_header() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  $1"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Print check result
check_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"

    if [ "$result" == "PASS" ]; then
        echo -e "   ${GREEN}✅ PASS${NC}: $test_name"
        [ -n "$details" ] && echo "      $details"
        ((PASSED++))
    elif [ "$result" == "FAIL" ]; then
        echo -e "   ${RED}❌ FAIL${NC}: $test_name"
        [ -n "$details" ] && echo "      $details"
        ((FAILED++))
    elif [ "$result" == "WARN" ]; then
        echo -e "   ${YELLOW}⚠️  WARN${NC}: $test_name"
        [ -n "$details" ] && echo "      $details"
        ((WARNINGS++))
    else
        echo -e "   ${BLUE}ℹ️  INFO${NC}: $test_name"
        [ -n "$details" ] && echo "      $details"
    fi
}

# Start verification
print_header "CODESPACE COMPREHENSIVE VERIFICATION REPORT"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "User: $USER"
echo ""

# ═══════════════════════════════════════════════════════════════════
# 1. MACHINE SPECIFICATIONS
# ═══════════════════════════════════════════════════════════════════
print_header "📋 1. MACHINE SPECIFICATIONS"

# Check CPU cores
CORES=$(nproc)
if [ "$CORES" -eq 16 ]; then
    check_result "CPU Cores" "PASS" "$CORES cores detected"
elif [ "$CORES" -ge 8 ]; then
    check_result "CPU Cores" "WARN" "$CORES cores (expected 16, but 8+ is acceptable)"
else
    check_result "CPU Cores" "FAIL" "$CORES cores (expected 16)"
fi

# Check memory
MEMORY_GB=$(free -h | grep Mem | awk '{print $2}')
MEMORY_NUM=$(free -g | grep Mem | awk '{print $2}')
if [ "$MEMORY_NUM" -ge 60 ]; then
    check_result "Memory (RAM)" "PASS" "$MEMORY_GB available"
elif [ "$MEMORY_NUM" -ge 30 ]; then
    check_result "Memory (RAM)" "WARN" "$MEMORY_GB available (expected ~64GB)"
else
    check_result "Memory (RAM)" "FAIL" "$MEMORY_GB available (expected ~64GB)"
fi

# Check disk space
DISK_SIZE=$(df -h /workspaces | tail -1 | awk '{print $2}')
DISK_AVAIL=$(df -h /workspaces | tail -1 | awk '{print $4}')
check_result "Disk Space" "INFO" "Total: $DISK_SIZE, Available: $DISK_AVAIL"

# ═══════════════════════════════════════════════════════════════════
# 2. CLAUDE CODE INSTALLATION
# ═══════════════════════════════════════════════════════════════════
print_header "📋 2. CLAUDE CODE INSTALLATION"

# Check if claude command exists
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -1)
    check_result "Claude Code Command" "PASS" "Version: $CLAUDE_VERSION"
else
    check_result "Claude Code Command" "FAIL" "claude command not found in PATH"
fi

# Check if dsp alias works (common alias from dotfiles)
if type dsp &> /dev/null 2>&1; then
    check_result "Claude Code Alias (dsp)" "PASS" "dsp alias is configured"
else
    check_result "Claude Code Alias (dsp)" "WARN" "dsp alias not found (may not be in dotfiles)"
fi

# Check Claude Code npm installation
if npm list -g 2>/dev/null | grep -q claude-code; then
    CLAUDE_NPM_VERSION=$(npm list -g claude-code 2>/dev/null | grep claude-code | awk '{print $2}')
    check_result "Claude Code NPM Package" "PASS" "Version: $CLAUDE_NPM_VERSION"
else
    check_result "Claude Code NPM Package" "WARN" "Not found in npm global packages (may use different install method)"
fi

# ═══════════════════════════════════════════════════════════════════
# 3. CLAUDE FLOW INSTALLATION
# ═══════════════════════════════════════════════════════════════════
print_header "📋 3. CLAUDE FLOW v2.7.0-alpha.10"

# Check Claude Flow via npx
FLOW_CHECK=$(npx --yes claude-flow@alpha --version 2>&1 | head -1)
if echo "$FLOW_CHECK" | grep -q "v2\.7\.0"; then
    check_result "Claude Flow Version" "PASS" "$FLOW_CHECK"
elif echo "$FLOW_CHECK" | grep -qE "v[0-9]+\.[0-9]+\.[0-9]+"; then
    check_result "Claude Flow Version" "WARN" "$FLOW_CHECK (expected v2.7.0-alpha.10)"
else
    check_result "Claude Flow Version" "FAIL" "Could not determine version: $FLOW_CHECK"
fi

# Check if .claude directory exists (indicates initialization)
if [ -d "/workspaces/.claude" ] || [ -d "$HOME/.claude" ]; then
    check_result "Claude Flow Directory" "PASS" ".claude directory exists"
else
    check_result "Claude Flow Directory" "WARN" ".claude directory not found (may need initialization)"
fi

# ═══════════════════════════════════════════════════════════════════
# 4. ALIASES VERIFICATION
# ═══════════════════════════════════════════════════════════════════
print_header "📋 4. ALIASES VERIFICATION"

# Check each expected alias
for alias_name in dsp DSP dsb DSB; do
    if type "$alias_name" &> /dev/null 2>&1; then
        ALIAS_DEF=$(type "$alias_name" 2>&1 | grep "is aliased" || echo "is defined")
        check_result "Alias: $alias_name" "PASS" "$ALIAS_DEF"
    else
        check_result "Alias: $alias_name" "FAIL" "Not defined"
    fi
done

# ═══════════════════════════════════════════════════════════════════
# 5. MCP SERVERS INSTALLATION
# ═══════════════════════════════════════════════════════════════════
print_header "📋 5. ESSENTIAL MCP SERVERS"

# Check for essential MCP servers in global npm packages
MCP_SERVERS=("@modelcontextprotocol/server-github" "@modelcontextprotocol/server-filesystem" "mcp-server-playwright" "mcp-server-sequential-thinking")
MCP_COUNT=0

for server in "${MCP_SERVERS[@]}"; do
    if npm list -g 2>/dev/null | grep -q "$server"; then
        check_result "MCP Server: $server" "PASS" "Installed"
        ((MCP_COUNT++))
    else
        check_result "MCP Server: $server" "WARN" "Not found (may use different package name)"
    fi
done

# Summary
if [ "$MCP_COUNT" -ge 3 ]; then
    check_result "MCP Servers Summary" "PASS" "$MCP_COUNT/4 essential servers found"
elif [ "$MCP_COUNT" -ge 1 ]; then
    check_result "MCP Servers Summary" "WARN" "$MCP_COUNT/4 essential servers found"
else
    check_result "MCP Servers Summary" "FAIL" "No MCP servers found"
fi

# ═══════════════════════════════════════════════════════════════════
# 6. SECRETS SECURITY CHECK
# ═══════════════════════════════════════════════════════════════════
print_header "📋 6. SECRETS SECURITY"

# Check if check_secrets function exists
if type check_secrets &> /dev/null 2>&1; then
    SECRETS_CHECK=$(check_secrets 2>&1 | head -5)
    if echo "$SECRETS_CHECK" | grep -q "No secrets exposed"; then
        check_result "Secrets Exposure Check" "PASS" "No secrets exposed in bashrc"
    else
        check_result "Secrets Exposure Check" "WARN" "check_secrets output requires review"
        echo "$SECRETS_CHECK"
    fi
else
    # Manual check for common secret patterns
    SECRET_PATTERNS=("ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GITHUB_TOKEN" "AWS_SECRET")
    FOUND_SECRETS=0

    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -q "$pattern" ~/.bashrc 2>/dev/null; then
            check_result "Secret Pattern: $pattern" "FAIL" "Found in .bashrc"
            ((FOUND_SECRETS++))
        fi
    done

    if [ "$FOUND_SECRETS" -eq 0 ]; then
        check_result "Manual Secrets Check" "PASS" "No common secret patterns found in .bashrc"
    else
        check_result "Manual Secrets Check" "FAIL" "$FOUND_SECRETS potential secret patterns found"
    fi
fi

# ═══════════════════════════════════════════════════════════════════
# 7. VERSION CHECK FUNCTION
# ═══════════════════════════════════════════════════════════════════
print_header "📋 7. VERSION CHECK FUNCTION"

if type check_versions &> /dev/null 2>&1; then
    check_result "check_versions Function" "PASS" "Function is available"
    echo ""
    echo "   Output of check_versions:"
    echo "   ─────────────────────────────────────"
    check_versions 2>&1 | head -20 | sed 's/^/   /'
else
    check_result "check_versions Function" "WARN" "Function not available (not in dotfiles)"
fi

# ═══════════════════════════════════════════════════════════════════
# 8. INSTALLATION LOG CHECK
# ═══════════════════════════════════════════════════════════════════
print_header "📋 8. INSTALLATION LOG"

CREATION_LOG="/workspaces/.codespaces/.persistedshare/creation.log"

if [ -f "$CREATION_LOG" ]; then
    check_result "Creation Log Exists" "PASS" "Log file found at $CREATION_LOG"

    # Check for successful installation indicators
    if grep -q "INSTALLATION SUCCESSFUL" "$CREATION_LOG" 2>/dev/null; then
        check_result "Installation Success Marker" "PASS" "Found 'INSTALLATION SUCCESSFUL' in log"
    else
        check_result "Installation Success Marker" "WARN" "Success marker not found (check log manually)"
    fi

    # Check for errors
    ERROR_COUNT=$(grep -c "ERROR\|FAILED\|Exception" "$CREATION_LOG" 2>/dev/null || echo 0)
    if [ "$ERROR_COUNT" -eq 0 ]; then
        check_result "Installation Errors" "PASS" "No errors found in creation log"
    else
        check_result "Installation Errors" "WARN" "$ERROR_COUNT error(s) found in creation log"
    fi

    # Show last 10 lines of log
    echo ""
    echo "   Last 10 lines of creation log:"
    echo "   ─────────────────────────────────────"
    tail -10 "$CREATION_LOG" 2>/dev/null | sed 's/^/   /'
else
    check_result "Creation Log" "WARN" "Log file not found at $CREATION_LOG"
fi

# ═══════════════════════════════════════════════════════════════════
# 9. VS CODE EXTENSIONS (if running in Codespace)
# ═══════════════════════════════════════════════════════════════════
print_header "📋 9. VS CODE CONFIGURATION"

# Check if running in Codespace
if [ -n "$CODESPACES" ]; then
    check_result "GitHub Codespace Detected" "INFO" "Running in GitHub Codespaces"

    # Check if devcontainer.json exists
    if [ -f "/workspaces/$(basename $(pwd))/.devcontainer/devcontainer.json" ] || [ -f ".devcontainer/devcontainer.json" ]; then
        check_result "DevContainer Configuration" "PASS" "devcontainer.json found"
    else
        check_result "DevContainer Configuration" "WARN" "devcontainer.json not found in repository"
    fi
else
    check_result "Environment" "INFO" "Not running in GitHub Codespaces (local environment)"
fi

# ═══════════════════════════════════════════════════════════════════
# 10. BASHRC CONFIGURATION
# ═══════════════════════════════════════════════════════════════════
print_header "📋 10. BASHRC CONFIGURATION"

if [ -f "$HOME/.bashrc" ]; then
    BASHRC_SIZE=$(wc -l < "$HOME/.bashrc")
    check_result ".bashrc Exists" "PASS" "$BASHRC_SIZE lines"

    # Check for dotfiles marker
    if grep -q "dotfiles" "$HOME/.bashrc" 2>/dev/null; then
        check_result "Dotfiles Integration" "PASS" "Dotfiles marker found in .bashrc"
    else
        check_result "Dotfiles Integration" "WARN" "No dotfiles marker found"
    fi
else
    check_result ".bashrc Exists" "FAIL" ".bashrc not found"
fi

# ═══════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════
print_header "VERIFICATION SUMMARY"

TOTAL=$((PASSED + FAILED + WARNINGS))
PASS_RATE=$((PASSED * 100 / TOTAL))

echo "   Total Checks: $TOTAL"
echo -e "   ${GREEN}✅ Passed: $PASSED${NC}"
echo -e "   ${RED}❌ Failed: $FAILED${NC}"
echo -e "   ${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo ""
echo "   Success Rate: $PASS_RATE%"
echo ""

# Overall result
if [ "$FAILED" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ VERIFICATION COMPLETE - ALL CHECKS PASSED                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    exit 0
elif [ "$FAILED" -eq 0 ]; then
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   ⚠️  VERIFICATION COMPLETE - WARNINGS PRESENT                ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ VERIFICATION FAILED - ISSUES DETECTED                    ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Please review the failed checks above and:"
    echo "1. Check the creation log: tail -100 /workspaces/.codespaces/.persistedshare/creation.log"
    echo "2. Verify dotfiles repository configuration in GitHub Settings"
    echo "3. Re-run dotfiles installation: bash \$DOTFILES/install.sh"
    echo "4. Create a new codespace if issues persist"
    exit 1
fi
