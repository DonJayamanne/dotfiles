#!/usr/bin/env bash

# =================================================================
# Don's Additional Tools Installation Script
# =================================================================
# This script installs Rust and sets up the shell environment
# including Oh My Zsh, plugins, and zprezto.
#
# Usage: ./scripts/install-tools.sh
# =================================================================

# Load common utilities
source "$(dirname "$0")/common.sh"

if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Install Oh My Zsh if not present
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

# Install you-should-use plugin
if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/you-should-use" ]]; then
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$HOME/.oh-my-zsh/custom/plugins/you-should-use"
fi

# Install zprezto
if [[ ! -d "$HOME/.zprezto" ]]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
fi

