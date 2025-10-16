#!/bin/bash

echo "🚀 Setting up your Codespace environment..."
echo "============================================"
echo ""

# Copy .claude.json to home directory FIRST
if [ -f "$(dirname "$0")/.claude.json" ]; then
    cp "$(dirname "$0")/.claude.json" ~/.claude.json
    echo "✅ Copied .claude.json to home directory"
else
    echo "⚠️  .claude.json not found in dotfiles"
fi
echo ""

# Install Claude Code globally (ALWAYS get latest version)
echo "📦 Installing Claude Code (latest version)..."
npm install -g @anthropic-ai/claude-code@latest --force 2>&1 | grep -v "npm WARN"

# Check version and confirm
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -1 || echo "unknown")
    echo "   ✅ Claude Code installed successfully!"
    echo "   📌 Installed Version: $CLAUDE_VERSION"
else
    echo "   ❌ Claude Code installation failed"
fi
echo ""

# Install SuperClaude (ALWAYS get latest version)
echo "🎯 Installing SuperClaude (latest version)..."
if command -v pipx &> /dev/null; then
    pipx install SuperClaude --force 2>&1 | tail -1
    pipx upgrade SuperClaude 2>&1 | tail -1
else
    pip install --break-system-packages --user --upgrade --force-reinstall SuperClaude 2>&1 | grep -v "Requirement already satisfied"
fi

# Check SuperClaude version
if command -v SuperClaude &> /dev/null || python3 -m SuperClaude --version &> /dev/null 2>&1; then
    SUPERCLAUDE_VERSION=$(python3 -m SuperClaude --version 2>&1 | head -1 || echo "installed")
    echo "   ✅ SuperClaude installed successfully!"
    echo "   📌 Installed Version: $SUPERCLAUDE_VERSION"
else
    echo "   ⚠️  SuperClaude installation had issues (not critical)"
fi
echo ""

# Install essential MCP servers (ALWAYS get latest versions)
echo "🔌 Installing MCP Servers (all latest versions)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. MCP Installer
echo ""
echo "1️⃣  Installing mcp-installer..."
npm install -g mcp-installer@latest --force 2>&1 | grep -v "npm WARN" | tail -2
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
npm install -g @modelcontextprotocol/server-brave-search@latest --force 2>&1 | grep -v "npm WARN" | tail -2
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
pip install --break-system-packages --user --upgrade --force-reinstall mcp-server-fetch 2>&1 | grep -E "(Successfully|already)" | head -1
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
npm install -g @modelcontextprotocol/server-github@latest --force 2>&1 | grep -v "npm WARN" | tail -2
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
npm install -g @modelcontextprotocol/server-filesystem@latest --force 2>&1 | grep -v "npm WARN" | tail -2
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
npm install -g @playwright/mcp@latest --force 2>&1 | grep -v "npm WARN" | tail -2
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
npm install -g @modelcontextprotocol/server-sequential-thinking@latest --force 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g @modelcontextprotocol/server-sequential-thinking &> /dev/null; then
    SEQ_VERSION=$(npm list -g @modelcontextprotocol/server-sequential-thinking 2>&1 | grep sequential-thinking | awk '{print $2}')
    echo "    ✅ sequential-thinking installed"
    echo "    📌 Version: $SEQ_VERSION"
    echo "    💡 Use: Break down complex problems step-by-step"
else
    echo "    ❌ Failed"
fi

# 8. Google Drive
echo ""
echo "8️⃣  Installing google-drive..."
npm install -g @modelcontextprotocol/server-gdrive@latest --force 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g @modelcontextprotocol/server-gdrive &> /dev/null; then
    GDRIVE_VERSION=$(npm list -g @modelcontextprotocol/server-gdrive 2>&1 | grep server-gdrive | awk '{print $2}')
    echo "    ✅ google-drive installed"
    echo "    📌 Version: $GDRIVE_VERSION"
    echo "    💡 Use: Access Google Drive files and folders"
else
    echo "    ❌ Failed"
fi

# 9. Hugging Face
echo ""
echo "9️⃣  Installing huggingface..."
npm install -g @huggingface/mcp-server-huggingface@latest --force 2>&1 | grep -v "npm WARN" | tail -2
if npm list -g @huggingface/mcp-server-huggingface &> /dev/null; then
    HF_VERSION=$(npm list -g @huggingface/mcp-server-huggingface 2>&1 | grep mcp-server-huggingface | awk '{print $2}')
    echo "    ✅ huggingface installed"
    echo "    📌 Version: $HF_VERSION"
    echo "    💡 Use: Access Hugging Face models & datasets"
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

