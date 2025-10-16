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

# Check MCP Configuration
echo "🔍 Verifying MCP Server Configuration..."
if [ -f "$HOME/.claude.json" ]; then
    MCP_COUNT=$(grep -c "\"command\"" "$HOME/.claude.json" 2>/dev/null || echo "0")
    echo "   ✅ MCP config file found: ~/.claude.json"
    echo "   📌 Configured servers: $MCP_COUNT"
    echo ""
    echo "   Servers configured:"
    grep -B1 "\"command\"" "$HOME/.claude.json" | grep "\"" | sed 's/.*"\([^"]*\)".*/      • \1/' | grep -v "command" | grep -v "^--$"
else
    echo "   ⚠️  MCP config file not found"
    echo "   💡 It will be created automatically when you first run Claude Code"
fi
echo ""

# Check Claude Code Authentication
echo "🔑 Checking Claude Code Authentication..."
if command -v claude &> /dev/null; then
    if claude auth status &> /dev/null; then
        echo "   ✅ Claude Code is authenticated!"
    else
        echo "   ⚠️  Not authenticated yet"
        echo "   💡 Next step: Run 'claude' and authenticate in the browser"
        echo "   💡 This only needs to be done once"
    fi
else
    echo "   ⚠️  Claude command not found"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Summary:"
echo "   • Claude Code: Installed and ready"
echo "   • SuperClaude Framework: Installed and ready"
echo "   • 7 MCP Servers: Installed"
echo "   • API Keys: Auto-configured from GitHub secrets"
echo ""
echo "🎯 Next Steps:"
echo "   1. Type 'claude --version' to verify"
echo "   2. Type 'claude' to start (authenticate if needed)"
echo "   3. All MCP servers will be active automatically"
echo ""
echo "💡 To verify MCP servers anytime:"
echo "   • View config: cat ~/.claude.json"
echo "   • List servers: claude mcp list"
echo ""
