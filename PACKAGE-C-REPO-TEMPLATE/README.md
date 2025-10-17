# PACKAGE-C: Repository Template for 4-Core Codespaces

## Purpose

Copy this `.devcontainer/` directory to ANY repository where you want 4-core codespaces instead of the default 2-core machines.

## Why This Exists

**Important**: Dotfiles cannot control machine specifications for other repositories. Each repository needs its own `.devcontainer/devcontainer.json` to request specific machine types.

- **Dotfiles CAN control**: Software installation, shell config, user preferences
- **Dotfiles CANNOT control**: Machine specs (CPU, RAM, storage) for other repos

## How to Use

### Option 1: Copy to a Single Repository

```bash
# In your target repository
cp -r /path/to/PACKAGE-C-REPO-TEMPLATE/.devcontainer .
git add .devcontainer/
git commit -m "Add 4-core devcontainer configuration"
git push
```

### Option 2: Copy to Multiple Repositories

```bash
# For each repository you want to upgrade:
cd /path/to/your-repo
cp -r /path/to/PACKAGE-C-REPO-TEMPLATE/.devcontainer .
git add .devcontainer/
git commit -m "Add 4-core devcontainer configuration"
git push
```

### Option 3: Use GitHub CLI (Bulk Update)

```bash
# Example script to add to multiple repos
for repo in repo1 repo2 repo3; do
  gh repo clone yourusername/$repo
  cd $repo
  cp -r /path/to/PACKAGE-C-REPO-TEMPLATE/.devcontainer .
  git add .devcontainer/
  git commit -m "Add 4-core devcontainer configuration"
  git push
  cd ..
done
```

## What This Provides

- **4-core CPU** (instead of default 2-core)
- **16GB RAM** (instead of default 8GB)
- **32GB storage** (instead of default 20GB)
- **GitHub CLI** installed
- **Node.js LTS** installed
- **Python 3.11** installed

## Customization

Edit `.devcontainer/devcontainer.json` to customize:

- **Features**: Add/remove language runtimes, tools
- **Extensions**: Add VS Code extensions in `customizations.vscode.extensions`
- **Ports**: Modify `forwardPorts` for your application
- **Resources**: Adjust CPU, memory, storage in `hostRequirements`

## Notes

- The first time you create a codespace in a repository with this config, it will use 4 cores
- Existing codespaces will continue using their current specs until rebuilt
- To rebuild an existing codespace: `gh codespace rebuild`

## Example Repositories

Examples of repositories that should have this:
- `tmobile-smart-quote-optimizer` ← Currently using default 2-core
- `bwe-evoting` ← Could benefit from 4-core
- Any development repository where you want better performance
