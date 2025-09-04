#!/usr/bin/env bash

# =================================================================
# Don's Complete Mac Setup Script
# =================================================================
# This is the ONLY script you need to run to set up your new Mac.
# It will prompt for your exported keys and handle everything else.
#
# Usage: cd scripts && ./setup-mac.sh
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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

log_step() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}"
}

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
if [[ ! -f "./brew-don.sh" ]]; then
    log_error "This script must be run from the dotfiles/scripts directory"
    log_error "Make sure you're in the scripts directory containing brew-don.sh"
    exit 1
fi

log_info "This script will set up your complete development environment:"
echo "  • Import your SSH and GPG keys"
echo "  • Install Homebrew and development tools"
echo "  • Configure Git with GPG signing"
echo "  • Set up Zsh with Oh My Zsh and Starship"
echo "  • Configure macOS system preferences"
echo "  • Install fonts"
echo ""

# =================================================================
# Step 1: Import Keys (Optional)
# =================================================================
log_step "Step 1: Import Your Keys (Optional)"

KEYS_IMPORTED=false
read -p "Do you have exported keys from your old Mac to import? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    while true; do
        echo ""
        log_info "Please provide the path to your exported keys directory"
        log_info "This should be the folder created by export-keys-don.sh"
        read -p "Path to exported keys (or 'skip' to continue without): " KEYS_PATH

        if [[ "$KEYS_PATH" == "skip" ]]; then
            log_info "Skipping key import - you can run ./import-keys-don.sh later"
            break
        fi

        # Expand tilde
        KEYS_PATH="${KEYS_PATH/#\~/$HOME}"

        if [[ -d "$KEYS_PATH" ]]; then
            log_info "Found keys directory: $KEYS_PATH"
            log_info "Running import-keys-don.sh..."

            if [[ -f "./import-keys-don.sh" ]]; then
                chmod +x "./import-keys-don.sh"
                "./import-keys-don.sh" "$KEYS_PATH"
                KEYS_IMPORTED=true
                log_success "Keys imported successfully!"
                break
            else
                log_error "import-keys-don.sh not found at ./import-keys-don.sh"
                exit 1
            fi
        else
            log_error "Directory not found: $KEYS_PATH"
            echo "Please check the path and try again, or type 'skip' to continue"
        fi
    done
else
    log_info "Skipping key import - you can run ./import-keys-don.sh later"
fi

# =================================================================
# Step 2: Install Homebrew
# =================================================================
log_step "Step 2: Install Homebrew"

if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed successfully"
else
    log_success "Homebrew is already installed"
fi

# =================================================================
# Step 3: Install Development Tools
# =================================================================
log_step "Step 3: Install Development Tools"

if [[ -f "./brew-don.sh" ]]; then
    log_info "Installing development packages..."
    chmod +x "./brew-don.sh"
    "./brew-don.sh"
    log_success "Development tools installed"
else
    log_error "brew-don.sh not found"
    exit 1
fi

# =================================================================
# Step 4: Setup Shell Environment
# =================================================================
log_step "Step 4: Setup Shell Environment"

# Install Oh My Zsh if not present
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
else
    log_success "Oh My Zsh already installed"
fi

# Install you-should-use plugin
if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/you-should-use" ]]; then
    log_info "Installing you-should-use plugin..."
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$HOME/.oh-my-zsh/custom/plugins/you-should-use"
    log_success "you-should-use plugin installed"
else
    log_success "you-should-use plugin already installed"
fi

# Merge custom zsh config
if [[ -f "./.zshrc" ]]; then
    if [[ -f "$HOME/.zshrc" ]] && grep -q "# Don's Zsh Customizations" "$HOME/.zshrc"; then
        log_success "Don's Zsh customizations already present in ~/.zshrc"
    else
        log_info "Adding custom Zsh configuration..."
        if [[ -f "$HOME/.zshrc" ]]; then
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup_$(date +%Y%m%d_%H%M%S)"
        fi
        cat "./.zshrc" >> "$HOME/.zshrc"
        log_success "Custom Zsh config added"
    fi
fi

