# ═══════════════════════════════════════════════════════════════════
# BASH PROFILE - Loads .bashrc on login
# ═══════════════════════════════════════════════════════════════════

# Load .bashrc if it exists (required for dsp/DSP commands)
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
elif [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# Also check for alternative bashrc location (dotfiles installation)
if [ -f "$HOME/.dotfiles/.bashrc" ]; then
    . "$HOME/.dotfiles/.bashrc"
fi
