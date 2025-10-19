# GitHub Codespaces Setup Guide

**Updated**: October 19, 2025
**For**: You and your 4 students

---

## 🎯 What This Does

**One-time setup** that gives you Claude Code + Claude Flow + larger machines in EVERY Codespace you create.

**Result**: Go to any repo → Create Codespace → Everything is configured automatically!

---

## 📋 Setup (Do This ONCE)

### Step 1: Configure Your Dotfiles Repository

**You already have this!** Your dotfiles repo is at: `https://github.com/stuinfla/dotfiles`

**What your students need to do**:

1. **Fork your dotfiles repo** (easiest way):
   ```bash
   # Go to: https://github.com/stuinfla/dotfiles
   # Click "Fork" button
   # Creates their own copy
   ```

   **OR create their own** (from scratch):
   ```bash
   # Create new repo called "dotfiles"
   gh repo create dotfiles --public --clone
   cd dotfiles

   # Copy files from your dotfiles repo
   # (You'll share the files with them)
   ```

### Step 2: Enable Dotfiles in GitHub Settings

**Everyone must do this (you and students)**:

1. Go to: **https://github.com/settings/codespaces**

2. Scroll to **"Dotfiles"** section

3. Configure:
   - ✅ Check "Automatically install dotfiles"
   - Repository: `YOUR_USERNAME/dotfiles` (e.g., `stuinfla/dotfiles`)
   - Install command: `bash install.sh`

4. Click **"Save"**

**That's it for dotfiles setup!** ✅

### Step 3: Configure Secrets (API Keys)

**If you want MCP servers to work** (optional but recommended):

1. Go to: **https://github.com/settings/codespaces**

2. Scroll to **"Codespaces secrets"**

3. Add secrets:
   - `ANTHROPIC_API_KEY` or `CLAUDE_API_KEY` (for Claude Code)
   - `BRAVE_API_KEY` (for web search MCP)
   - `GITHUB_ACCESS_TOKEN` (for GitHub MCP)
   - `HUGGINGFACE_API_KEY` (for HuggingFace MCP)

**Students**: They need their own API keys if they want MCPs

---

## 🚀 Using It (Every Project)

### For Projects You Want Larger Machines

**If you want 4-core machines** (instead of default 2-core):

1. Go to your project repository

2. Run the setup script:
   ```bash
   # Option A: If you cloned your dotfiles locally
   cd /path/to/your/project
   bash /path/to/dotfiles/add-devcontainer.sh

   # Option B: Direct from GitHub (easiest)
   curl -sSL https://raw.githubusercontent.com/stuinfla/dotfiles/main/add-devcontainer.sh | bash
   ```

3. Review `.devcontainer/devcontainer.json` (edit if you want)

4. Commit and push:
   ```bash
   git add .devcontainer
   git commit -m "Add Codespace configuration for 4-core machine"
   git push
   ```

5. **Create Codespace** - it will use 4-core machine!

### For Quick Projects (Default Machines)

**If you're fine with 2-core** (default):

- Just create Codespace
- Your dotfiles still run (Claude Code, Flow, MCPs all installed)
- You just get smaller machine

---

## 📦 What Gets Installed Automatically

When you create ANY Codespace (with your dotfiles configured):

1. ✅ **Claude Code** - AI coding assistant
2. ✅ **Claude Flow** - Advanced AI workflow tools
3. ✅ **SuperClaude** - Enhanced Claude interface
4. ✅ **9 MCP Servers** (if you have API keys):
   - brave-search (web search)
   - fetch (scrape websites)
   - github (GitHub integration)
   - filesystem (file operations)
   - playwright (browser automation)
   - sequential-thinking (complex reasoning)
   - google-drive (Google Drive access)
   - huggingface (AI models)
   - mcp-installer (install more MCPs)

5. ✅ **Shell Configuration**:
   - Type `claude` → automatically runs with `--dangerously-skip-permissions`
   - Session resume enabled (conversations persist)
   - Auto-updates (once per day)

---

## 🎓 Student Workflow

**For your 4 students**, here's what they do:

### One-Time Setup (10 minutes)

1. **Fork your dotfiles repo**:
   - Go to: `https://github.com/stuinfla/dotfiles`
   - Click "Fork"
   - Creates their own copy

2. **Configure GitHub settings**:
   - Go to: https://github.com/settings/codespaces
   - Enable dotfiles: `THEIR_USERNAME/dotfiles`
   - Install command: `bash install.sh`

3. **Add API keys** (optional):
   - Codespaces secrets
   - Add `ANTHROPIC_API_KEY` (for Claude Code)
   - Add other keys if desired

### Every Project (30 seconds)

1. **Go to their project repository**

2. **Add devcontainer config** (for larger machines):
   ```bash
   curl -sSL https://raw.githubusercontent.com/stuinfla/dotfiles/main/add-devcontainer.sh | bash
   git add .devcontainer
   git commit -m "Add Codespace config"
   git push
   ```

3. **Create Codespace**:
   - Click "Code" → "Codespaces" → "Create codespace on main"
   - Wait 3-5 minutes
   - Everything is configured!

4. **Start coding**:
   ```bash
   # In the Codespace terminal:
   claude
   # Claude Code starts with all features enabled!
   ```

---

## ✅ Verification

**After creating your first Codespace**, verify everything works:

