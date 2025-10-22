# Troubleshooting Guide

## 🚨 Common Issues

### Issue: "dsp: command not found"

**Symptoms:**
```bash
$ dsp
bash: dsp: command not found
```

**Root Cause:**
Your dotfiles were not loaded in this codespace.

**Solution:**

**Step 1: Verify dotfiles are enabled**
1. Go to https://github.com/settings/codespaces
2. Check if "Automatically install dotfiles" is enabled
3. Repository should be: `stuinfla/dotfiles`

**Step 2: If dotfiles were NOT enabled:**
```bash
# This codespace was created WITHOUT dotfiles
# You need to manually load them:

# Option A: Reload bashrc (if dotfiles were added later)
source ~/.bashrc

# Option B: Create a NEW codespace (recommended)
# Delete this codespace and create a new one with dotfiles enabled
```

**Step 3: Verify .bashrc was loaded**
```bash
# Check if your custom .bashrc exists
ls -la ~/.bashrc

# Check if it contains the DSP aliases
grep -n "alias dsp" ~/.bashrc

# Check if aliases are active
type dsp
alias | grep dsp
```

### Issue: Codespace Not Renamed

**Symptoms:**
Codespace is named "humble engine" or another random name instead of the repository name.

**Root Cause:**
Auto-rename script didn't run because:
1. Dotfiles were not enabled when codespace was created, OR
2. GitHub CLI (`gh`) authentication failed, OR
3. Environment variables not set

**Solution:**

**Step 1: Verify environment variables**
```bash
# Check if you're in a codespace
echo $CODESPACES

# Check repository name
echo $GITHUB_REPOSITORY

# Check codespace name
echo $CODESPACE_NAME
```

**Step 2: Manual rename**
```bash
# Run the rename function manually
rename-codespace

# Or run it directly
gh codespace edit --codespace "$CODESPACE_NAME" --display-name "$(basename $GITHUB_REPOSITORY)"
```

**Step 3: If `gh` command fails**
```bash
# Authenticate GitHub CLI
gh auth login

# Then try renaming again
rename-codespace
```

## 🔍 Diagnostic Commands

### Check if Dotfiles Ran

```bash
# Look for dotfiles directory
ls -la ~/.dotfiles

# Check if install script ran (look for success messages in journal)
journalctl --user | grep -i "installing claude"

# Check if MCP servers installed
npm list -g | grep -i mcp
```

### Check Bash Configuration

```bash
# Show which .bashrc is being used
echo $BASH_SOURCE

# Show .bashrc location
ls -la ~/.bashrc

# Show if it's the GitHub auto-copied one or custom
head -5 ~/.bashrc
```

### Check Claude Code Installation

```bash
# Check if Claude Code is installed
which claude
claude --version

# Check if it's in PATH
echo $PATH | grep npm-global
```

## 🛠️ Manual Installation (If Dotfiles Failed)

If dotfiles didn't run, you can manually install everything:

```bash
# Step 1: Clone dotfiles
git clone https://github.com/stuinfla/dotfiles ~/.dotfiles

# Step 2: Run install script
cd ~/.dotfiles
bash install.sh

# Step 3: Reload shell
source ~/.bashrc

# Step 4: Verify
type dsp
claude --version
```

## ✅ Verification Checklist

After installation, verify everything works:

```bash
# 1. Check aliases
type claude
type dsp
type DSP

# 2. Check Claude Code
claude --version

# 3. Check SuperClaude
python3 -m SuperClaude --version

# 4. Check MCP servers
cat ~/.claude.json | jq '.mcpServers | keys'

# 5. Check auto-updates
cat ~/.cache/claude_tools_updated

# 6. Check sessions directory
ls -la ~/.claude-sessions
```

## 🔄 Starting Fresh

If nothing works, create a completely new codespace:

1. **Delete current codespace**
   - Go to https://github.com/codespaces
   - Find the codespace
   - Click "..." → "Delete"

2. **Verify dotfiles are enabled**
   - Go to https://github.com/settings/codespaces
   - Ensure "Automatically install dotfiles" is checked
   - Repository: `stuinfla/dotfiles`

3. **Create new codespace**
   - Go to your repository
   - Click "Code" → "Codespaces" → "Create codespace on main"
   - Wait 2-5 minutes for installation

4. **Verify installation**
   ```bash
   dsp --version
   check_versions
   check_secrets
   ```

## 📞 Getting Help

If issues persist:

1. Check installation logs: `cat ~/.cache/claude_update.log`
2. Check dotfiles directory: `ls -la ~/.dotfiles`
3. Check GitHub Codespaces logs in the creation process
4. Open an issue at: https://github.com/stuinfla/dotfiles/issues
