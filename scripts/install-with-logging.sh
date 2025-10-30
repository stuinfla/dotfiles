#!/bin/bash

# Example: install.sh integrated with enhanced logging
# This demonstrates how to use the logging system in the main installer

# ==============================================================================
# SETUP
# ==============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the logging system
# shellcheck source=scripts/enhanced-logging.sh
source "${SCRIPT_DIR}/enhanced-logging.sh"

# Record start time
START_TIME=$(date +%s)
export START_TIME

# Initialize logging
init_logging

# Set trap for cleanup on exit
trap finalize_logging EXIT

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install package with error handling
install_package() {
    local package="$1"

    start_operation "Installing $package"

    if command_exists "$package"; then
        log_info "$package is already installed"
        complete_operation "Installing $package"
        return 0
    fi

    if safe_execute "brew install $package" "Package installation"; then
        complete_operation "Installing $package"
        return 0
    else
        fail_operation "Installing $package" "Homebrew installation failed"
        catch_error "Failed to install $package" "Try running: brew install $package manually"
        return 1
    fi
}

# Create symlink with error handling
create_symlink() {
    local source="$1"
    local target="$2"

    start_operation "Creating symlink: $target"

    # Check if source exists
    if [[ ! -e "$source" ]]; then
        fail_operation "Creating symlink: $target" "Source file does not exist: $source"
        return 1
    fi

    # Backup existing target
    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
        log_warn "Target exists, backing up to: $backup"
        if ! mv "$target" "$backup"; then
            fail_operation "Creating symlink: $target" "Failed to backup existing file"
            return 1
        fi
    fi

    # Remove existing symlink
    if [[ -L "$target" ]]; then
        log_debug "Removing existing symlink: $target"
        rm -f "$target"
    fi

    # Create symlink
    if ln -s "$source" "$target"; then
        complete_operation "Creating symlink: $target"
        return 0
    else
        fail_operation "Creating symlink: $target" "Failed to create symlink"
        return 1
    fi
}

# ==============================================================================
# MAIN INSTALLATION STEPS
# ==============================================================================

main() {
    log_info "Starting dotfiles installation"
    log_debug "Running on: $(uname -s)"

    # Step 1: Check Homebrew
    start_operation "Checking Homebrew"
    if command_exists brew; then
        log_info "Homebrew is installed"
        complete_operation "Checking Homebrew"
    else
        log_warn "Homebrew not found"
        fail_operation "Checking Homebrew" "Homebrew must be installed first"
        catch_error "Homebrew not found" "Install from https://brew.sh"
        return 1
    fi

    # Step 2: Install packages
    log_info "Installing required packages"

    local packages=(
        "git"
        "zsh"
        "tmux"
        "neovim"
    )

    local failed_packages=()

    for package in "${packages[@]}"; do
        if ! install_package "$package"; then
            failed_packages+=("$package")
        fi
    done

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "Failed to install: ${failed_packages[*]}"
    fi

    # Step 3: Create dotfiles symlinks
    log_info "Creating configuration symlinks"

    local dotfiles_dir="${HOME}/.dotfiles"

    if [[ ! -d "$dotfiles_dir" ]]; then
        log_error "Dotfiles directory not found: $dotfiles_dir"
        catch_error "Missing dotfiles directory" "Clone your dotfiles repository first"
        return 1
    fi

    # Example symlinks
    create_symlink "${dotfiles_dir}/.zshrc" "${HOME}/.zshrc"
    create_symlink "${dotfiles_dir}/.tmux.conf" "${HOME}/.tmux.conf"
    create_symlink "${dotfiles_dir}/.config/nvim" "${HOME}/.config/nvim"

    # Step 4: Final verification
    start_operation "Verifying installation"

    local verification_failed=false

    if [[ ! -L "${HOME}/.zshrc" ]]; then
        log_error ".zshrc symlink not created"
        verification_failed=true
    fi

    if [[ ! -L "${HOME}/.tmux.conf" ]]; then
        log_error ".tmux.conf symlink not created"
        verification_failed=true
    fi

    if [[ "$verification_failed" == true ]]; then
        fail_operation "Verifying installation" "Some symlinks were not created"
        return 1
    else
        complete_operation "Verifying installation"
    fi

    log_info "Installation completed successfully!"
    return 0
}

# ==============================================================================
# EXECUTION
# ==============================================================================

# Run main function
if main; then
    log_info "All operations completed"
    exit 0
else
    log_error "Installation failed"
    show_error_solutions
    exit 1
fi