```bash
# Check installations
claude --version          # Should show Claude Code version
claude-flow --version     # Should show Claude Flow version
SuperClaude --version     # Should show SuperClaude version

# Check alias
type claude               # Should show it's a function

# Check session directory
ls -la ~/.claude-sessions # Should exist

# Check MCP configuration
cat ~/.claude.json        # Should show 9 MCP servers

# Test Claude Code
claude
# Should start without permission prompts!
```

---

## 🔧 Customization

### Change Machine Size

Edit `.devcontainer/devcontainer.json` in your project:

```json
{
  "hostRequirements": {
    "cpus": 8,        // Change to 2, 4, or 8
    "memory": "32gb", // Adjust accordingly
    "storage": "64gb"
  }
}
```

**Note**: 8-core machines may require GitHub approval for some accounts.

### Add VS Code Extensions

Edit `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "github.copilot",
        "github.copilot-chat",
        "ms-python.python",
        "eamodio.gitlens"
      ]
    }
  }
}
```

### Disable Auto-Skip Permissions

Edit `~/.bashrc` in dotfiles repo:

```bash
# Current (auto-skip):
claude() {
    command claude --dangerously-skip-permissions --session-dir "$CLAUDE_SESSION_DIR" "$@"
}

# Change to (require permissions):
claude() {
    command claude --session-dir "$CLAUDE_SESSION_DIR" "$@"
}
```

---

## 💰 Cost

**GitHub Free Tier**:
- 60 hours per month
- 2-core machines = 60 hours free
- 4-core machines = 30 hours free
- 8-core machines = 15 hours free

**Your setup** (4-core):
- 30 free hours per month
- More than enough for most development work
- Codespaces auto-stop after 30 minutes idle

---

## 🆘 Troubleshooting

### "Dotfiles didn't run!"

**Check**:
1. Go to: https://github.com/settings/codespaces
2. Verify dotfiles enabled
3. Verify repository is `YOUR_USERNAME/dotfiles`
4. Verify install command is `bash install.sh`

**Test**:
```bash
# In Codespace:
ls -la ~/.dotfiles  # Should exist
```

### "Claude command not found"

**Cause**: Installation failed or PATH not configured

**Fix**:
```bash
# Re-run dotfiles installation
bash ~/.dotfiles/install.sh

# Check if installed
command -v claude

# Add to PATH manually if needed
export PATH="$HOME/.npm-global/bin:$PATH"
```

### "Secrets not working"

**Check**:
1. Secrets configured at: https://github.com/settings/codespaces
2. Secrets are CODESPACE secrets (not repository secrets!)
3. Restart Codespace after adding secrets

**Test**:
```bash
# In Codespace:
echo $ANTHROPIC_API_KEY  # Should show your key
```

### "Machine size not changing"

**Cause**: `.devcontainer/devcontainer.json` not in repo or not committed

**Fix**:
```bash
# Make sure file exists
ls -la .devcontainer/devcontainer.json

# Make sure it's committed
git status

# If not committed:
git add .devcontainer
git commit -m "Add devcontainer config"
git push

# Delete old Codespace and create new one
```

---

## 📚 Files Explained

### In Your Dotfiles Repo

| File | Purpose |
|------|---------|
| `install.sh` | Installs Claude Code, Claude Flow, SuperClaude, MCPs |
| `.bashrc` | Shell configuration with `claude` alias |
| `.claude.json` | MCP server configuration |
| `add-devcontainer.sh` | Script to add machine size config to projects |
| `health-check.sh` | Verify everything is installed correctly |

### In Each Project (Optional)

| File | Purpose |
|------|---------|
| `.devcontainer/devcontainer.json` | Codespace machine size and extensions |

---

## 🎯 Quick Reference

### Setup Dotfiles (Once)
```bash
# 1. Fork https://github.com/stuinfla/dotfiles
# 2. Configure at: https://github.com/settings/codespaces
# 3. Add secrets (API keys) if desired
```

### Add to Project (Per Project)
```bash
curl -sSL https://raw.githubusercontent.com/stuinfla/dotfiles/main/add-devcontainer.sh | bash
git add .devcontainer && git commit -m "Add devcontainer" && git push
```

### Create Codespace
```bash
# Go to repo → Code → Codespaces → Create codespace
# Wait 3-5 minutes
# Everything configured automatically!
```

### Verify Setup
```bash
claude --version
claude-flow --version
cat ~/.claude.json
type claude
```

---

## ✨ What Your Students Get

**After setup, students can**:

1. Work on ANY project from ANY device (browser-based)
2. Get Claude Code + Claude Flow automatically
3. Have consistent environment across all projects
4. Choose machine size per project (2, 4, or 8-core)
5. Access their secrets (API keys) automatically
6. Resume Claude conversations between sessions

**Zero per-project hassle. One setup, works everywhere.**

---

## 📞 Support

**For You**:
- Dotfiles repo: `https://github.com/stuinfla/dotfiles`
- Settings: https://github.com/settings/codespaces
- Health check: `bash ~/.dotfiles/health-check.sh`

**For Students**:
- Same as above, but with their own usernames
- Share this guide with them
- They fork your repo and follow the same steps

---

**Questions?** Run `health-check.sh` in your Codespace to diagnose issues:

```bash
bash ~/.dotfiles/health-check.sh
```

This will show you exactly what's configured and what's missing.
