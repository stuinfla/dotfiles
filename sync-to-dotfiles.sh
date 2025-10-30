#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ATOMIC SYNC TO DOTFILES - Enhanced with safety checks and validation
# ═══════════════════════════════════════════════════════════════════
#
# This script ensures COMPLETE synchronization by:
# 1. Validating environment and prerequisites
# 2. Wiping everything in dotfiles repo (except .git)
# 3. Copying ALL production files from dotfiles-installer-1
# 4. Verifying sync with checksums
# 5. Providing rollback capability if needed
#
# Usage:
#   ./sync-to-dotfiles.sh              # Normal sync
#   ./sync-to-dotfiles.sh --verify     # Check status only
#   ./sync-to-dotfiles.sh --dry-run    # Show what would be done
#   ./sync-to-dotfiles.sh --rollback   # Restore from backup
#
# ═══════════════════════════════════════════════════════════════════

set -e

INSTALLER_DIR="/Users/stuartkerr/Code/dotfiles-installer-1"
DOTFILES_DIR="/Users/stuartkerr/Code/dotfiles"
BACKUP_DIR="/tmp/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
CHECKSUM_FILE="/tmp/dotfiles-sync-checksums.txt"
LOG_FILE="/tmp/dotfiles-sync.log"

# Mode flags
DRY_RUN=false
VERIFY_ONLY=false
ROLLBACK=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verify)
            VERIFY_ONLY=true
            shift
            ;;
        --rollback)
            ROLLBACK=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--verify] [--rollback] [-v|--verbose]"
            exit 1
            ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

verbose_log() {
    if [ "$VERBOSE" = true ]; then
        log "$1"
    fi
}

error() {
    log "❌ ERROR: $1"
    exit 1
}

