# Stuart's Dotfiles - VibeCoding Setup

**Automated AI-powered development environment for GitHub Codespaces**

**TL;DR:** One-click setup that automatically installs Claude Code, SuperClaude, Claude Flow, 5 MCP servers, and 11 VS Code extensions in 3-5 minutes. Saves 3+ hours of manual configuration every time you create a codespace.

---

## 🚀 Quick Setup (3 Steps - One Time Only!)

### Step 1: Fork This Repo
Click the "Fork" button at the top right of this page.

### Step 2: Enable in Your GitHub Settings
1. Go to [GitHub Codespaces Settings](https://github.com/settings/codespaces)
2. Under **"Dotfiles"** section:
   - ✅ Check **"Automatically install dotfiles"**
   - Repository: `YOUR-USERNAME/dotfiles` (your fork)
3. Click **"Save"**

### Step 3: Create a Codespace (On ANY Repo)
1. Go to **any repository** you want to work on
2. Click **Code** → **Codespaces** → **Create codespace**
3. ☕ Wait 3-5 minutes while everything installs automatically
4. Open terminal and type `dsp` to start coding with AI!

**That's it!** Every new codespace you create will have this setup automatically. Set it once, use it forever.

---

## 📦 What Gets Installed Automatically (The Magic)

### Complete Automated Installation

| What You Get | What You DON'T Have to Do | Time Saved |
|-------------|---------------------------|------------|
| ✅ **16-core cloud computer** (or max for your account) | Buy expensive hardware | Hours + $$$ |
| ✅ **Claude Code** (latest version) | Download, install, configure AI assistant | 15 min |
| ✅ **SuperClaude** with `/sc:` commands | Set up advanced AI workflows | 20 min |
| ✅ **Claude Flow** multi-agent system | Configure AI team orchestration | 30 min |
| ✅ **5 MCP Servers** (GitHub, filesystem, playwright, etc.) | Install and configure each server | 45 min |
| ✅ **11 VS Code Extensions** (Python, Jupyter, Office viewers, etc.) | Search, install, configure extensions | 30 min |
| ✅ **DSP shortcut** - Type `dsp` to launch Claude | Type long commands every time | Every session |
| ✅ **Status line** - Shows repo, files, context%, tokens, cores, memory | Guess resource usage | Always |
| ✅ **Auto-updates** - Daily silent updates for all tools | Manually update weekly | 15 min/week |
| ✅ **Auto-save** - Auto-commit/push every 5 minutes | Remember to save constantly | Every 5 min |
| ✅ **Shutdown protection** - Saves uncommitted work | Lose work when closing | Data loss risk |
| **TOTAL** | **Manual setup every time** | **3+ hours!** |

### 🎯 Real-World Impact

**Scenario 1 - New Project:**
- ❌ Traditional: 3+ hours setting up before first line of code
- ✅ VibeCoding: 5 minutes, then start coding with AI

**Scenario 2 - Multiple Devices:**
- ❌ Traditional: Configure laptop + desktop + tablet = 9+ hours
- ✅ VibeCoding: Same environment on any device = 0 setup

**Scenario 3 - Collaboration:**
- ❌ Traditional: "Works on my machine" problems
- ✅ VibeCoding: Everyone has identical environments

**Scenario 4 - Maintenance:**
- ❌ Traditional: Update tools manually = 13 hours/year
- ✅ VibeCoding: Silent auto-updates = 0 hours/year

**Scenario 5 - Data Loss:**
- ❌ Traditional: Forget to save, lose hours of work
- ✅ VibeCoding: Auto-save every 5 min = impossible to lose work

---

## 📦 What's Included

### Core Configuration
- **Bash** - `.bash_profile`, `.bashrc` with helpful aliases
- **Claude Code MCP** - `.claude.json` with pre-configured MCP servers
- **VS Code** - `.vscode/extensions.json` with recommended extensions
- **Codespaces** - `.devcontainer/devcontainer.json` for optimal setup
- **SuperClaude Framework** - `.claude/` directory with complete AI framework
- **Project Instructions** - `CLAUDE.md` for Claude Code integration

### SuperClaude AI Framework (209 Files)
Complete AI-powered development framework in `.claude/`:
- **11 Specialized Personas** - Architect, Frontend, Backend, Security, Performance, etc.
- **Intelligent Routing** - Auto-selects optimal tools and approaches
- **MCP Integration** - Claude Flow, Sequential Thinking, Context7
- **SPARC Methodology** - Systematic development workflows
- **54+ Specialized Agents** - For every development task

---

## 🎯 How It Works

When you create a new codespace:

1. **GitHub clones your fork** of this repo
2. **Copies all dotfiles** to your home directory
3. **Your codespace is ready** with full configuration!

No manual installation needed - it's completely automatic!

---

## 🔧 Customization

### Add Your API Keys

Add secrets at [GitHub Codespaces Secrets](https://github.com/settings/codespaces):

| Secret Name | Purpose |
|-------------|---------|
| `ANTHROPIC_API_KEY` | Claude Code (required) |
| `BRAVE_API_KEY` | Web search MCP (optional) |
| `GITHUB_ACCESS_TOKEN` | GitHub integration MCP (optional) |

### Modify Configuration

Simply edit the files in your fork:
- `.bashrc` - Shell aliases and functions
- `.claude.json` - MCP server configuration
- `.devcontainer/devcontainer.json` - Codespace machine specs
- `.vscode/extensions.json` - VS Code extensions

Commit changes to your fork, and they'll apply to all new codespaces!

---

## 🛠️ Development

Want to improve these dotfiles or build installation automation?

See **[dotfiles-installer](https://github.com/stuinfla/dotfiles-installer)** for:
- Development and testing machinery
- Validation and health-check scripts
- Comprehensive documentation
- Templates and utilities

## 📚 File Structure

```
dotfiles/
├── .bash_profile          # Shell startup
├── .bashrc                # Aliases, functions, environment
├── .claude.json           # MCP servers configuration
├── .gitignore             # Excludes runtime artifacts
├── .devcontainer/
│   └── devcontainer.json  # Codespace machine configuration
├── .vscode/
│   └── extensions.json    # Recommended VS Code extensions
├── .claude/               # SuperClaude AI Framework (209 files)
│   ├── FLAGS.md           # Behavioral flags
│   ├── PRINCIPLES.md      # Engineering principles
│   ├── RULES.md           # Behavioral rules
│   ├── COMMANDS.md        # Command framework
│   ├── MODES.md           # Operational modes
│   ├── ORCHESTRATOR.md    # Routing system
│   ├── PERSONAS.md        # 11 domain personas
│   ├── MCP.md             # MCP integration
│   ├── agents/            # 54+ specialized agents
│   ├── commands/          # Command implementations
│   ├── skills/            # Claude Code skills
│   └── helpers/           # Utility scripts
├── CLAUDE.md              # Project-specific instructions
└── README.md              # This file
```

---

## 💡 Tips

**Using Claude Code:**
```bash
# Standard command
claude

# Continue most recent session
claude -c

# Resume specific session
claude --resume
```

**Update Your Fork:**
```bash
# Keep your fork in sync with improvements
cd ~/dotfiles
git pull upstream main
git push origin main
```

---

## 🔗 Resources

- **[dotfiles-installer](https://github.com/stuinfla/dotfiles-installer)** - Development tools
- **[Claude Code](https://docs.anthropic.com/claude/docs)** - Official documentation
- **[SuperClaude](https://github.com/cyanheads/SuperClaude)** - Enhanced framework
- **[GitHub Codespaces](https://docs.github.com/codespaces)** - Codespaces docs
- **[Claude Flow](https://github.com/ruvnet/claude-flow)** - Multi-agent orchestration

---

## 📄 License

MIT License - Feel free to fork, modify, and share!

---

**Questions?** Open an issue or check the [development repo](https://github.com/stuinfla/dotfiles-installer).

**Star ⭐ this repo if it helps you!**