# Merge custom zprofile config
if [[ -f "./.zprofile" ]]; then
    if [[ -f "$HOME/.zprofile" ]] && grep -q "# Don's Zprofile Customizations" "$HOME/.zprofile"; then
        log_success "Don's Zprofile customizations already present in ~/.zprofile"
    else
        log_info "Adding custom Zprofile configuration..."
        if [[ -f "$HOME/.zprofile" ]]; then
            cp "$HOME/.zprofile" "$HOME/.zprofile.backup_$(date +%Y%m%d_%H%M%S)"
        fi
        cat "./.zprofile" >> "$HOME/.zprofile"
        log_success "Custom Zprofile config added"
    fi
fi

# Configure Starship
if [[ -f "../starship.toml" ]]; then
    log_info "Installing Starship prompt configuration..."
    mkdir -p "$HOME/.config"
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.backup_$(date +%Y%m%d_%H%M%S)"
    fi
    cp "../starship.toml" "$HOME/.config/starship.toml"
    log_success "Starship prompt configured"
fi

# Install zprezto
if [[ ! -d "$HOME/.zprezto" ]]; then
    log_info "Installing zprezto..."
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    log_success "zprezto installed"
fi

# Configure zprezto with custom zpreztorc
if [[ -f "./zpreztorc" ]]; then
    log_info "Installing custom zprezto configuration..."
    if [[ -f "$HOME/.zprezto/runcoms/zpreztorc" ]]; then
        cp "$HOME/.zprezto/runcoms/zpreztorc" "$HOME/.zprezto/runcoms/zpreztorc.backup_$(date +%Y%m%d_%H%M%S)"
    fi
    cp "./zpreztorc" "$HOME/.zprezto/runcoms/zpreztorc"
    log_success "zprezto configuration installed"
else
    log_warning "zpreztorc not found in scripts directory - using default"
fi

# =================================================================
# Step 5: Install Fonts
# =================================================================
log_step "Step 5: Install Fonts"

if [[ -f "./install-fonts.sh" ]]; then
    log_info "Installing programming fonts..."
    chmod +x "./install-fonts.sh"
    "./install-fonts.sh"
    log_success "Fonts installed"
else
    log_warning "install-fonts.sh not found - skipping fonts"
fi

# =================================================================
# Step 6: Configure macOS (Optional)
# =================================================================
log_step "Step 6: Configure macOS System Preferences"

if [[ -f "../.macos" ]]; then
    echo ""
    log_warning "⚠️  This will modify your macOS system preferences!"
    log_info "Changes include: Dock, Finder, security settings, etc."
    echo ""

    read -p "Apply macOS system configurations? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Applying macOS configurations..."
        chmod +x "../.macos"
        "../.macos"
        log_success "macOS preferences configured"
    else
        log_info "Skipped macOS configuration"
        log_info "Run later with: ../.macos"
    fi
fi

# =================================================================
# Final Summary
# =================================================================
echo ""
log_success "🎉 Mac setup completed successfully!"
echo ""
echo -e "${BOLD}📋 What's been set up:${NC}"
echo "  ✅ Homebrew package manager"
echo "  ✅ Development tools and CLI utilities (including fnm & starship)"
if [[ "$KEYS_IMPORTED" == "true" ]]; then
    echo "  ✅ SSH and GPG keys imported"
    echo "  ✅ Git configured with GPG signing"
else
    echo "  ⏸️  SSH/GPG keys (run ./import-keys-don.sh later)"
    echo "  ⏸️  Git configuration (run ./git-setup-don.sh after importing keys)"
fi
echo "  ✅ Zsh shell with Oh My Zsh"
echo "  ✅ Starship prompt theme"
echo "  ✅ Programming fonts"
echo ""

echo -e "${BOLD}🚀 Next steps:${NC}"
echo "  1. Restart your terminal or run: source ~/.zshrc"
if [[ "$KEYS_IMPORTED" != "true" ]]; then
    echo "  2. Import keys when ready: ./import-keys-don.sh ~/path/to/keys"
    echo "  3. Configure Git: ./git-setup-don.sh"
fi
echo "  2. Install applications manually (see README-don.md for list)"
echo "  3. Enjoy your fully configured development environment!"
echo ""

log_info "📖 For more details, see README-don.md"
echo ""
echo -e "${GREEN}${BOLD}🎯 Your Mac is now ready for development!${NC}"
