# Dotfiles Scripts

Utility scripts for managing and diagnosing the dotfiles installation.

## Available Scripts

### DSP Command Diagnostics

#### verify-dsp.sh
**Purpose**: Comprehensive diagnostic tool for DSP command issues

**Usage**:
```bash
bash scripts/verify-dsp.sh
```

**Checks**:
1. ✅ Claude Code installation and location
2. ✅ .bashrc configuration (dsp/DSP functions)
3. ✅ .bash_profile sourcing
4. ✅ Function availability in current shell
5. ✅ Environment variables (ANTHROPIC_CLAUDE_CODE_SKIP_PERMISSIONS, CLAUDE_CODE_SESSION_DIR)
6. ✅ Session directory existence

**Output**: Detailed diagnostic report with actionable recommendations

---

#### test-dsp.sh
**Purpose**: Quick verification that DSP command works

**Usage**:
```bash
bash scripts/test-dsp.sh
```

**Tests**:
- dsp function availability
- DSP (uppercase) function availability  
- Version command execution

**Output**: Quick pass/fail with version info

---

### Auto-Update Scripts

#### auto-update.sh
**Purpose**: Daily automatic updates for development tools

**Runs Automatically**: On every new terminal session (background, non-blocking)

**Updates**:
- Claude Code CLI
- SuperClaude framework
- Claude Flow MCP server
- VS Code extensions (Codespaces only)

**Manual Run**:
```bash
bash ~/.dotfiles/scripts/auto-update.sh
```

---

#### auto-git-save.sh
**Purpose**: Automatic git commit and push every 5 minutes

**Runs Automatically**: On every new terminal session (background, non-blocking)

**Features**:
- Commits changes every 5 minutes
- Pushes to remote repository
- Adds "[AUTO-SAVE]" prefix to commit messages
- Shows notification with file count

**Manual Run**:
```bash
bash ~/.dotfiles/scripts/auto-git-save.sh
```

**Stop Auto-Save**:
```bash
pkill -f auto-git-save
```

---

### Installation Scripts

#### capture-codespace-screenshots.js
**Purpose**: Playwright script to capture Codespace UI screenshots

**Usage**:
```bash
node scripts/capture-codespace-screenshots.js
```

**Output**: Screenshots in `validation-screenshots/` directory

---

#### status-update.sh
**Purpose**: Update status messages during installation

**Usage**: Called internally by install.sh

---

#### test-status-visibility.sh
**Purpose**: Test installation status visibility

**Usage**:
```bash
bash scripts/test-status-visibility.sh
```

---

## Script Locations

All scripts are in `/scripts` directory:

```
scripts/
├── README.md                          # This file
├── verify-dsp.sh                     # DSP diagnostics
├── test-dsp.sh                       # Quick DSP test
├── auto-update.sh                    # Daily updates
├── auto-git-save.sh                  # Auto commit/push
├── capture-codespace-screenshots.js  # Screenshot capture
├── status-update.sh                  # Installation status
└── test-status-visibility.sh        # Status visibility test
```

## Common Use Cases

### Troubleshooting DSP Command

**Problem**: "command not found: dsp"

**Solution**:
```bash
bash scripts/verify-dsp.sh   # Diagnose issue
source ~/.bashrc              # Reload configuration
bash scripts/test-dsp.sh     # Verify fix
```

---

### Checking Auto-Update Status

```bash
# Check if auto-update is running
ps aux | grep auto-update

# View auto-update log
tail -f ~/.cache/auto-update.log
```

---

### Manual Updates

```bash
# Update all tools manually
bash ~/.dotfiles/scripts/auto-update.sh

# Update just Claude Code
npm update -g @anthropic-ai/claude-code

# Update SuperClaude
pip install --upgrade SuperClaude
```

---

### Managing Auto-Save

```bash
# Check auto-save status
ps aux | grep auto-git-save

# Stop auto-save
pkill -f auto-git-save

# Start auto-save manually
bash ~/.dotfiles/scripts/auto-git-save.sh &
```

---

## Development

### Adding New Scripts

1. Create script in `/scripts` directory
2. Make executable: `chmod +x scripts/your-script.sh`
3. Document in this README
4. Test thoroughly before committing

### Script Guidelines

- **Idempotent**: Safe to run multiple times
- **Non-destructive**: Don't delete user data
- **Error handling**: Check prerequisites
- **User feedback**: Clear status messages
- **Background-safe**: Don't block terminal if running in background

---

## Maintenance

### Cleanup Old Logs

```bash
# Clean auto-update logs older than 7 days
find ~/.cache -name "auto-update*.log" -mtime +7 -delete

# Clean old session files
find ~/.claude-sessions -name "*.json" -mtime +30 -delete
```

---

## Troubleshooting

### Script Won't Run

```bash
# Make executable
chmod +x scripts/script-name.sh

# Check for syntax errors
bash -n scripts/script-name.sh
```

### Background Script Stuck

```bash
# Find process
ps aux | grep script-name

# Kill process
pkill -f script-name
```

### Diagnostic Output

All diagnostic scripts save output to:
- `~/.cache/auto-update.log` - Auto-update logs
- `~/.cache/dotfiles_summary` - Installation summary
- `~/.cache/dotfiles_just_installed` - First-run flag

---

**Quick Reference:**

| Script | Purpose | Usage |
|--------|---------|-------|
| `verify-dsp.sh` | DSP diagnostics | `bash scripts/verify-dsp.sh` |
| `test-dsp.sh` | Quick DSP test | `bash scripts/test-dsp.sh` |
| `auto-update.sh` | Daily updates | Automatic (or manual) |
| `auto-git-save.sh` | Auto commit/push | Automatic (or manual) |
| `capture-codespace-screenshots.js` | Screenshot capture | `node scripts/capture-codespace-screenshots.js` |
