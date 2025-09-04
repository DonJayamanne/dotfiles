#!/usr/bin/env bash

# =================================================================
# Font Installation Script
# =================================================================
# This script installs the Nerd Fonts that are currently used
# on your system. Based on analysis of your current setup, you have:
# - FiraCode Nerd Font (multiple variants)
# - Symbols Nerd Font
# - Monaspace fonts (GitHub's programming fonts)
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create fonts directory if it doesn't exist
FONTS_DIR="$HOME/Library/Fonts"
mkdir -p "$FONTS_DIR"

log_info "Installing Nerd Fonts..."

# =================================================================
# Install via Homebrew (recommended method)
# =================================================================
log_info "Installing fonts via Homebrew..."

# Font casks to install (based on your current setup)
font_casks=(
    "font-fira-code-nerd-font"      # FiraCode Nerd Font
    "font-symbols-only-nerd-font"   # Symbols Nerd Font
    "font-monaspace"                # Monaspace fonts (GitHub)
)

# Install each font
for font in "${font_casks[@]}"; do
    if brew list --cask "$font" &>/dev/null; then
        log_success "$font already installed"
    else
        log_info "Installing $font..."
        brew install --cask "$font"
        log_success "$font installed"
    fi
done

# =================================================================
# Verify Installation
# =================================================================
log_info "Verifying font installation..."

expected_fonts=(
    "FiraCode Nerd Font"
    "Symbols Nerd Font"
    "Monaspace Argon"
    "Monaspace Krypton"
    "Monaspace Neon"
    "Monaspace Radon"
    "Monaspace Xenon"
)

installed_count=0
total_fonts=${#expected_fonts[@]}

for font_family in "${expected_fonts[@]}"; do
    if system_profiler SPFontsDataType | grep -q "$font_family"; then
        log_success "✓ $font_family is installed"
        ((installed_count++))
    else
        log_warning "✗ $font_family not found"
    fi
done

# =================================================================
# Summary
# =================================================================
log_info "Font installation summary:"
echo "  Installed: $installed_count/$total_fonts fonts"

if [ $installed_count -eq $total_fonts ]; then
    log_success "All fonts installed successfully! 🎉"
else
    log_warning "Some fonts may not have installed correctly."
    log_info "You can manually download missing fonts from:"
    echo "  - https://www.nerdfonts.com/font-downloads"
    echo "  - https://github.com/githubnext/monaspace"
fi

log_info "Note: You may need to restart applications to see the new fonts."
