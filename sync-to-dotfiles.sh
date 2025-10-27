#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ATOMIC SYNC TO DOTFILES - Wipe and rebuild dotfiles repo cleanly
# ═══════════════════════════════════════════════════════════════════
#
# This script ensures COMPLETE synchronization by:
# 1. Wiping everything in dotfiles repo (except .git)
# 2. Copying ALL production files from dotfiles-installer-1
# 3. Result: All files have identical timestamp = truly synchronized
#
# Why atomic sync matters:
# - GitHub Codespaces uses the dotfiles repo
# - Piecemeal updates cause files from different days (confusing!)
# - Atomic sync = one snapshot, one moment in time
#
# ═══════════════════════════════════════════════════════════════════

set -e

INSTALLER_DIR="/Users/stuartkerr/Code/dotfiles-installer-1"
DOTFILES_DIR="/Users/stuartkerr/Code/dotfiles"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                  ATOMIC SYNC TO DOTFILES REPO                     ║"
echo "║                  (Wipe + Rebuild Strategy)                        ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════════
# 1. VALIDATE
# ═══════════════════════════════════════════════════════════════════

if [ ! -d "$INSTALLER_DIR" ]; then
    echo "❌ ERROR: Installer directory not found: $INSTALLER_DIR"
    exit 1
fi

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "❌ ERROR: Dotfiles directory not found: $DOTFILES_DIR"
    exit 1
fi

if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "❌ ERROR: Dotfiles directory is not a git repo: $DOTFILES_DIR"
    exit 1
fi

echo "✅ Both repos exist and dotfiles has .git directory"
echo ""

# ═══════════════════════════════════════════════════════════════════
# 2. CHECK FOR UNCOMMITTED CHANGES (Safety Check)
# ═══════════════════════════════════════════════════════════════════

cd "$DOTFILES_DIR"
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠️  WARNING: Dotfiles repo has uncommitted changes!"
    echo ""
    git status --short
    echo ""
    read -p "Wipe anyway? This will DELETE uncommitted changes! (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Aborted. Commit or stash your changes first."
        exit 1
    fi
fi

# ═══════════════════════════════════════════════════════════════════
# 3. WIPE EVERYTHING (Except .git)
# ═══════════════════════════════════════════════════════════════════

echo "🗑️  Wiping dotfiles repo (keeping .git only)..."
echo ""

cd "$DOTFILES_DIR"
find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} \;

echo "✅ Dotfiles repo wiped clean"
echo ""

# ═══════════════════════════════════════════════════════════════════
# 4. COPY ALL FILES FROM INSTALLER
# ═══════════════════════════════════════════════════════════════════

echo "📦 Copying ALL files from installer repo..."
echo ""

cd "$INSTALLER_DIR"

# Copy all dotfiles (files starting with .)
for file in .[^.]*; do
    if [ "$file" != ".git" ] && [ "$file" != ".swarm" ] && [ "$file" != ".claude-flow" ]; then
        cp -r "$file" "$DOTFILES_DIR/"
        echo "  ✅ $file"
    fi
done

# Copy all regular files and directories
for item in *; do
    # Skip test files, node_modules, screenshots, docs, templates
    if [ "$item" != "node_modules" ] && \
       [ "$item" != "playwright-screenshots" ] && \
       [ "$item" != "docs" ] && \
       [ "$item" != "templates" ] && \
       [ "$item" != "package.json" ] && \
       [ "$item" != "package-lock.json" ] && \
       [[ "$item" != *test*.js ]] && \
       [[ "$item" != *test*.json ]] && \
       [[ "$item" != *.md ]] || \
       [ "$item" = "README.md" ]; then
        cp -r "$item" "$DOTFILES_DIR/"
        echo "  ✅ $item"
    fi
done

echo ""
echo "✅ All production files copied"
echo ""

# ═══════════════════════════════════════════════════════════════════
# 5. VERIFY SYNCHRONIZATION
# ═══════════════════════════════════════════════════════════════════

echo "🔍 Verifying all files have same timestamp..."
echo ""

cd "$DOTFILES_DIR"
TIMESTAMPS=$(find . -maxdepth 2 -type f ! -path "./.git/*" -exec stat -f "%Sm" -t "%Y-%m-%d %H:%M" {} \; | sort -u)
TIMESTAMP_COUNT=$(echo "$TIMESTAMPS" | wc -l | tr -d ' ')

if [ "$TIMESTAMP_COUNT" -eq 1 ]; then
    echo "✅ Perfect! All files have identical timestamp:"
    echo "   $TIMESTAMPS"
    echo ""
else
    echo "⚠️  WARNING: Files have different timestamps:"
    echo "$TIMESTAMPS"
    echo ""
    echo "This shouldn't happen with atomic sync. Continuing anyway..."
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════
# 6. SHOW GIT STATUS
# ═══════════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════════"
echo "  📊 Git Status in Dotfiles Repo"
echo "════════════════════════════════════════════════════════════════════"
echo ""

git status

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "  ✅ ATOMIC SYNC COMPLETE!"
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "All files synchronized at: $TIMESTAMPS"
echo ""
echo "🚀 Next Steps:"
echo ""
echo "  cd $DOTFILES_DIR"
echo "  git add -A"
echo "  git commit -m \"ATOMIC SYNC: Wipe and rebuild from dotfiles-installer\""
echo "  git push origin main"
echo ""
echo "OR use the quick commit helper:"
echo ""
echo "  ./sync-to-dotfiles.sh --commit \"Your commit message\""
echo ""
