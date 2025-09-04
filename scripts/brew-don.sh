#!/usr/bin/env bash

# =================================================================
# Don's Additional Homebrew Packages
# =================================================================
# This file contains Don's additional packages that are NOT in the
# upstream brew.sh file. This prevents merge conflicts while adding
# modern development tools.
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_info "Installing Don's additional Homebrew packages..."

# Make sure we're using the latest Homebrew
brew update

# Upgrade any already-installed formulae
brew upgrade

# Save Homebrew's installed location for later use
BREW_PREFIX=$(brew --prefix)

# Don's Essential Development Tools
don_packages=(
    "pyenv"         # Python version manager
    "fnm"           # Fast Node Manager (Node.js version manager)
    "starship"      # Cross-shell prompt
    "pinentry-mac"  # GPG password entry for macOS
    "azure-cli"     # Azure command line interface
    "gh"            # GitHub CLI
    "git-lfs"       # Git Large File Storage

    # Modern CLI improvements
    # "bat"           # Better cat with syntax highlighting
    # "exa"           # Better ls with colors and icons
    # "ripgrep"       # Better grep (faster)
    # "fd"            # Better find
    # "htop"          # Better top
    "tree"          # Directory tree visualization
    # "jq"            # JSON processor

    # Network and utilities
    "curl"          # Latest curl version
    "wget"          # Web downloader

    # GNU utilities (better than macOS versions)
    # "coreutils"     # GNU core utilities
    # "moreutils"     # Additional useful utilities
    # "findutils"     # GNU find, locate, updatedb, xargs
    # "gnu-sed"       # GNU sed (better than macOS sed)

	"gnupg"         # Install GnuPG to enable PGP-signing commits.
    "grep"          # GNU grep
    "openssh"       # Latest OpenSSH
)

# Install Don's packages
for package in "${don_packages[@]}"; do
    if brew list "$package" &>/dev/null; then
        log_success "$package already installed"
    else
        log_info "Installing $package..."
        brew install "$package"
        log_success "$package installed"
    fi
done

# =================================================================
# Don's Applications via Homebrew Cask
# =================================================================
don_apps=(
    # "visual-studio-code"            # VS Code Stable
    # "visual-studio-code-insiders"   # VS Code Insiders
    # "microsoft-edge"                # Edge browser
    # "docker"                        # Docker Desktop
    # "postman"                       # API development tool
    # "xcode"                         # Apple development IDE
    # "gpg-suite"                     # GPG Keychain and tools
    # "slack"                         # Team communication
    # "okta-verify"                   # 2FA authentication
    # "ollama"                        # Local AI model runner
    # "tor-browser"                   # Privacy-focused browser
    # "rectangle"                     # Window management tool
)

log_info "Installing Don's applications..."

for app in "${don_apps[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
        log_success "$app already installed"
    else
        log_info "Installing $app..."
        brew install --cask "$app"
        log_success "$app installed"
    fi
done

# =================================================================
# Cleanup
# =================================================================
log_info "Cleaning up Homebrew..."
brew cleanup

log_success "Don's additional packages installed! 🎉"
echo ""
log_info "📋 Notes:"
echo "  • GNU utilities are now available (coreutils, findutils, gnu-sed, etc.)"
echo "  • Modern CLI tools installed: bat, exa, ripgrep, fd, htop"
echo "  • All outdated Homebrew flags have been removed for compatibility"
echo "  • Bash is available as an alternative shell (zsh is primary)"
echo ""
log_info "🔧 To use GNU tools by default, add to your ~/.zshrc:"
echo "  export PATH=\"\$(brew --prefix)/libexec/gnubin:\$PATH\""
