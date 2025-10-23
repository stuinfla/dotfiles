# stuinfla/dotfiles - Usage Guide for External Users

## 🚀 What This Provides

This dotfiles repository automatically sets up your GitHub Codespace with:

- **Claude Code 2.0.25+** - AI-powered coding assistant
- **SuperClaude** - Enhanced slash commands (`/sc:*`)
- **Claude Flow @alpha v2.7.1+** - 90+ additional MCP servers
- **4 Essential MCPs**: GitHub, Filesystem, Sequential Thinking, Playwright
- **Convenient Aliases**: `dsp`, `DSP`, `dsb`, `DSB` (all skip permissions prompts)
- **Session Resume**: Context persistence across sessions

---

## 📖 Quick Start: Choose Your Method

### 🎯 For External Users (Recommended)

**You want your OWN dotfiles that you can customize?**

👉 **Use Method 1: Fork Repository** (see below)

This creates YOUR OWN copy at `github.com/YOUR_USERNAME/dotfiles` that you fully control.

### 🔬 For Testing/Reference Only

**Just want to try it out without forking?**

👉 **Use Method 2: Direct Use** (see below)

This uses the original `stuinfla/dotfiles` directly - good for testing, but you can't customize it.

---

## Method 1: Fork Repository (Recommended for Your Own Use)

**This is what most external users should do.** Forking creates YOUR OWN copy of the dotfiles repository in YOUR GitHub account.

### Why Fork?

✅ **Full Control**: It's YOUR repository - customize however you want
✅ **Your Updates**: Make changes anytime without affecting the original
✅ **No Dependencies**: Works even if original repo is deleted
✅ **Your Secrets**: API keys stored in YOUR GitHub account
✅ **Persistence**: Your dotfiles work across all YOUR repositories

### Step 1: Fork the Repository

1. **Visit**: https://github.com/stuinfla/dotfiles
2. **Click**: The **Fork** button (top-right corner)
3. **Select**: Your GitHub account as the destination
4. **Create Fork**: GitHub creates `github.com/YOUR_USERNAME/dotfiles`

**Result**: You now have YOUR OWN copy at:
```
https://github.com/YOUR_USERNAME/dotfiles
```

Example: If your username is `johndoe`, your fork is at:
```
https://github.com/johndoe/dotfiles
```

### Step 2: Configure GitHub Codespaces Settings

**Important**: Use YOUR fork URL, not the original!

1. Navigate to: https://github.com/settings/codespaces
2. Under **Dotfiles**, set:
   - **Repository**: `YOUR_USERNAME/dotfiles` ← **YOUR fork, not stuinfla/dotfiles**
   - **Install automatically**: ✅ Checked (default)
3. Click **Save**

**Example Configuration**:
```
Dotfiles repository: johndoe/dotfiles  ← YOUR username here
```

### Step 3: Add Your API Keys (Secrets)

Add your API keys as Codespaces secrets in YOUR GitHub account:

1. Stay on: https://github.com/settings/codespaces
2. Scroll to **Codespaces secrets**
3. Click **New secret** for each:
   - **Name**: `ANTHROPIC_API_KEY` or `CLAUDE_API_KEY`
   - **Value**: Your Claude API key
   - **Repository access**: All repositories (or specific ones)

4. Add other optional secrets:
   - `GITHUB_ACCESS_TOKEN` - GitHub personal access token
   - `BRAVE_API_KEY` - Brave Search API
   - `OPENAI_API_KEY` - OpenAI API
   - etc.

**Important**: Secrets are stored in YOUR GitHub account and injected automatically.

### Step 4: Create a Codespace

Now create a codespace in ANY of YOUR repositories:

**Via Web Browser (Easiest)**:
1. Navigate to ANY repository you own
2. Click the green **Code** button
3. Click the **Codespaces** tab
4. Click **+** or **Create codespace on main**
5. **Select machine**: `4-core (standardLinux32gb)` recommended
6. Click **Create**

**Via GitHub CLI**:
```bash
# Create codespace in any of your repos
gh codespace create \
  --repo YOUR_USERNAME/YOUR_PROJECT \
  --machine standardLinux32gb \
  --display-name "my-codespace"
```

### Step 5: Wait for Installation (2-3 minutes)

Watch the terminal for the installation progress from YOUR fork:

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
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Claude Code installed (type 'dsp' or 'claude' to start)
✅ SuperClaude installed (use /sc: commands)
✅ Claude Flow @alpha installed
✅ MCP servers configured (4 essential + 90+ via Claude Flow)
```

**Success Indicator**: Green ✅ checkmarks throughout

### Step 6: Activate Aliases (Required!)

**The aliases won't work immediately** - you must restart your terminal:

```bash
# Option 1: Reload shell
bash -l

# Option 2: Source .bashrc
source ~/.bashrc

# Option 3: Close and reopen terminal in VS Code
```

### Step 7: Verify Installation

```bash
# Test alias
dsp --version
# Should show: Claude Code 2.0.25