# Initialize counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

echo "═══════════════════════════════════════════"
echo "1. CLAUDE CODE STATUS"
echo "═══════════════════════════════════════════"
if command -v claude &> /dev/null; then
    INSTALLED_CLAUDE=$(claude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    echo "   Status: ✅ INSTALLED"
    echo "   Version: $INSTALLED_CLAUDE"
    echo "   ✅ READY TO USE"
    ((PASS_COUNT++))
else
    echo "   Status: ❌ NOT FOUND"
    ((FAIL_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "2. SUPERCLAUDE STATUS"
echo "═══════════════════════════════════════════"
if python3 -m SuperClaude --version &> /dev/null 2>&1; then
    INSTALLED_SC=$(python3 -m SuperClaude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    echo "   Status: ✅ INSTALLED"
    echo "   Version: $INSTALLED_SC"
    echo "   ✅ READY TO USE"
    ((PASS_COUNT++))
else
    echo "   Status: ⚠️  NOT INSTALLED (not critical)"
    ((WARN_COUNT++))
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
    "@modelcontextprotocol/server-gdrive"
    "@huggingface/mcp-server-huggingface"
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
    grep -B1 "\"command\"" "$HOME/.claude.json" 2>/dev/null | grep "\"" | sed 's/.*"\([^"]*\)".*/      • \1/' | grep -v "command" | grep -v "^--$" || echo "      (parsing issue)"
    if [ "$MCP_CONFIGURED" -ge 9 ]; then
        echo ""
        echo "   ✅ ALL EXPECTED SERVERS CONFIGURED"
        ((PASS_COUNT++))
    else
        echo ""
        echo "   ⚠️  FEWER SERVERS THAN EXPECTED (expected 9, found $MCP_CONFIGURED)"
        ((WARN_COUNT++))
    fi
else
    echo "   Status: ❌ NOT FOUND"
    echo "   ⚠️  .claude.json was not copied to home directory"
    ((FAIL_COUNT++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "5. AUTHENTICATION STATUS"
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
echo "6. ENVIRONMENT VARIABLES (API KEYS)"
echo "═══════════════════════════════════════════"

# Check for key environment variables from GitHub secrets
declare -a KEY_VARS=(
    "BRAVE_API_KEY:Brave Search"
    "ANTHROPIC_API_KEY:Claude API"
    "GITHUB_ACCESS_TOKEN:GitHub"
    "GOOGLE_GEMINI_API_KEY:Google Gemini"
    "HUGGINGFACE_API_KEY:Hugging Face"
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
        echo "   ⚠️  $NAME ($VAR) - Not set"
        ((ENV_FAIL++))
    fi
done

echo ""
if [ $ENV_PASS -gt 0 ]; then
    echo "   API Keys: $ENV_PASS found, $ENV_FAIL missing"
    ((PASS_COUNT++))
else
    echo "   ⚠️  No API keys found - add them to GitHub Codespace Secrets"
    ((WARN_COUNT++))
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
    echo "🎉 PERFECT! Everything is installed and ready!"
elif [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ GOOD! Core components installed. Review warnings above."
else
    echo "⚠️  ATTENTION: Some components failed to install."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 NEXT STEPS:"
echo "   • Type 'claude --version' to verify Claude Code"
echo "   • Type 'claude' to start (authenticate if needed)"
echo "   • All MCP servers will activate automatically"
echo ""
echo "💡 HELPFUL COMMANDS:"
echo "   • Check MCP config: cat ~/.claude.json"
echo "   • List installed packages: npm list -g --depth=0"
echo "   • Update everything: Re-run this script"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# AUTO-RENAME CODESPACE TO MATCH REPOSITORY
# ==============================================================================

if [ -n "$CODESPACES" ] && [ -n "$CODESPACE_NAME" ] && [ -n "$GITHUB_REPOSITORY" ]; then
    # Extract repository name (without owner)
    REPO_NAME=$(basename "$GITHUB_REPOSITORY" 2>/dev/null)

    if [ -n "$REPO_NAME" ]; then
        echo "🏷️  Auto-renaming Codespace..."
        echo "   Repository: $REPO_NAME"
        echo "   Codespace: $CODESPACE_NAME"

        # Try to rename the codespace
        if gh codespace edit --codespace "$CODESPACE_NAME" --display-name "$REPO_NAME" 2>/dev/null; then
            echo "   ✅ Codespace renamed to: $REPO_NAME"
            echo ""
        else
            echo "   ⚠️  Could not rename (you can rename manually with 'rename-codespace')"
            echo ""
        fi
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
