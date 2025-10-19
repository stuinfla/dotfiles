#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ADD DEVCONTAINER CONFIGURATION
# Adds .devcontainer/devcontainer.json to request larger machines
# ═══════════════════════════════════════════════════════════════════

set -e

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

echo "🔧 Adding Codespace machine size configuration..."
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️  Warning: Not in a git repository root${NC}"
    echo "   This script should be run from the root of your repository"
    read -p "   Continue anyway? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Create .devcontainer directory if it doesn't exist
mkdir -p .devcontainer

# Check if devcontainer.json already exists
if [ -f ".devcontainer/devcontainer.json" ]; then
    echo -e "${YELLOW}⚠️  .devcontainer/devcontainer.json already exists${NC}"
    read -p "   Overwrite? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Create devcontainer.json
cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "${localWorkspaceFolderBasename}",
  "image": "mcr.microsoft.com/devcontainers/universal:2",

  // Request 4-core machine (or 8-core if you have access)
  "hostRequirements": {
    "cpus": 4,
    "memory": "16gb",
    "storage": "32gb"
  },

  // Optional: Add VS Code extensions if desired
  "customizations": {
    "vscode": {
      "extensions": [
        "github.copilot",
        "github.copilot-chat"
      ]
    }
  },

  "remoteUser": "codespace"
}
EOF

echo -e "${GREEN}✅ Created .devcontainer/devcontainer.json${NC}"
echo ""
echo "Configuration:"
echo "  - Codespace name: Matches repository name"
echo "  - Machine size: 4-core, 16GB RAM, 32GB storage"
echo "  - Extensions: GitHub Copilot (optional)"
echo ""
echo "📝 Next steps:"
echo "  1. Review .devcontainer/devcontainer.json (edit if needed)"
echo "  2. Commit the file: git add .devcontainer && git commit -m 'Add devcontainer config'"
echo "  3. Push to GitHub: git push"
echo "  4. Create Codespace - it will use these settings!"
echo ""
echo "💡 Your dotfiles will still run automatically when the Codespace creates"
echo "   So you'll get Claude Code + larger machine automatically!"
echo ""
