# stuinfla/dotfiles - Usage Guide

## 🚀 What This Provides

This dotfiles repository automatically sets up your GitHub Codespace with:

- **Claude Code 2.0.25+** - AI-powered coding assistant
- **SuperClaude** - Enhanced slash commands (`/sc:*`)
- **Claude Flow @alpha v2.7.1+** - 90+ additional MCP servers
- **4 Essential MCPs**: GitHub, Filesystem, Sequential Thinking, Playwright
- **Convenient Aliases**: `dsp`, `DSP`, `dsb`, `DSB` (all skip permissions prompts)
- **Session Resume**: Context persistence across sessions

## 📖 Quick Start

### Option A: Web Browser Method (Recommended)

This is the **simplest method** for most users. GitHub automatically installs dotfiles when creating a Codespace.

#### Step 1: Configure GitHub Codespaces Settings

1. Navigate to: https://github.com/settings/codespaces
2. Set **Dotfiles repository** to: `stuinfla/dotfiles`
3. Keep **Automatically install dotfiles** checked
4. Click **Save**

#### Step 2: Set Up Secrets (Required)

Add your API keys as Codespaces secrets:

1. Go to: https://github.com/settings/codespaces
2. Click **New secret** for each:
   - `ANTHROPIC_API_KEY` or `CLAUDE_API_KEY` - Your Claude API key
   - `GITHUB_ACCESS_TOKEN` - GitHub personal access token (for MCP)
   - Optional: `BRAVE_API_KEY`, `OPENAI_API_KEY`, etc.

Secrets are automatically injected as environment variables in all your Codespaces.

#### Step 3: Create Codespace via Web Browser

**For the dotfiles repository itself:**
1. Navigate to: https://github.com/stuinfla/dotfiles
2. Click the green **Code** button
3. Click the **Codespaces** tab
4. Click **+** or **Create codespace on main**
5. Select machine size: **4-core** (standardLinux32gb) recommended
6. Click **Create**

**For ANY other repository:**
1. Navigate to your target repository
2. Click the green **Code** button
3. Click the **Codespaces** tab
4. Click **+** to create codespace
5. Dotfiles will install automatically!

#### Step 4: Wait for Installation (2-3 minutes)

Watch the terminal for installation progress:
```
═══════════════════════════════════════
📋 STEP 1/5: Copying configuration files...
✅ Copied .bashrc to home directory
✅ Copied .bash_profile to home directory
✅ Copied .claude.json to home directory

📦 STEP 2/5: Installing core tools...
✅ Claude Code installed: 2.0.25
✅ Claude Flow installed: v2.7.1

🚀 Codespace Ready!
━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Claude Code installed (type 'dsp' or 'claude' to start)
✅ SuperClaude installed (use /sc: commands)
✅ Claude Flow @alpha installed
✅ MCP servers configured (4 essential + 90+ via Claude Flow)
```

**Look for**: Green ✅ checkmarks indicate successful installation.

#### Step 5: Activate Aliases (Important!)

**The aliases won't work immediately.** You must restart your terminal:

```bash
# Option 1: Reload shell configuration
bash -l

# Option 2: Source .bashrc
source ~/.bashrc

# Option 3: Close and reopen terminal
# Click the trash icon in VS Code terminal, then open new terminal
```

#### Step 6: Verify Installation

```bash
# Test alias
dsp --version
# Should show: Claude Code 2.0.25

# Or try other aliases
dsb --version
DSP --version
DSB --version

# Check versions
check_versions

# Verify secrets loaded
check_secrets
```

### Option B: GitHub CLI Method (Advanced)

For command-line enthusiasts:

```bash
# Create codespace with dotfiles
gh codespace create \
  --repo YOUR_REPO/YOUR_PROJECT \
  --branch main \
  --machine standardLinux32gb \
  --display-name "my-codespace"

# Or create from dotfiles repo
gh codespace create \
  --repo stuinfla/dotfiles \
  --machine standardLinux32gb \
  --display-name "dotfiles-test"
```

The dotfiles install automatically if configured in GitHub settings.

## 🔧 Machine Size Selection

### Free/Basic GitHub Accounts

| Machine Type | Cores | RAM | When to Use |
|-------------|-------|-----|-------------|
| `basicLinux32gb` | 2 | 8GB | Light work, testing |
| `standardLinux32gb` | 4 | 16GB | **Recommended** - development |

**Note**: Higher-tier machines (8/16/32 cores) require GitHub Team or Enterprise accounts.

### How to Change Machine Size

**For new codespaces**: Select during creation via web UI or `--machine` flag.

**For existing codespaces**:
1. Go to: https://github.com/codespaces
2. Click **...** menu on your codespace
3. Select **Change machine type**
4. Choose `standardLinux32gb` (4 cores)
5. Click **Update codespace**

## ✅ Verification Checklist

After installation completes:

