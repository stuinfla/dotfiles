#!/bin/bash

echo "🚀 Setting up your Codespace environment..."
echo "============================================"
echo ""

# Install Claude Code globally (latest version)
echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code 2>&1 | grep -v "npm WARN"

# Check version and confirm
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
    echo "   ✅ Claude Code installed successfully!"
    echo "   📌 Version: $CLAUDE_VERSION"
else
    echo "   ❌ Claude Code installation failed"
fi
echo ""

# Check if pipx is available for SuperClaude
echo "🎯 Installing SuperClaude 4.2..."
if command -v pipx &> /dev/null; then
    pipx install SuperClaude --force 2>&1 | tail -1
    pipx upgrade SuperClaude 2>&1 | tail -1
else
    pip install --break-system-packages --user SuperClaude --upgrade 2>&1 | grep -v "Requirement already satisfied"
fi

# Check SuperClaude version
if command -v SuperClaude &> /dev/null || python3 -m SuperClaude --version &> /dev/null; then
    SUPERCLAUDE_VERSION=$(python3 -m SuperClaude --version 2>&1 | head -1 || echo "installed")
    echo "   ✅ SuperClaude installed successfully!"
    echo "   📌 Version: $SUPERCLAUDE_VERSION"
else
    echo "   ❌ SuperClaude installation failed"
fi
echo ""

# Install essential MCP servers
echo "🔌 Installing MCP Servers..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. MCP Installer
echo ""
echo "1️⃣  Installing mcp-installer..."
npm install -g mcp-installer 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g mcp-installer &> /dev/null; then
    MCP_INSTALLER_VERSION=$(npm list -g mcp-installer 2>&1 | grep mcp-installer | awk '{print $2}')
    echo "    ✅ mcp-installer installed"
    echo "    📌 Version: $MCP_INSTALLER_VERSION"
    echo "    💡 Use: Ask Claude to 'install [server-name] MCP server'"
else
    echo "    ❌ Failed"
fi

# 2. Brave Search
echo ""
echo "2️⃣  Installing brave-search..."
npm install -g @modelcontextprotocol/server-brave-search 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g @modelcontextprotocol/server-brave-search &> /dev/null; then
    BRAVE_VERSION=$(npm list -g @modelcontextprotocol/server-brave-search 2>&1 | grep server-brave-search | awk '{print $2}')
    echo "    ✅ brave-search installed"
    echo "    📌 Version: $BRAVE_VERSION"
    echo "    💡 Use: Web search with your Brave API key"
else
    echo "    ❌ Failed"
fi

# 3. Fetch
echo ""
echo "3️⃣  Installing fetch..."
pip install --break-system-packages --user mcp-server-fetch 2>&1 | grep -E "(Successfully|already)" | head -1
if python3 -m pip show mcp-server-fetch &> /dev/null; then
    FETCH_VERSION=$(python3 -m pip show mcp-server-fetch 2>&1 | grep "Version:" | awk '{print $2}')
    echo "    ✅ fetch installed"
    echo "    📌 Version: $FETCH_VERSION"
    echo "    💡 Use: Web scraping and content retrieval"
else
    echo "    ❌ Failed"
fi

# 4. GitHub
echo ""
echo "4️⃣  Installing github..."
npm install -g @modelcontextprotocol/server-github 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g @modelcontextprotocol/server-github &> /dev/null; then
    GITHUB_VERSION=$(npm list -g @modelcontextprotocol/server-github 2>&1 | grep server-github | awk '{print $2}')
    echo "    ✅ github installed"
    echo "    📌 Version: $GITHUB_VERSION"
    echo "    💡 Use: Manage repos, issues, PRs (uses your gh auth)"
else
    echo "    ❌ Failed"
fi

# 5. Filesystem
echo ""
echo "5️⃣  Installing filesystem..."
npm install -g @modelcontextprotocol/server-filesystem 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g @modelcontextprotocol/server-filesystem &> /dev/null; then
    FS_VERSION=$(npm list -g @modelcontextprotocol/server-filesystem 2>&1 | grep server-filesystem | awk '{print $2}')
    echo "    ✅ filesystem installed"
    echo "    📌 Version: $FS_VERSION"
    echo "    💡 Use: Read, write, search files in /workspaces"
else
    echo "    ❌ Failed"
fi

# 6. Playwright
echo ""
echo "6️⃣  Installing playwright..."
npm install -g @playwright/mcp 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g @playwright/mcp &> /dev/null; then
    PLAYWRIGHT_VERSION=$(npm list -g @playwright/mcp 2>&1 | grep @playwright/mcp | awk '{print $2}')
    echo "    ✅ playwright installed"
    echo "    📌 Version: $PLAYWRIGHT_VERSION"
    echo "    💡 Use: Browser automation & testing"
