#!/usr/bin/env bash

# =================================================================
# Don's Complete Mac Setup Script
# =================================================================
# This is the ONLY script you need to run to set up your new Mac.
# It will prompt for your exported keys and handle everything else.
#
# Usage: ./setup-mac.sh
# =================================================================

# Load common utilities
source "$(dirname "$0")/scripts/common.sh"

# Welcome message
echo -e "${BOLD}${BLUE}"
echo "██████╗  ██████╗ ███╗   ██╗███████╗    ███╗   ███╗ █████╗  ██████╗"
echo "██╔══██╗██╔═══██╗████╗  ██║██╔════╝    ████╗ ████║██╔══██╗██╔════╝"
echo "██║  ██║██║   ██║██╔██╗ ██║███████╗    ██╔████╔██║███████║██║     "
echo "██║  ██║██║   ██║██║╚██╗██║╚════██║    ██║╚██╔╝██║██╔══██║██║     "
echo "██████╔╝╚██████╔╝██║ ╚████║███████║    ██║ ╚═╝ ██║██║  ██║╚██████╗"
echo "╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝"
echo -e "${NC}"
echo -e "${BOLD}🚀 Complete Mac Development Environment Setup${NC}"
echo ""

# Check if we're in the right directory
if [[ ! -f "./brew.sh" ]]; then
    log_error "This script must be run from the dotfiles directory"
    log_error "Make sure you're in the dotfiles directory containing brew.sh"
    exit 1
fi


if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

chmod +x "./brew.sh"
"./brew.sh"

chmod +x "./scripts/import-keys.sh"
if "./scripts/import-keys.sh"; then
    KEYS_IMPORTED=true
else
    KEYS_IMPORTED=false
fi


chmod +x "./scripts/install-tools.sh"
"./scripts/install-tools.sh"

if [[ -f "../.macos" ]]; then
    echo ""
    log_warning "⚠️  This will modify your macOS system preferences!"
    echo ""

    read -p "Apply macOS system configurations? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x "../.macos"
        "../.macos"
    fi
fi

if [[ "$KEYS_IMPORTED" != "true" ]]; then
    log_info "Import your keys later with: ./scripts/import-keys.sh ~/path/to/keys"
fi
log_success "🎯 Mac setup completed!"