- [ ] Welcome message displays with green checkmarks
- [ ] `dsp --version` shows Claude Code version (after terminal restart)
- [ ] `check_versions` shows all installed tools
- [ ] `check_secrets` shows ✅ for required API keys
- [ ] `/sc:help` shows available SuperClaude commands
- [ ] `nproc` shows 4 cores (if using standardLinux32gb)

## 🆚 Fork vs Direct Use

### Direct Use (Recommended for Most Users)

**Advantages:**
- ✅ Simple - just configure once in GitHub settings
- ✅ Automatic updates when dotfiles repo changes
- ✅ Works across ALL your repositories
- ✅ No maintenance required

**How:**
1. Set dotfiles repository to `stuinfla/dotfiles` in GitHub settings
2. Done! Every codespace uses these dotfiles automatically

### Fork (For Customization)

**When to fork:**
- ❓ You want to customize the install script
- ❓ You need different MCP configurations
- ❓ You want to add personal aliases or scripts

**How to fork:**
1. Visit: https://github.com/stuinfla/dotfiles
2. Click **Fork** button
3. Set your fork as dotfiles repository in GitHub settings
4. Customize as needed
5. Your codespaces will use your fork

**Note**: Forking means you manage updates yourself.

## 🛠️ Available Commands

Once installed, these commands are available:

```bash
# Claude Code
dsp              # Start Claude Code (skip permissions)
DSP              # Same as dsp
dsb              # Same as dsp
DSB              # Same as dsp
claude           # Full Claude Code with session support

# Utility commands
check_versions   # Show installed tool versions
check_secrets    # Verify API keys loaded
check_sessions   # View Claude session history
rename-codespace # Rename to match repository name

# SuperClaude slash commands
/sc:help         # List all SuperClaude commands
/sc:analyze      # Code analysis
/sc:implement    # Feature implementation
/sc:test         # Testing workflows
# ... 20+ more commands
```

## 🐛 Troubleshooting

### Aliases Not Working

**Problem**: `dsp: command not found`

**Solution**: Restart terminal
```bash
bash -l
# Or source ~/.bashrc
# Or close and reopen terminal
```

### Only 2 Cores Instead of 4

**Problem**: Codespace shows 2 cores

**Causes**:
- Created with `basicLinux32gb` (default)
- GitHub Free account limitation (4 cores max)

**Solution**:
- Create new codespace with `standardLinux32gb`
- Or change machine type for existing codespace (see Machine Size section)

### Installation Failed

**Problem**: Red ✖ in creation log

**Solution**:
1. Check creation log: `cat /workspaces/.codespaces/.persistedshare/creation.log`
2. Look for error messages
3. Common issues:
   - Network timeouts → Retry creation
   - npm errors → Usually non-critical, partial success OK
   - Missing permissions → Check GitHub settings

### Secrets Not Loaded

**Problem**: `check_secrets` shows ❌ for API keys

**Solution**:
1. Add secrets at: https://github.com/settings/codespaces
2. **Important**: Secrets only apply to NEW codespaces
3. Delete and recreate codespace to pick up new secrets
4. Or restart codespace: `gh codespace stop` then `gh codespace start`

### MCP Servers Not Working

**Problem**: MCP commands fail

**Solution**:
1. Verify installation: `npm list -g | grep mcp`
2. Check configuration: `cat ~/.claude.json`
3. Essential MCPs should show:
   - `@modelcontextprotocol/server-github`
   - `@modelcontextprotocol/server-filesystem`
   - `@modelcontextprotocol/server-sequential-thinking`
   - `@playwright/mcp`

## 📚 Additional Resources

- **Claude Code Docs**: https://docs.claude.com/claude-code
- **SuperClaude GitHub**: https://github.com/stuartckershaw/SuperClaude
- **Claude Flow**: https://github.com/stuartckershaw/claude-flow
- **GitHub Codespaces Settings**: https://github.com/settings/codespaces
- **MCP Documentation**: https://modelcontextprotocol.io

## 🎯 Success Indicators

Your installation is successful when you see:

```
🚀 Codespace Ready!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Claude Code installed (type 'dsp' or 'claude' to start)
✅ SuperClaude installed (use /sc: commands)
✅ Claude Flow @alpha installed
✅ MCP servers configured (4 essential + 90+ via Claude Flow)
✅ Session resume enabled
```

**Exit Code**: Look for `devcontainer process exited with exit code 0` in creation log - this means success (green ✅).

## 🤝 Getting Help

If you encounter issues:

1. Check the creation log for errors
2. Verify GitHub Codespaces settings configured correctly
3. Ensure secrets added at https://github.com/settings/codespaces
4. Try creating a new codespace (fresh start often resolves issues)
5. Check that terminal has been restarted for aliases

---

**Repository**: https://github.com/stuinfla/dotfiles
**License**: MIT
**Maintained**: Active development with regular updates