# Check all tools
check_versions

# Verify secrets loaded
check_secrets
```

### Step 8: Customize Your Fork (Optional)

Now you can customize YOUR dotfiles:

1. Clone YOUR fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git
   cd dotfiles
   ```

2. Make changes:
   - Edit `.bashrc` for custom aliases
   - Modify `.claude.json` for different MCPs
   - Update `install.sh` for additional tools

3. Commit and push:
   ```bash
   git add .
   git commit -m "Customize my dotfiles"
   git push origin main
   ```

4. **Future codespaces automatically use your changes!**

---

## Method 2: Use Original Directly (Reference/Testing)

**This method uses `stuinfla/dotfiles` directly without forking.**

### When to Use This?

✅ **Testing**: Try it out before forking
✅ **Reference**: See how it works
✅ **No Customization Needed**: You're happy with the defaults

❌ **Not Recommended If**: You want to customize or have your own copy

### Quick Setup (Direct Use)

1. **Configure GitHub Settings**:
   - Go to: https://github.com/settings/codespaces
   - Set **Dotfiles repository**: `stuinfla/dotfiles` ← Original repo
   - Enable: **Install automatically**

2. **Add Secrets** (same as Method 1):
   - Add `ANTHROPIC_API_KEY`, `GITHUB_ACCESS_TOKEN`, etc.
   - At: https://github.com/settings/codespaces

3. **Create Codespace** (same as Method 1):
   - Any repository → Code → Codespaces → Create
   - Select 4-core machine

4. **Restart Terminal**: `bash -l` to activate aliases

5. **Verify**: `dsp --version`

### Limitations of Direct Use

⚠️ **No Customization**: You can't modify the original repository
⚠️ **Dependency**: If original repo changes, your setup changes
⚠️ **No Control**: Can't freeze to a specific version

**Recommendation**: Fork it to have your own copy!

---

## 🔧 Understanding Forking

### What Happens When You Fork?

```
Original Repository:
https://github.com/stuinfla/dotfiles

↓ You click "Fork"

Your Fork (YOUR COPY):
https://github.com/YOUR_USERNAME/dotfiles
```

### Key Points About Forks

1. **Independent Copy**: Your fork is completely separate from the original
2. **You Own It**: Full read/write access to YOUR fork
3. **No Connection Required**: Works even if original is deleted
4. **Can Sync Updates**: Optionally pull updates from original
5. **Your Settings Apply**: GitHub Codespaces uses YOUR fork URL

### Fork vs Direct Use Comparison

| Feature | Fork (Method 1) | Direct (Method 2) |
|---------|----------------|-------------------|
| **Ownership** | You own it | stuinfla owns it |
| **Customization** | ✅ Full control | ❌ No changes allowed |
| **URL** | `YOUR_USERNAME/dotfiles` | `stuinfla/dotfiles` |
| **Updates** | You control | Auto-updates from original |
| **Recommended For** | YOUR own use | Testing/reference |

---

## 🔍 Machine Size Selection

### Free/Basic GitHub Accounts

| Machine Type | Cores | RAM | When to Use |
|-------------|-------|-----|-------------|
| `basicLinux32gb` | 2 | 8GB | Light work, testing |
| `standardLinux32gb` | 4 | 16GB | **Recommended** - development |

**Note**: Higher-tier machines (8/16/32 cores) require GitHub Team or Enterprise accounts.

### How to Select Machine Size

**During Creation** (Web Browser):
1. Click Code → Codespaces → +
2. Look for **Machine type** dropdown
3. Select: **4-core (16 GB RAM, 32 GB storage)**
4. Click Create

**During Creation** (GitHub CLI):
```bash
gh codespace create \
  --machine standardLinux32gb \  # ← 4 cores
  --repo YOUR_USERNAME/YOUR_PROJECT
```

**For Existing Codespace**:
1. Go to: https://github.com/codespaces
2. Click **...** menu on your codespace
3. Select **Change machine type**
4. Choose **4-core (16 GB RAM)**
5. Click **Update codespace**

---

## ✅ Verification Checklist

After installation completes, verify everything works:

- [ ] Welcome message displays with green ✅ checkmarks
- [ ] Terminal restarted (`bash -l`)
- [ ] `dsp --version` shows Claude Code version
- [ ] `dsb --version` also works (all 4 aliases work)
- [ ] `check_versions` shows all tools installed
- [ ] `check_secrets` shows ✅ for required API keys
- [ ] `/sc:help` shows SuperClaude commands
- [ ] `nproc` shows 4 cores (if using standardLinux32gb)

---

## 🛠️ Available Commands

Once installed, these commands are available:

```bash
# Claude Code (all 4 aliases work identically)
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

# SuperClaude slash commands (20+ available)
/sc:help         # List all SuperClaude commands
/sc:analyze      # Code analysis
/sc:implement    # Feature implementation
/sc:test         # Testing workflows
/sc:design       # System design
/sc:improve      # Code improvement
# ... and many more
```

