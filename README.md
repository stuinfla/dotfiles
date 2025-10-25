# Stuart's Dotfiles

Production-ready dotfiles for GitHub Codespaces with Claude Code + SuperClaude framework.

## 🚀 Quick Setup (3 Steps)

### 1. Fork This Repository
Click the "Fork" button at the top of this page to create your own copy.

### 2. Enable Dotfiles in GitHub Codespaces
1. Go to [GitHub Codespaces Settings](https://github.com/settings/codespaces)
2. Scroll to **"Dotfiles"** section
3. Check ✅ **"Automatically install dotfiles"**
4. Repository: `[your-username]/dotfiles`
5. Click **"Save"**

### 3. Create a Codespace
Create a codespace from **any repository** and your dotfiles will be automatically installed!

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