check_network() {
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

check_git_credentials() {
    cd "$DOTFILES_DIR"
    if ! git ls-remote origin >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

calculate_checksums() {
    local dir="$1"
    local output_file="$2"

    cd "$dir"
    find . -type f ! -path "./.git/*" ! -path "./.swarm/*" ! -path "./.claude-flow/*" -exec md5 {} \; | sort > "$output_file"
}

compare_checksums() {
    local source_checksums="$1"
    local dest_checksums="$2"

    if diff -q "$source_checksums" "$dest_checksums" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

should_skip() {
    local item="$1"

    # Skip patterns
    local skip_patterns=(
        "node_modules"
        "playwright-screenshots"
        "validation-screenshots"
        "docs"
        "templates"
        "package.json"
        "package-lock.json"
        ".DS_Store"
        "*.log"
        "*.tmp"
    )

    for pattern in "${skip_patterns[@]}"; do
        if [[ "$item" == $pattern ]]; then
            return 0
        fi
    done

    # Skip test files (but keep README.md)
    if [[ "$item" == *test*.js ]] || [[ "$item" == *test*.json ]]; then
        return 0
    fi

    if [[ "$item" == *.md ]] && [[ "$item" != "README.md" ]]; then
        return 0
    fi

    return 1
}

# ═══════════════════════════════════════════════════════════════════
# MAIN FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

perform_rollback() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                         ROLLBACK MODE                              ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""

    # Find most recent backup
    local latest_backup=$(ls -td /tmp/dotfiles-backup-* 2>/dev/null | head -1)

    if [ -z "$latest_backup" ]; then
        error "No backup found to restore from"
    fi

    log "Found backup: $latest_backup"
    read -p "Restore from this backup? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log "Rollback cancelled"
        exit 0
    fi

    cd "$DOTFILES_DIR"

    # Wipe current state (except .git)
    log "Wiping current dotfiles state..."
    find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} \;

    # Restore from backup
    log "Restoring from backup..."
    cp -r "$latest_backup"/* "$DOTFILES_DIR/"

    log "✅ Rollback complete!"
    git status
    exit 0
}

verify_sync_status() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                       VERIFY SYNC STATUS                          ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""

    log "Calculating checksums..."

    local source_checksums="/tmp/source-checksums.txt"
    local dest_checksums="/tmp/dest-checksums.txt"

    calculate_checksums "$INSTALLER_DIR" "$source_checksums"
    calculate_checksums "$DOTFILES_DIR" "$dest_checksums"

    if compare_checksums "$source_checksums" "$dest_checksums"; then
        log "✅ Repos are in sync!"
        log ""
        log "File count comparison:"
        log "  Source: $(wc -l < "$source_checksums") files"
        log "  Dest:   $(wc -l < "$dest_checksums") files"
    else
        log "⚠️  Repos are OUT OF SYNC!"
        log ""
        log "Differences detected:"
        diff "$source_checksums" "$dest_checksums" || true
    fi

    # Check git status
    log ""
    log "Git status in dotfiles repo:"
    cd "$DOTFILES_DIR"
    git status --short

    exit 0
}

perform_sync() {
    local is_dry_run=$1

    if [ "$is_dry_run" = true ]; then
        echo ""
        echo "╔═══════════════════════════════════════════════════════════════════╗"
        echo "║                         DRY RUN MODE                              ║"
        echo "║                    (No changes will be made)                      ║"
        echo "╚═══════════════════════════════════════════════════════════════════╝"
        echo ""
    else
        echo ""
        echo "╔═══════════════════════════════════════════════════════════════════╗"
        echo "║                  ATOMIC SYNC TO DOTFILES REPO                     ║"
        echo "║                  (Wipe + Rebuild Strategy)                        ║"
        echo "╚═══════════════════════════════════════════════════════════════════╝"
        echo ""
    fi

    # ═══════════════════════════════════════════════════════════════════
    # 1. VALIDATE ENVIRONMENT
    # ═══════════════════════════════════════════════════════════════════

    log "Step 1: Validating environment..."

    if [ ! -d "$INSTALLER_DIR" ]; then
        error "Installer directory not found: $INSTALLER_DIR"
    fi
    verbose_log "  ✅ Installer directory exists"

    if [ ! -d "$DOTFILES_DIR" ]; then
        error "Dotfiles directory not found: $DOTFILES_DIR"
    fi
    verbose_log "  ✅ Dotfiles directory exists"

    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        error "Dotfiles directory is not a git repo: $DOTFILES_DIR"
    fi
    verbose_log "  ✅ Dotfiles has .git directory"

    # Check for symbolic links
    if [ -L "$DOTFILES_DIR" ] || [ -L "$INSTALLER_DIR" ]; then
        log "⚠️  WARNING: One or both directories are symbolic links"
        log "  This may cause unexpected behavior"
    fi

    log "✅ Environment validation passed"
    log ""

    # ═══════════════════════════════════════════════════════════════════
    # 2. CHECK NETWORK AND GIT CREDENTIALS
    # ═══════════════════════════════════════════════════════════════════

    log "Step 2: Checking network and git credentials..."

    if ! check_network; then
        log "⚠️  WARNING: No network connectivity to github.com"
        log "  Push operations may fail after sync"
    else
        verbose_log "  ✅ Network connectivity OK"
    fi

    if ! check_git_credentials; then
        log "⚠️  WARNING: Git credentials check failed"
        log "  You may need to authenticate before pushing"
    else
        verbose_log "  ✅ Git credentials OK"
    fi

    log "✅ Network checks complete"
    log ""

    # ═══════════════════════════════════════════════════════════════════
    # 3. CHECK FOR UNCOMMITTED CHANGES
    # ═══════════════════════════════════════════════════════════════════

    log "Step 3: Checking for uncommitted changes..."

    cd "$DOTFILES_DIR"
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log "⚠️  WARNING: Dotfiles repo has uncommitted changes!"
        log ""
        git status --short | tee -a "$LOG_FILE"
        log ""

        if [ "$is_dry_run" = false ]; then
            read -p "Wipe anyway? This will DELETE uncommitted changes! (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                error "Aborted. Commit or stash your changes first."
            fi
        fi
    else
        log "✅ No uncommitted changes"
    fi
    log ""

    # ═══════════════════════════════════════════════════════════════════
    # 4. CREATE BACKUP
    # ═══════════════════════════════════════════════════════════════════

    if [ "$is_dry_run" = false ]; then
        log "Step 4: Creating backup..."
        mkdir -p "$BACKUP_DIR"

        cd "$DOTFILES_DIR"
        find . -maxdepth 1 ! -name '.git' ! -name '.' -exec cp -r {} "$BACKUP_DIR/" \;

        log "✅ Backup created: $BACKUP_DIR"
        log ""
    fi

    # ═══════════════════════════════════════════════════════════════════
    # 5. WIPE DOTFILES REPO
    # ═══════════════════════════════════════════════════════════════════

    log "Step 5: Wiping dotfiles repo (keeping .git only)..."

    if [ "$is_dry_run" = false ]; then
        cd "$DOTFILES_DIR"
        find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} \;
        log "✅ Dotfiles repo wiped clean"
    else
        log "  [DRY RUN] Would wipe all files except .git"
    fi
    log ""

    # ═══════════════════════════════════════════════════════════════════
    # 6. COPY FILES FROM INSTALLER
    # ═══════════════════════════════════════════════════════════════════

    log "Step 6: Copying files from installer repo..."
    log ""

    cd "$INSTALLER_DIR"
    local file_count=0

    # Copy dotfiles (files starting with .)
    for file in .[^.]*; do
        if [ "$file" != ".git" ] && [ "$file" != ".swarm" ] && [ "$file" != ".claude-flow" ]; then
            if [ "$is_dry_run" = false ]; then
                cp -r "$file" "$DOTFILES_DIR/"
            fi
            log "  ✅ $file"
            ((file_count++))
        fi
    done

    # Copy regular files and directories
    for item in *; do
        if ! should_skip "$item"; then
            if [ "$is_dry_run" = false ]; then
                # Handle symbolic links specially
                if [ -L "$item" ]; then
                    log "  ⚠️  Skipping symbolic link: $item"
                    continue
                fi

                cp -r "$item" "$DOTFILES_DIR/"
            fi
            log "  ✅ $item"
            ((file_count++))
        else
            verbose_log "  ⏭️  Skipped: $item"
        fi
    done

    log ""
    log "✅ Copied $file_count items"
    log ""

    # ═══════════════════════════════════════════════════════════════════
    # 7. VERIFY WITH CHECKSUMS
    # ═══════════════════════════════════════════════════════════════════

    log "Step 7: Verifying sync with checksums..."

    if [ "$is_dry_run" = false ]; then
        local source_checksums="/tmp/source-checksums.txt"
        local dest_checksums="/tmp/dest-checksums.txt"

        calculate_checksums "$INSTALLER_DIR" "$source_checksums"
        calculate_checksums "$DOTFILES_DIR" "$dest_checksums"

        # Save for later verification
        cp "$dest_checksums" "$CHECKSUM_FILE"

        if compare_checksums "$source_checksums" "$dest_checksums"; then
            log "✅ Checksum verification passed!"
        else
            log "❌ Checksum verification FAILED!"
            log "Differences detected - this may indicate:"
            log "  - File permission issues"
            log "  - Symbolic link handling problems"
            log "  - Copy errors"
            log ""
            log "Run with --verify to see detailed differences"

            read -p "Continue anyway? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log "Performing automatic rollback..."
                cd "$DOTFILES_DIR"
                find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} \;
                cp -r "$BACKUP_DIR"/* "$DOTFILES_DIR/"
                error "Sync failed and rolled back"
            fi
        fi
    else
        log "  [DRY RUN] Would verify checksums after copy"
    fi
    log ""

    # ═══════════════════════════════════════════════════════════════════
    # 8. CHECK TIMESTAMPS
    # ═══════════════════════════════════════════════════════════════════

    log "Step 8: Checking file timestamps..."

    cd "$DOTFILES_DIR"
    TIMESTAMPS=$(find . -maxdepth 2 -type f ! -path "./.git/*" -exec stat -f "%Sm" -t "%Y-%m-%d %H:%M" {} \; | sort -u)
    TIMESTAMP_COUNT=$(echo "$TIMESTAMPS" | wc -l | tr -d ' ')

    if [ "$TIMESTAMP_COUNT" -eq 1 ]; then
        log "✅ Perfect! All files have identical timestamp:"
        log "   $TIMESTAMPS"
    else
        log "⚠️  WARNING: Files have different timestamps:"
        echo "$TIMESTAMPS" | tee -a "$LOG_FILE"
        log ""
        log "This shouldn't happen with atomic sync."
    fi
    log ""

    # ═══════════════════════════════════════════════════════════════════
    # 9. SHOW GIT STATUS
    # ═══════════════════════════════════════════════════════════════════

    log "════════════════════════════════════════════════════════════════════"
    log "  📊 Git Status in Dotfiles Repo"
    log "════════════════════════════════════════════════════════════════════"
    log ""

    cd "$DOTFILES_DIR"
    git status | tee -a "$LOG_FILE"

    log ""
    log "════════════════════════════════════════════════════════════════════"

    if [ "$is_dry_run" = true ]; then
        log "  ✅ DRY RUN COMPLETE - No changes made"
    else
        log "  ✅ ATOMIC SYNC COMPLETE!"
    fi

    log "════════════════════════════════════════════════════════════════════"
    log ""
    log "Sync summary:"
    log "  Files copied: $file_count"
    log "  Backup saved: $BACKUP_DIR"
    log "  Log saved: $LOG_FILE"
    log "  Checksums: $CHECKSUM_FILE"
    log ""

    if [ "$is_dry_run" = false ]; then
        log "🚀 Next Steps:"
        log ""
        log "  cd $DOTFILES_DIR"
        log "  git add -A"
        log "  git commit -m \"ATOMIC SYNC: Wipe and rebuild from dotfiles-installer\""
        log "  git push origin main"
        log ""
        log "To verify the sync later:"
        log "  ./sync-to-dotfiles.sh --verify"
        log ""
        log "If something went wrong:"
        log "  ./sync-to-dotfiles.sh --rollback"
        log ""
    fi
}

# ═══════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

# Initialize log
echo "Sync started at $(date)" > "$LOG_FILE"

# Route to appropriate function
if [ "$ROLLBACK" = true ]; then
    perform_rollback
elif [ "$VERIFY_ONLY" = true ]; then
    verify_sync_status
else
    perform_sync "$DRY_RUN"
fi