---

## 🐛 Troubleshooting

### Aliases Not Working

**Problem**: `dsp: command not found`

**Cause**: Terminal needs to be restarted to load new configuration

**Solution**:
```bash
# Reload shell configuration
bash -l

# Or source .bashrc
source ~/.bashrc

# Or close and reopen terminal in VS Code
```

### Installation Used Wrong Repository

**Problem**: Installation used `stuinfla/dotfiles` instead of YOUR fork

**Cause**: GitHub Codespaces settings not configured correctly

**Solution**:
1. Check settings: https://github.com/settings/codespaces
2. Verify **Dotfiles repository** shows: `YOUR_USERNAME/dotfiles`
3. NOT: `stuinfla/dotfiles` (unless using Method 2)
4. Delete codespace and create new one with correct settings

### Only 2 Cores Instead of 4

**Problem**: `nproc` shows 2 cores

**Cause**: Created with default `basicLinux32gb` (2 cores)

**Solution**:
- **For new codespaces**: Select "4-core" during creation
- **For existing codespaces**: Change machine type via GitHub UI

### Secrets Not Loading

**Problem**: `check_secrets` shows ❌ for API keys

**Cause**: Secrets not added or not applied to new codespaces

**Solution**:
1. Add secrets: https://github.com/settings/codespaces
2. **Important**: Secrets only apply to NEW codespaces
3. Delete and recreate codespace to pick up new secrets
4. Or restart: `gh codespace stop` then `gh codespace start`

### Customizations Not Appearing

**Problem**: Made changes to YOUR fork but codespace doesn't reflect them

**Cause**: Codespace uses cached version or wrong repository

**Solution**:
1. Verify changes pushed to YOUR fork: `https://github.com/YOUR_USERNAME/dotfiles`
2. Delete existing codespace
3. Create fresh codespace (pulls latest from YOUR fork)
4. Check installation log shows YOUR fork URL

### How to Sync Updates from Original

**Problem**: Want to pull updates from `stuinfla/dotfiles` into YOUR fork

**Solution**:
```bash
# In your local fork
git remote add upstream https://github.com/stuinfla/dotfiles.git
git fetch upstream
git merge upstream/main
git push origin main
```

This pulls updates from original while keeping your customizations.

---

## 📚 Additional Resources

- **Original Repository**: https://github.com/stuinfla/dotfiles
- **Claude Code Docs**: https://docs.claude.com/claude-code
- **SuperClaude GitHub**: https://github.com/stuartckershaw/SuperClaude
- **Claude Flow**: https://github.com/stuartckershaw/claude-flow
- **GitHub Codespaces Settings**: https://github.com/settings/codespaces
- **GitHub Forking Guide**: https://docs.github.com/en/get-started/quickstart/fork-a-repo
- **MCP Documentation**: https://modelcontextprotocol.io

---

## 🎯 Success Indicators

Your installation from YOUR fork is successful when you see:

```
🚀 Codespace Ready!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Claude Code installed (type 'dsp' or 'claude' to start)
✅ SuperClaude installed (use /sc: commands)
✅ Claude Flow @alpha installed
✅ MCP servers configured (4 essential + 90+ via Claude Flow)
✅ Session resume enabled
```

**Exit Code Check**: Look for `devcontainer process exited with exit code 0` in creation log - this means success (green ✅).

---

## 🤝 Getting Help

If you encounter issues with YOUR fork:

1. **Check the creation log** for errors:
   ```bash
   cat /workspaces/.codespaces/.persistedshare/creation.log | tail -100
   ```

2. **Verify GitHub settings** configured with YOUR fork:
   - Settings show: `YOUR_USERNAME/dotfiles`
   - NOT: `stuinfla/dotfiles` (unless using Method 2)

3. **Ensure secrets added** at: https://github.com/settings/codespaces

4. **Try fresh codespace**: Delete and recreate often resolves issues

5. **Check terminal restarted**: Run `bash -l` for aliases to work

6. **Verify fork exists**: Visit `https://github.com/YOUR_USERNAME/dotfiles`

---

## 📝 Summary for External Users

**To use stuinfla/dotfiles as YOUR OWN dotfiles:**

1. ✅ **Fork** `stuinfla/dotfiles` to `YOUR_USERNAME/dotfiles`
2. ✅ **Configure** GitHub Codespaces with YOUR fork URL
3. ✅ **Add secrets** in YOUR GitHub account
4. ✅ **Create codespaces** (uses YOUR fork automatically)
5. ✅ **Restart terminal** to activate aliases
6. ✅ **Customize YOUR fork** as needed (optional)

**Result**: Every codespace you create automatically uses YOUR dotfiles setup!

---

**Repository**: https://github.com/stuinfla/dotfiles (Fork this to YOUR account!)
**License**: MIT
**Maintained**: Active development with regular updates
