# Installation Timeout Fixes

## Problem Analysis

The installation script was hanging indefinitely during package installations, particularly:
- npm packages (Claude Code, Claude Flow, MCP servers)
- pip packages (SuperClaude)
- GitHub CLI operations (codespace renaming)

## Root Causes

1. **No timeout enforcement** - Commands could hang forever
2. **No progress feedback** - Users couldn't tell if installation was stuck
3. **No heartbeat monitoring** - Silent failures looked like hangs
4. **Poor background job handling** - Parallel installs had no monitoring
5. **No emergency kill switch** - Script could run indefinitely

## Implemented Fixes

### 1. `run_with_timeout()` Wrapper Function

**Location**: Lines 110-155

**What it does**:
- Wraps ANY command with timeout + heartbeat monitoring
- Shows "Still working..." every 10 seconds
- Kills command if it exceeds timeout
- Returns proper exit codes

**Usage**:
```bash
# Before (could hang forever)
npm install -g package@latest --force

# After (guaranteed to timeout or complete)
run_with_timeout 300 "npm install -g package@latest --force"
```

### 2. All External Commands Now Use Timeouts

**Modified locations**:
- Line 366: Claude Code installation
- Line 380-386: SuperClaude installation (pipx/pip)
- Line 395: SuperClaude setup
- Line 401: Claude Flow installation
- Line 408: Claude Flow init
- Line 417: Claude Flow MCP registration
- Line 526: npm package installer function
- Line 542: pip package installer function
- Line 704: GitHub codespace rename

**Flags added**:
- `--progress=false` - Disables npm interactive progress
- `--loglevel=error` - Reduces npm verbosity
- `--no-input` - Prevents pip from prompting
- `--force` - Non-interactive mode

### 3. Emergency Timeout Watcher

**Location**: Lines 248-282

**What it does**:
- Monitors entire script execution
- Kills script after 15 minutes (900 seconds)
- Updates visible status file
- Shows clear error message

**Behavior**:
```
Minute 1-14: Silent background monitoring
Minute 15: "🚨 EMERGENCY TIMEOUT" + kills script
```

### 4. Parallel Job Heartbeat Monitoring

**Location**: Lines 577-607

**What it does**:
- Monitors 4 parallel MCP installations
- Shows progress every 15 seconds
- Maximum 10 minutes for all parallel jobs
- Counts completed jobs (1/4, 2/4, 3/4, 4/4)

**Output**:
```
Parallel installs in progress... (2/4 complete)
Still working... (45s elapsed, max 600s)
```

### 5. Enhanced Cleanup & Ctrl+C Handling

**Location**: Lines 214-242

**What it does**:
- Traps EXIT, INT (Ctrl+C), TERM signals
- Kills all background processes (TERM then KILL)
- Updates visible status file on interruption
- Enables job control for proper Ctrl+C

**Signals handled**:
- `EXIT`: Normal script exit
- `INT`: User presses Ctrl+C
- `TERM`: External termination signal

### 6. Detailed Progress Logging

**Throughout script**:
- Every operation logs what command is running
- Heartbeat messages every 10 seconds
- Visible status updates in workspace file
- Clear timeout/error messages

## Testing Recommendations

### Test 1: Normal Installation
```bash
# Should complete in 3-5 minutes
./install.sh
```

**Expected**:
- No hangs
- Progress updates every 10-15 seconds
- Completion message

### Test 2: Slow Network Simulation
```bash
# Throttle network and test timeouts
tc qdisc add dev eth0 root netem delay 2000ms
./install.sh
```

**Expected**:
- Heartbeat messages appear
- Operations timeout after 5 minutes per package
- Script continues or exits gracefully

### Test 3: Ctrl+C Interrupt
```bash
./install.sh
# Press Ctrl+C after 30 seconds
```

**Expected**:
- Immediate response to Ctrl+C
- All background processes killed
- Status file updated with interruption message

### Test 4: Emergency Timeout
```bash
# Modify SCRIPT_TIMEOUT to 60 for quick testing
SCRIPT_TIMEOUT=60 ./install.sh
```

**Expected**:
- Script killed after 60 seconds
- Emergency timeout message displayed
- Status file updated

## Timeout Configuration

**Current settings** (lines 94-98):
```bash
PACKAGE_TIMEOUT=300    # 5 minutes per package
SCRIPT_TIMEOUT=900     # 15 minutes total
```

**Adjustable for testing**:
```bash
# Quick test (aggressive timeouts)
PACKAGE_TIMEOUT=30 SCRIPT_TIMEOUT=120 ./install.sh

# Patient installation (relaxed timeouts)
PACKAGE_TIMEOUT=600 SCRIPT_TIMEOUT=1800 ./install.sh
```

## Monitoring Installation Progress

### 1. Real-time Log
```bash
tail -f /tmp/dotfiles-install.log
```

### 2. Visible Status File
```bash
cat /workspaces/*/DOTFILES-INSTALLATION-STATUS.txt
```

### 3. Background Processes
```bash
ps aux | grep -E 'npm|pip|claude'
```

## Troubleshooting Hangs

### If installation appears stuck:

1. **Check log file**:
   ```bash
   tail -n 50 /tmp/dotfiles-install.log
   ```

2. **Check what's running**:
   ```bash
   ps aux | grep install.sh
   ps aux | grep -E 'npm|pip'
   ```

3. **Manual timeout**:
   ```bash
   # Find install.sh PID
   ps aux | grep install.sh

   # Kill it
   kill -TERM <PID>
   ```

4. **Check status file**:
   ```bash
   cat /workspaces/*/DOTFILES-INSTALLATION-STATUS.txt
   ```

## Files Modified

1. `/Users/stuartkerr/Code/dotfiles/install.sh`
   - Added `run_with_timeout()` function
   - Wrapped all external commands
   - Enhanced cleanup trap
   - Added emergency timeout
   - Added parallel job monitoring

## Performance Impact

- **Overhead**: ~1-2 seconds per operation (heartbeat processes)
- **Safety**: Prevents infinite hangs
- **Visibility**: Users know script is working
- **Reliability**: Guaranteed completion or timeout

## Future Improvements

1. **Retry logic**: Automatically retry failed operations
2. **Exponential backoff**: For network-related failures
3. **Smart timeout adjustment**: Based on network speed
4. **Progress bars**: Visual progress for long operations
5. **Checkpoint recovery**: Resume from failed step