else
    echo "    ❌ Failed"
fi

# 7. Sequential Thinking
echo ""
echo "7️⃣  Installing sequential-thinking..."
npm install -g @modelcontextprotocol/server-sequential-thinking 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g @modelcontextprotocol/server-sequential-thinking &> /dev/null; then
    SEQ_VERSION=$(npm list -g @modelcontextprotocol/server-sequential-thinking 2>&1 | grep sequential-thinking | awk '{print $2}')
    echo "    ✅ sequential-thinking installed"
    echo "    📌 Version: $SEQ_VERSION"
    echo "    💡 Use: Break down complex problems step-by-step"
else
    echo "    ❌ Failed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# COMPREHENSIVE VERIFICATION
# ==============================================================================

echo "🔍 RUNNING COMPREHENSIVE VERIFICATION..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for latest versions online
echo "📡 Checking for latest versions online..."
LATEST_CLAUDE=$(npm view @anthropic-ai/claude-code version 2>/dev/null || echo "unknown")
LATEST_SUPERCLAUDE=$(pip index versions SuperClaude 2>/dev/null | grep "LATEST:" | awk '{print $2}' || echo "unknown")

# Initialize counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

echo ""
echo "═══════════════════════════════════════════"
echo "1. CLAUDE CODE STATUS"
echo "═══════════════════════════════════════════"
if command -v claude &> /dev/null; then
    INSTALLED_CLAUDE=$(claude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    echo "   Status: ✅ INSTALLED"
    echo "   Installed: $INSTALLED_CLAUDE"
    echo "   Latest:    $LATEST_CLAUDE"
    if [ "$INSTALLED_CLAUDE" = "$LATEST_CLAUDE" ]; then
        echo "   ✅ UP TO DATE"
        ((PASS_COUNT++))
    else
        echo "   ⚠️  UPDATE AVAILABLE"
        ((WARN_COUNT++))
    fi
else
    echo "   Status: ❌ NOT FOUND"
    ((FAIL_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "2. SUPERCLAUDE STATUS"
echo "═══════════════════════════════════════════"
if python3 -m SuperClaude --version &> /dev/null; then
    INSTALLED_SC=$(python3 -m SuperClaude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    echo "   Status: ✅ INSTALLED"
    echo "   Installed: $INSTALLED_SC"
    echo "   Latest:    $LATEST_SUPERCLAUDE"
    if [ "$INSTALLED_SC" = "$LATEST_SUPERCLAUDE" ] || [ "$LATEST_SUPERCLAUDE" = "unknown" ]; then
        echo "   ✅ UP TO DATE"
        ((PASS_COUNT++))
    else
        echo "   ⚠️  UPDATE AVAILABLE"
        ((WARN_COUNT++))
    fi
else
    echo "   Status: ❌ NOT FOUND"
    ((FAIL_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "3. MCP SERVERS STATUS"
echo "═══════════════════════════════════════════"

# Check each MCP server
declare -a MCP_SERVERS=(
    "mcp-installer"
    "@modelcontextprotocol/server-brave-search"
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-filesystem"
    "@playwright/mcp"
    "@modelcontextprotocol/server-sequential-thinking"
)

MCP_PASS=0
MCP_FAIL=0

for server in "${MCP_SERVERS[@]}"; do
    if npm list -g "$server" &> /dev/null; then
        echo "   ✅ $server"
        ((MCP_PASS++))
    else
        echo "   ❌ $server"
        ((MCP_FAIL++))
    fi
done

# Check Python MCP server
if python3 -m pip show mcp-server-fetch &> /dev/null; then
    echo "   ✅ mcp-server-fetch (Python)"
    ((MCP_PASS++))
else
    echo "   ❌ mcp-server-fetch (Python)"
    ((MCP_FAIL++))
fi

echo ""
echo "   MCP Summary: $MCP_PASS installed, $MCP_FAIL failed"
if [ $MCP_FAIL -eq 0 ]; then
    ((PASS_COUNT++))
else
    ((FAIL_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "4. MCP CONFIGURATION FILE"
echo "═══════════════════════════════════════════"
if [ -f "$HOME/.claude.json" ]; then
    MCP_CONFIGURED=$(grep -c "\"command\"" "$HOME/.claude.json" 2>/dev/null || echo "0")
    echo "   Status: ✅ FOUND"
    echo "   Location: ~/.claude.json"
    echo "   Servers configured: $MCP_CONFIGURED"
    echo ""
    echo "   Configured servers:"
    grep -B1 "\"command\"" "$HOME/.claude.json" | grep "\"" | sed 's/.*"\([^"]*\)".*/      • \1/' | grep -v "command" | grep -v "^--$"
    if [ "$MCP_CONFIGURED" -ge 7 ]; then
        echo ""
        echo "   ✅ ALL EXPECTED SERVERS CONFIGURED"
        ((PASS_COUNT++))
    else
        echo ""
        echo "   ⚠️  FEWER SERVERS THAN EXPECTED (expected 7)"
        ((WARN_COUNT++))
    fi
else
    echo "   Status: ⚠️  NOT FOUND (will be created on first run)"
    ((WARN_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "5. VS CODE EXTENSIONS"
echo "═══════════════════════════════════════════"

# Check if code command exists
if command -v code &> /dev/null; then
    echo "   Checking installed extensions..."
    
    declare -a EXPECTED_EXTENSIONS=(
        "Kombai.kombai"
        "shd101wyy.markdown-preview-enhanced"
        "GrapeCity.gc-excelviewer"
        "cweijan.vscode-office"
        "tomoki1207.pdf"
        "PKief.material-icon-theme"
    )
    
    EXT_PASS=0
    EXT_FAIL=0
    
    for ext in "${EXPECTED_EXTENSIONS[@]}"; do
        if code --list-extensions 2>/dev/null | grep -q "$ext"; then
            echo "   ✅ $ext"
            ((EXT_PASS++))
        else
            echo "   ⏳ $ext (installing...)"
            ((EXT_FAIL++))
        fi
    done
    
    echo ""
    echo "   Extension Summary: $EXT_PASS verified, $EXT_FAIL pending"
    if [ $EXT_FAIL -eq 0 ]; then
        ((PASS_COUNT++))
    else
        echo "   ℹ️  Extensions install automatically on first Codespace start"
        ((WARN_COUNT++))
    fi
else
    echo "   ℹ️  VS Code not ready yet (extensions will install automatically)"
    ((WARN_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "6. AUTHENTICATION STATUS"
echo "═══════════════════════════════════════════"
if command -v claude &> /dev/null; then
    if claude auth status &> /dev/null 2>&1; then
        echo "   ✅ AUTHENTICATED"
        ((PASS_COUNT++))
    else
        echo "   ⚠️  NOT AUTHENTICATED YET"
        echo "   💡 Run 'claude' to authenticate (one-time setup)"
        ((WARN_COUNT++))
    fi
else
    echo "   ⚠️  Cannot check (Claude Code not available)"
    ((WARN_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "7. ENVIRONMENT VARIABLES (API KEYS)"
echo "═══════════════════════════════════════════"

# Check for key environment variables from GitHub secrets
declare -a KEY_VARS=(
    "BRAVE_API_KEY:Brave Search"
    "ANTHROPIC_API_KEY:Claude API"
    "GITHUB_ACCESS_TOKEN:GitHub"
    "GOOGLE_GEMINI_API_KEY:Google Gemini"
)

ENV_PASS=0
ENV_FAIL=0

for item in "${KEY_VARS[@]}"; do
    VAR="${item%%:*}"
    NAME="${item##*:}"
    if [ -n "${!VAR}" ]; then
        echo "   ✅ $NAME ($VAR)"
        ((ENV_PASS++))
    else
        echo "   ❌ $NAME ($VAR) - Not set"
        ((ENV_FAIL++))
    fi
done

echo ""
echo "   API Key Summary: $ENV_PASS found, $ENV_FAIL missing"
if [ $ENV_FAIL -eq 0 ]; then
    ((PASS_COUNT++))
else
    echo "   ⚠️  Some API keys missing - add them to GitHub Codespace Secrets"
    ((FAIL_COUNT++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 FINAL VERIFICATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   ✅ Passed:   $PASS_COUNT checks"
echo "   ⚠️  Warnings: $WARN_COUNT checks"
echo "   ❌ Failed:   $FAIL_COUNT checks"
echo ""

if [ $FAIL_COUNT -eq 0 ] && [ $WARN_COUNT -eq 0 ]; then
    echo "🎉 PERFECT! Everything is installed and up to date!"
elif [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ GOOD! Everything is installed. Some warnings to review."
else
    echo "⚠️  ATTENTION NEEDED: Some components failed to install."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 QUICK START:"
echo "   1. Type 'claude --version' to verify"
echo "   2. Type 'claude' to start (authenticate if needed)"
echo "   3. All MCP servers will activate automatically"
echo ""
echo "💡 HELPFUL COMMANDS:"
echo "   • Check MCP config: cat ~/.claude.json"
echo "   • List VS Code extensions: code --list-extensions"
echo "   • Update everything: Run this script again"
echo ""
