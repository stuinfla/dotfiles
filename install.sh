#!/bin/bash

echo "🚀 Setting up your Codespace environment..."
echo "============================================"

# Install Claude Code globally (latest version)
echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

# Check if pipx is available for SuperClaude
if command -v pipx &> /dev/null; then
    echo "🎯 Installing SuperClaude 4.2 with pipx..."
    pipx install SuperClaude --force
    pipx upgrade SuperClaude
else
    echo "🎯 Installing SuperClaude 4.2 with pip..."
    pip install --break-system-packages --user SuperClaude --upgrade
fi

# Install essential MCP servers
echo "🔌 Installing MCP Servers..."

# 1. MCP Installer - Install others on demand
echo "  → mcp-installer (install others on demand)"
npm install -g mcp-installer

# 2. Brave Search - Web search
echo "  → brave-search"
npm install -g @modelcontextprotocol/server-brave-search

# 3. Fetch - Web scraping
echo "  → fetch"
pip install --break-system-packages --user mcp-server-fetch

# 4. GitHub - Already authenticated via gh
echo "  → github"
npm install -g @modelcontextprotocol/server-github

# 5. Filesystem - File operations
echo "  → filesystem"
npm install -g @modelcontextprotocol/server-filesystem

# 6. Playwright - Browser automation & testing
echo "  → playwright"
npm install -g @playwright/mcp

# 7. Sequential Thinking - Complex problem solving
echo "  → sequential-thinking"
npm install -g @modelcontextprotocol/server-sequential-thinking

echo ""
echo "✅ Setup complete!"
echo "💡 Type 'claude' to start Claude Code (includes --dangerously-skip-permissions)"
echo "🔌 All MCP servers are ready to use!"
