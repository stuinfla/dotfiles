# Stuart's Dotfiles

My personal development environment configuration with Claude Code + SuperClaude framework.

## 🚀 Quick Install

```bash
git clone https://github.com/stuinfla/dotfiles-clean.git ~/dotfiles
cd ~/dotfiles
# Copy files to your home directory as needed
```

## 📦 What's Included

- **Bash configuration** - `.bash_profile`, `.bashrc`
- **Claude Code MCP setup** - `.claude.json` for Model Context Protocol servers
- **VS Code extensions** - `.vscode/extensions.json` with recommended extensions
- **Codespace configuration** - `.devcontainer/devcontainer.json` for GitHub Codespaces
- **SuperClaude AI framework** - `.claude/` directory with complete framework files
- **Project instructions** - `CLAUDE.md` for Claude Code integration

## 🛠️ Manual Setup

Copy individual files to your home directory:

```bash
cp .bash_profile ~/.bash_profile
cp .bashrc ~/.bashrc
cp .claude.json ~/.claude.json
cp -r .devcontainer ~/.devcontainer
cp -r .vscode ~/.vscode
cp -r .claude ~/.claude
```

## 🤖 Automated Installation

For automated installation with validation and setup, see:
**[dotfiles-installer](https://github.com/stuinfla/dotfiles-installer)**

## 📚 Key Features

### SuperClaude Framework
The `.claude/` directory contains a comprehensive AI framework:
- **FLAGS.md** - Behavioral flags and mode activation
- **PRINCIPLES.md** - Software engineering principles
- **RULES.md** - Behavioral rules and best practices
- **COMMANDS.md** - Command execution framework
- **MODES.md** - Operational modes (Task Management, Introspection, Token Efficiency)
- **ORCHESTRATOR.md** - Intelligent routing system
- **PERSONAS.md** - 11 specialized domain personas
- **MCP.md** - MCP server integration

### Claude Code Integration
- Pre-configured MCP servers (Claude Flow, Sequential Thinking, Context7)
- SPARC methodology support for systematic development
- Automated hooks for code formatting and quality checks
- Neural training patterns for continuous improvement

## 🔗 Related Resources

- **[dotfiles-installer](https://github.com/stuinfla/dotfiles-installer)** - Automated setup tools
- **[Claude Code](https://github.com/anthropics/claude-code)** - Anthropic's official CLI
- **[Claude Flow](https://github.com/ruvnet/claude-flow)** - Multi-agent orchestration

## 📄 License

Personal configuration files - use at your own discretion.
