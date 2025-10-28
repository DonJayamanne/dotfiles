#!/usr/bin/env bash

# =================================================================
# Don's Additional Homebrew Packages
# =================================================================
# This file contains Don's additional packages that are NOT in the
# upstream brew.sh file. This prevents merge conflicts while adding
# modern development tools.
# =================================================================

# Load common utilities
source "$(dirname "$0")/scripts/common.sh"


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
	# "zsh-autosuggestions" # Ghost text style suggestions
	# "zsh-syntax-highlighting" # Syntax highlighting
    # "bat"           # Better cat with syntax highlighting
    # "exa"           # Better ls with colors and icons
    # "ripgrep"       # Better grep (faster)
    # "fd"            # Better find
    # "htop"          # Better top
    "tree"            # Directory tree visualization
    # "jq"            # JSON processor
    "rename"          # Batch renaming of files

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

	"rustup"
)

# Install Don's packages
for package in "${don_packages[@]}"; do
    if ! brew list "$package" &>/dev/null; then
        brew install "$package"
    fi
done

# =================================================================
# Don's Applications via Homebrew Cask
# =================================================================
don_apps=(
    "font-fira-code-nerd-font"      # FiraCode Nerd Font
    "font-symbols-only-nerd-font"   # Symbols Nerd Font
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


for app in "${don_apps[@]}"; do
    if ! brew list --cask "$app" &>/dev/null; then
        brew install --cask "$app"
    fi
done

# =================================================================
# Cleanup
# =================================================================
brew cleanup

