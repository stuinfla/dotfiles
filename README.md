# AI Development Environment Dotfiles

Automated setup for GitHub Codespaces with Claude Code, SuperClaude, Claude Flow, and AI development tools.

## 🚀 Features

- **Claude Code** - Official Anthropic CLI with auto-permissions bypass
- **SuperClaude** - Enhanced framework with `/sc:` commands
- **Claude Flow @alpha** - Latest alpha release with automatic updates
- **9 MCP Servers** - Extended AI capabilities (web search, GitHub, browser automation, etc.)
- **Auto-Updates** - Daily background updates for all tools
- **Session Resume** - Context retention across sessions
- **4-Core Codespaces** - Optimized machine configuration
- **Auto-Rename** - Codespaces automatically named to match repository

## 📋 Prerequisites

Before using these dotfiles, you need:

1. **GitHub Account** (Free or Pro)
2. **Anthropic API Key** - Get from [Anthropic Console](https://console.anthropic.com)
3. **Optional API Keys** (for enhanced features):
   - Brave Search API Key
   - GitHub Personal Access Token
   - Hugging Face API Key

## 🔧 Setup Instructions

### Step 1: Configure Your API Keys (Required)

1. Go to [GitHub Codespaces Secrets](https://github.com/settings/codespaces)
2. Click **"New secret"**
3. Add your API keys:

| Secret Name | Required? | Purpose |
|-------------|-----------|---------|
| `ANTHROPIC_API_KEY` | ✅ **Required** | Claude Code functionality |
| `BRAVE_API_KEY` | Optional | Web search via MCP |
| `GITHUB_ACCESS_TOKEN` | Optional | GitHub integration via MCP |
| `HUGGINGFACE_API_KEY` | Optional | Hugging Face models via MCP |

**⚠️ IMPORTANT:** These secrets are stored in **YOUR** GitHub account and are **NEVER** shared with others. Each user must configure their own API keys.

### Step 2: Enable These Dotfiles in Your Account

1. Go to [GitHub Codespaces Settings](https://github.com/settings/codespaces)
2. Scroll to **"Dotfiles"** section
3. Check ✅ **"Automatically install dotfiles"**
4. Repository: `stuinfla/dotfiles`
5. Click **"Save"**

### Step 3: Create a Codespace

Create a codespace from **any repository**:
1. Click **Code** → **Codespaces** → **Create codespace on main**
2. Wait 2-5 minutes for automatic installation
3. Your codespace will be automatically configured!

## ✨ What Gets Installed

### Core AI Tools (Auto-Installed & Updated Daily)
1. **Claude Code** @latest - Anthropic's official CLI
2. **SuperClaude** (latest) - Enhanced command framework
3. **Claude Flow @alpha** (latest) - Advanced workflow automation
4. **9 MCP Servers** @latest - Extended capabilities

### MCP Servers Included
- `brave-search` - Web search (requires BRAVE_API_KEY)
- `fetch` - HTTP requests and web scraping
- `github` - GitHub integration (requires GITHUB_ACCESS_TOKEN)
- `filesystem` - File system access
- `playwright` - Browser automation and testing
- `sequential-thinking` - Multi-step reasoning
- `google-drive` - Google Drive integration
- `huggingface` - AI model access (requires HUGGINGFACE_API_KEY)
- `mcp-installer` - MCP management

### Development Environment
- **4-core machine** with 16GB RAM and 32GB storage
- **50+ VS Code extensions** (Python, Docker, Git, AI tools, etc.)
- **Node.js LTS** + **Python 3.11**
- **GitHub CLI** pre-configured

## 🎯 Usage

### Running Claude Code

Once your codespace is ready, you have **three ways** to run Claude:

```bash
# Method 1: Standard command
claude

# Method 2: Short alias (lowercase)
dsp

# Method 3: Short alias (uppercase)
DSP
```

**All three commands work identically** and include:
- ✅ Automatic permission bypass (`--dangerously-skip-permissions`)
- ✅ Session resume support (`--session-dir ~/.claude-sessions`)
- ✅ Your API key from GitHub secrets

### Continuing Previous Conversations

```bash
# Continue the most recent conversation
claude -c
# OR
dsp -c
# OR
DSP -c

# Resume a specific conversation
claude --resume
# OR
dsp --resume
# OR
DSP --resume
```

### Helpful Commands

```bash
# Check installed versions
check_versions

# Verify API keys are loaded
check_secrets

# View Claude sessions
check_sessions

# Rename codespace to match repository
rename-codespace
```

### Update Management

**Automatic Updates:**
- Run **once per day** (first terminal session of the day)
- Run in **background** (non-blocking)
- Update **all tools** to latest versions
- Logged to `~/.cache/claude_update.log`

**Manual Update:**
```bash
# Force immediate update
rm ~/.cache/claude_tools_updated
# Then open new terminal
```

## 🔒 Security & Privacy

### Your Secrets Are Safe

**✅ What's Public (This Repository):**
- Installation scripts
- Configuration files
- Shell aliases and functions
- MCP server configurations

**❌ What's Private (Your GitHub Account):**
- API keys and secrets
- Personal codespace environments
- Session data and chat history

### How Secrets Work

```
Your GitHub Account
    └─ Secrets (encrypted)
        └─ Injected into YOUR codespaces only
            └─ Never accessible to others

Other User's GitHub Account
    └─ Their own secrets (separate)
        └─ Injected into THEIR codespaces only
            └─ Never have access to YOUR secrets
```

**When someone uses your dotfiles:**
1. They get the **setup** (scripts, configs, automation)
2. They use **their own API keys** (from their GitHub account)
3. They **cannot access your secrets** (impossible by design)

## 📊 What Happens During Installation

### Timeline: New Codespace Creation

```
00:00 - Codespace created (4-core, 16GB RAM)
00:01 - GitHub installs: Node.js, Python, GitHub CLI
00:02 - GitHub installs: 50+ VS Code extensions
00:03 - install.sh runs:
        ├─ Copies .claude.json
        ├─ Installs Claude Code @latest
        ├─ Installs SuperClaude (latest)
        ├─ Installs Claude Flow @alpha
        └─ Installs 9 MCP servers (parallel)
00:05 - Installation complete
00:06 - Codespace ready to use!

First Terminal:
08:00 - .bashrc loads
08:01 - Auto-update runs (background)
08:01 - Welcome message displays
08:01 - YOU START WORKING ✅

Daily Updates:
- First terminal each day triggers update check
- All tools refreshed to latest versions
- Runs in background (non-blocking)
- Logged for review
```

## 🛠️ Customization

### Modify Machine Size

Edit `.devcontainer/devcontainer.json`:

```json
"hostRequirements": {
  "cpus": 8,        // Change from 4 to 8 (requires GitHub Pro)
  "memory": "32gb", // Change from 16GB to 32GB
  "storage": "64gb" // Change from 32GB to 64GB
}
```

**Note:** Larger machines may incur additional costs.

### Add Your Own Secrets

Add more secrets at [GitHub Settings](https://github.com/settings/codespaces):

```bash
# Then reference them in .bashrc or install.sh
export MY_CUSTOM_SECRET="${MY_CUSTOM_SECRET}"
```

### Add More MCP Servers

Edit `.claude.json` and `install.sh`:

```json
// In .claude.json
"my-server": {
  "command": "npx",
  "args": ["-y", "@package/server-name"]
}
```

```bash
# In install.sh (add to parallel installation section)
install_npm_package "@package/server-name" "my-server" &
```

## 📚 Documentation

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs)
- [GitHub Codespaces Documentation](https://docs.github.com/codespaces)
- [MCP Servers Documentation](https://modelcontextprotocol.io)
- [SuperClaude Documentation](https://github.com/cyanheads/SuperClaude)

## 🐛 Troubleshooting

### Claude Code not working
```bash
# Check if installed
claude --version

# Check API key loaded
check_secrets

# Reload configuration
source ~/.bashrc
```

### MCP servers failing
```bash
# Check installation log
cat ~/.cache/claude_update.log

# Verify .claude.json exists
ls -la ~/.claude.json
```

### Permissions errors
```bash
# Verify aliases are set
type claude
alias dsp
alias DSP

# All should show correct configuration
```

### Auto-update not running
```bash
# Check update marker
cat ~/.cache/claude_tools_updated

# View update log
cat ~/.cache/claude_update.log

# Force update
rm ~/.cache/claude_tools_updated
# Then open new terminal
```

## 🤝 Contributing

If you fork this repository and want to share improvements:

1. Test changes in a fresh codespace
2. Ensure no personal information is committed
3. Document any new features in README
4. Submit a pull request with clear description

## 📄 License

MIT License - Feel free to use, modify, and share!

## 🙏 Acknowledgments

- [Anthropic](https://anthropic.com) - Claude Code
- [SuperClaude](https://github.com/cyanheads/SuperClaude) - Enhanced framework
- [MCP Servers](https://modelcontextprotocol.io) - Extended capabilities
- [GitHub](https://github.com) - Codespaces platform

---

**Questions or Issues?** Open an issue in this repository or check the troubleshooting section above.

**Star ⭐ this repo if it helps you!**
