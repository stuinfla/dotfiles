# Dotfiles Installer

**Development workshop for [Stuart's dotfiles](https://github.com/stuinfla/dotfiles)**

This repo contains the automation machinery, testing tools, and development workflow for building and maintaining the production dotfiles configuration.

## 🚀 Quick Start

```bash
# Clone this repo
git clone https://github.com/stuinfla/dotfiles-installer.git
cd dotfiles-installer

# Run automated installation
./install.sh

# Or run manual installation with validation
./manual-install.sh
```

## 📦 What This Does - Complete Automation Breakdown

**TL;DR:** One-click setup that would normally take 3+ hours of manual configuration.

### Complete Automated Installation Process

| Step | What Happens Automatically | What You DON'T Have to Do | Time Saved |
|------|---------------------------|---------------------------|------------|
| **1** | GitHub creates 16-core cloud computer (64GB RAM, 128GB storage) | Buy/configure expensive hardware | Hours + $$$ |
| **2** | VS Code loads in your browser | Install VS Code on your computer | 10 min |
| **3** | GitHub finds your dotfiles repository | Remember to configure each codespace | Every time |
| **4** | Dotfiles cloned to `~/.dotfiles` | Manually copy configuration files | 5 min |
| **5** | **Claude Code** installed (latest version) | Download, install, configure AI assistant | 15 min |
| **6** | **SuperClaude** installed with `/sc:` commands | Set up advanced AI workflows | 20 min |
| **7** | **Claude Flow** installed + registered as MCP server | Configure multi-agent orchestration | 30 min |
| **8** | **5 MCP servers** installed in parallel | Install and configure each server individually | 45 min |
| **9** | `.bashrc`, `.bash_profile`, `.claude.json` configured | Edit configuration files manually | 20 min |
| **10** | **11 VS Code extensions** installed automatically | Search, install, configure each extension | 30 min |
| **11** | **DSP shortcut** created (`dsp` and `dsp /c`) | Type long commands every time | Every session |
| **12** | **ccstatusline** configured (repo, files, context%, tokens, cores, memory) | Guess resource usage blindly | Always |
| **13** | **Auto-update** script starts (daily background updates) | Manually update tools every week | 15 min/week |
| **14** | **Auto-save** script starts (5-minute auto-commit/push) | Remember to commit/push constantly | Every 5 min |
| **15** | **Shutdown protection** enabled (auto-save on close) | Lose work if you forget to save | Data loss risk |
| **16** | Shell reloaded + DSP verified working | Close/reopen terminal, test commands | 5 min |
| **17** | ✅ **Ready to code with AI in 3-5 minutes!** | 3+ hours of manual setup | **3+ hours!** |

### 🎯 What You Get vs. What You DON'T Have to Do

**❌ Without This Automation (Traditional Setup):**
- Spend 3+ hours installing and configuring tools
- Manually install Claude Code, SuperClaude, Claude Flow
- Configure MCP servers one by one
- Install VS Code extensions individually
- Set up keyboard shortcuts and aliases
- Configure status line and monitoring
- Create auto-save scripts from scratch
- Set up auto-update mechanisms
- Test everything works together
- Remember all settings for next time
- Repeat this process for EVERY new codespace

**✅ With This Automation (VibeCoding):**
- **One-click setup** - Create codespace, grab coffee (literally), start coding in 5 minutes
- **Real-time progress** - Watch installation progress live, never wonder if it's hanging
- **Clean startup** - No confusing welcome screens, setup wizards, or extension prompts
- **Consistent environment** - Identical setup on every codespace, every time, everywhere
- **AI-powered development** - Claude Code + SuperClaude + Claude Flow ready instantly
- **Never lose work** - Auto-save every 5 minutes + shutdown protection
- **Always up-to-date** - Daily silent updates for all tools (zero maintenance)
- **Resource visibility** - Status line shows exactly what's happening under the hood
- **Work anywhere** - Any device with a browser becomes a powerful dev machine
- **Zero configuration** - No setup, no maintenance, no thinking required

### 💡 Real-World Impact

**Scenario 1 - New Project:**
- **Traditional:** 3+ hours setting up environment before writing first line of code
- **VibeCoding:** 5 minutes, then immediately start coding with AI assistance

**Scenario 2 - Multiple Devices:**
- **Traditional:** Configure laptop, configure desktop, configure tablet separately (9+ hours total)
- **VibeCoding:** Use same codespace from any device (0 additional setup)

**Scenario 3 - Collaboration:**
- **Traditional:** "It works on my machine" (everyone has different setups)
- **VibeCoding:** Everyone has identical environments (zero config drift)

**Scenario 4 - Maintenance:**
- **Traditional:** Update tools manually every week (15+ min/week = 13 hours/year)
- **VibeCoding:** Silent auto-updates daily (0 minutes/year)

**Scenario 5 - Data Loss:**
- **Traditional:** Forget to save, codespace times out, lose 2 hours of work
- **VibeCoding:** Auto-save every 5 minutes + shutdown protection (impossible to lose work)

---

## 🏗️ Repository Architecture

### Two-Repo Strategy

**[dotfiles](https://github.com/stuinfla/dotfiles)** - Production (What Users Fork)
- Clean configuration files only
- Users fork this repo and enable in Codespaces settings
- GitHub auto-installs on new codespaces
- **This is the public-facing repo**

**[dotfiles-installer](https://github.com/stuinfla/dotfiles-installer)** - Development (This Repo)
- All automation machinery and testing tools
- Development and validation scripts
- Comprehensive documentation
- **This is YOUR workshop**

### Development Workflow

```
1. Development (This Repo)
   ├── Create new features
   ├── Test automation scripts
   ├── Validate configurations
   └── Update documentation

2. Production Release
   ├── Copy clean configs → dotfiles repo
   ├── Update dotfiles README
   ├── Commit to dotfiles repo
   └── Users get updates via git pull

3. End Users
   ├── Fork stuinfla/dotfiles
   ├── Enable in Codespaces settings
   └── Automatic installation on new codespaces
```

**Why This Works:**
- ✅ **Clean separation** - Configuration vs machinery
- ✅ **Easy adoption** - Users just fork dotfiles
- ✅ **Flexible development** - Full tooling in installer
- ✅ **Standard naming** - dotfiles repo follows conventions

## 📚 Scripts

### Installation Scripts
- **`install.sh`** - Main automated installer with full validation
- **`manual-install.sh`** - Manual installation with step-by-step prompts
- **`add-devcontainer.sh`** - Add devcontainer configuration to existing repo
- **`check-dotfiles-config.sh`** - Validate dotfiles configuration
- **`health-check.sh`** - Comprehensive system health check

### Utility Scripts
- **`scripts/cleanup-vscode-state.sh`** - Clean VS Code state and caches
- **`scripts/reset-kombai.sh`** - Reset Kombai extension settings

## 🛠️ Manual Installation

If you prefer manual control:

```bash
# 1. Clone dotfiles repo
git clone https://github.com/stuinfla/dotfiles.git ~/dotfiles

# 2. Backup existing dotfiles
mkdir -p ~/.dotfiles.backup
cp ~/.bash_profile ~/.dotfiles.backup/ 2>/dev/null || true
cp ~/.bashrc ~/.dotfiles.backup/ 2>/dev/null || true
cp ~/.claude.json ~/.dotfiles.backup/ 2>/dev/null || true

# 3. Copy new dotfiles
cp ~/dotfiles/.bash_profile ~/
cp ~/dotfiles/.bashrc ~/
cp ~/dotfiles/.claude.json ~/
cp -r ~/dotfiles/.devcontainer ~/
cp -r ~/dotfiles/.vscode ~/
cp -r ~/dotfiles/.claude ~/

# 4. Install MCP servers
claude mcp add claude-flow npx claude-flow@alpha mcp start
claude mcp add sequential npx @modelcontextprotocol/server-sequential-thinking
claude mcp add context7 npx @upstash/context7-mcp

# 5. Reload shell
source ~/.bash_profile
```

## 📖 Documentation

Comprehensive guides in the `docs/` directory:

- **[SETUP-GUIDE.md](docs/SETUP-GUIDE.md)** - Detailed setup instructions
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[USAGE_GUIDE.md](docs/USAGE_GUIDE.md)** - Using the dotfiles after installation
- **[INSTALLATION_MANIFEST.md](docs/INSTALLATION_MANIFEST.md)** - Complete installation details
- **[Claude-Flow-Complete-Guide-v2.7.0.md](docs/Claude-Flow-Complete-Guide-v2.7.0-alpha.10.md)** - Claude Flow documentation
- **[Claude-Flow-Quick-Reference-v2.7.0.md](docs/Claude-Flow-Quick-Reference-v2.7.0.md)** - Quick reference guide

## 🎯 Features

### Real-Time Progress Visibility 📊 (NEW - Oct 2025)
No more wondering if installation is working or hanging!

**Live Progress Tracking:**
```bash
# Installation shows real-time progress:
⏳ STEP 1/5: Copying configuration files...
✅ Copied .bashrc to home directory
✅ Copied .bash_profile to home directory
⏳ Configuring VS Code to suppress welcome screens...
✅ VS Code configured: Cline blocked + welcome screens suppressed

⏳ STEP 2/5: Installing AI tools...
⏳   [1/3] Installing Claude Code (latest)...
✅         Claude Code installed
⏳   [2/3] Installing SuperClaude (latest)...
✅         SuperClaude installed

⏳ Installing 4 essential MCP servers in parallel...
✅   ✅ GitHub MCP
✅   ✅ Filesystem MCP
✅   ✅ Playwright MCP
✅   ✅ Sequential Thinking MCP
```

**Monitor Installation Live:**
```bash
# If you want detailed progress:
tail -f /tmp/dotfiles-progress.txt

# For full logs:
tail -f /tmp/dotfiles-install.log
```

**Benefits:**
- ✅ See exactly what's happening at each step
- ✅ Timestamped progress entries
- ✅ Never wonder if it's working or stuck
- ✅ Clear success/failure indicators
- ✅ Can debug issues in real-time

### Clean Startup Experience 🎨 (NEW - Oct 2025)
No confusing welcome screens or setup wizards!

**What We Suppress:**
- ❌ VS Code theme selection and configuration wizards
- ❌ Kombai "Build with agent mode" welcome screen
- ❌ Extension "Getting Started" pages
- ❌ Update notifications and prompts
- ❌ Survey and feedback requests
- ❌ Tutorial overlays and walkthroughs

**What You Get Instead:**
- ✅ Clean file explorer view on startup
- ✅ All extensions installed and configured
- ✅ No interruptions or questions
- ✅ Ready to code immediately
- ✅ Professional, distraction-free environment

**How We Do It:**
- Three-layer suppression system (workspace, container, runtime)
- VS Code global state configuration
- Extension-specific flag management
- Runs automatically during installation

### Automatic Daily Updates 🔄
- **Silent background updates** (no notifications, no blocking)
- **Claude Code** - Latest stable version
- **SuperClaude** - Latest release
- **Claude Flow @alpha** - Latest alpha + re-initialization
- **VS Code Extensions** - All installed extensions
- **Logs**: `~/.cache/claude_update.log`

### Claude Flow Full Instantiation 🌊
- **Global installation** (`npm install -g claude-flow@alpha`)
- **MCP server registration** (`claude mcp add claude-flow`)
- **Directory instantiation** (`.claude-flow/` copied to home)
- **Configuration initialization** (`claude-flow init --force`)
- **90+ MCP tools** available for advanced workflows

### SuperClaude Framework
The installer sets up the complete SuperClaude AI framework:
- 11 specialized domain personas (Architect, Frontend, Backend, Security, etc.)
- Intelligent routing and orchestration
- MCP server integration (Claude Flow, Sequential, GitHub, Filesystem, Playwright)
- Automated hooks for code formatting and quality
- Neural training patterns for continuous improvement

### Claude Code Integration
- Pre-configured MCP servers for enhanced AI capabilities
- SPARC methodology support for systematic development
- Automated code formatting and quality checks
- Session management and persistence (`~/.claude-sessions`)
- Cross-session memory and context

### Development Environment
- GitHub Codespaces ready with devcontainer
- VS Code extensions auto-installation
- Bash configuration with helpful aliases
- Git workflow optimizations

## 🔧 Advanced Options

### Environment Variables
```bash
# Customize installation
export DOTFILES_REPO="https://github.com/stuinfla/dotfiles.git"
export DOTFILES_DIR="$HOME/dotfiles"
export BACKUP_DIR="$HOME/.dotfiles.backup"

# Run installer with custom settings
./install.sh
```

### Installation Flags
```bash
# Skip specific steps
./install.sh --skip-mcp        # Skip MCP server installation
./install.sh --skip-backup     # Skip backup creation
./install.sh --skip-validation # Skip validation checks

# Dry run (show what would be done)
./install.sh --dry-run
```

## 🧪 Validation

Run comprehensive validation after installation:

```bash
# Full health check
./health-check.sh

# Configuration validation
./check-dotfiles-config.sh

# MCP server status
claude mcp list
```

## 🔗 Related Resources

- **[dotfiles](https://github.com/stuinfla/dotfiles)** - Production configuration (what users fork)
- **[Claude Code](https://github.com/anthropics/claude-code)** - Anthropic's official CLI
- **[Claude Flow](https://github.com/ruvnet/claude-flow)** - Multi-agent orchestration
- **[Sequential Thinking](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking)** - Structured reasoning
- **[Context7](https://github.com/upstash/context7-mcp)** - Documentation lookup

## 📄 License

Personal automation tools - use at your own discretion.

## 🤝 Contributing

Issues and pull requests welcome! Please ensure:
- Scripts are POSIX-compliant
- Documentation is updated
- Validation tests pass
- Changes are backwards-compatible

## 💡 Support

For issues or questions:
- Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Review [SETUP-GUIDE.md](docs/SETUP-GUIDE.md)
- Open an issue on GitHub
