#!/usr/bin/env bash

# =================================================================
# Don's Git Configuration Setup
# =================================================================
# This script sets up Git with Don's personal configuration including
# user information, GPG signing, and preferences. It reads from the
# current git config to preserve existing settings.
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

log_info "🔧 Setting up Git configuration..."

# =================================================================
# Git User Information
# =================================================================
GIT_CONFIG_FILE="$HOME/.config/don/git-config.sh"

if [[ ! -f "$GIT_CONFIG_FILE" ]]; then
    log_error "Git configuration file not found: $GIT_CONFIG_FILE"
    log_error "Please run the import script first: ./scripts/import-keys-don.sh"
    exit 1
fi

log_info "Loading git configuration from imported settings..."
source "$GIT_CONFIG_FILE"

log_info "Configuring Git user information..."

# Set user name
CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
if [[ "$CURRENT_NAME" != "$DON_GIT_NAME" ]]; then
    git config --global user.name "$DON_GIT_NAME"
    log_success "User name set to: $DON_GIT_NAME"
else
    log_success "User name already configured: $CURRENT_NAME"
fi

# Set user email
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
if [[ "$CURRENT_EMAIL" != "$DON_GIT_EMAIL" ]]; then
    git config --global user.email "$DON_GIT_EMAIL"
    log_success "User email set to: $DON_GIT_EMAIL"
else
    log_success "User email already configured: $CURRENT_EMAIL"
fi

# =================================================================
# GPG Signing Configuration
# =================================================================
log_info "Configuring GPG signing..."

# Set GPG signing key
CURRENT_KEY=$(git config --global user.signingkey 2>/dev/null || echo "")
if [[ "$CURRENT_KEY" != "$DON_GPG_KEY" ]]; then
    git config --global user.signingkey "$DON_GPG_KEY"
    log_success "GPG signing key set to: $DON_GPG_KEY"
else
    log_success "GPG signing key already configured: $CURRENT_KEY"
fi

# Enable commit signing
CURRENT_SIGNING=$(git config --global commit.gpgsign 2>/dev/null || echo "false")
if [[ "$CURRENT_SIGNING" != "true" ]]; then
    git config --global commit.gpgsign true
    log_success "GPG commit signing enabled"
else
    log_success "GPG commit signing already enabled"
fi

# Set GPG program path (for macOS)
CURRENT_GPG_PROGRAM=$(git config --global gpg.program 2>/dev/null || echo "")

# Use imported GPG program if available, otherwise determine based on architecture
if [[ -n "$DON_GPG_PROGRAM" ]]; then
    EXPECTED_GPG_PROGRAM="$DON_GPG_PROGRAM"
else
    EXPECTED_GPG_PROGRAM="/opt/homebrew/bin/gpg"
fi

if [[ "$CURRENT_GPG_PROGRAM" != "$EXPECTED_GPG_PROGRAM" ]]; then
    git config --global gpg.program "$EXPECTED_GPG_PROGRAM"
    log_success "GPG program path set to: $EXPECTED_GPG_PROGRAM"
else
    log_success "GPG program path already configured: $CURRENT_GPG_PROGRAM"
fi

# =================================================================
# Additional Git Preferences
# =================================================================
log_info "Configuring additional Git preferences..."

# Set default branch name for new repositories
DESIRED_BRANCH="${DON_DEFAULT_BRANCH:-main}"
CURRENT_INIT_BRANCH=$(git config --global init.defaultBranch 2>/dev/null || echo "")
if [[ "$CURRENT_INIT_BRANCH" != "$DESIRED_BRANCH" ]]; then
    git config --global init.defaultBranch "$DESIRED_BRANCH"
    log_success "Default branch name set to '$DESIRED_BRANCH'"
else
    log_success "Default branch name already set to '$DESIRED_BRANCH'"
fi

# Configure pull strategy
DESIRED_REBASE="${DON_PULL_REBASE:-false}"
CURRENT_PULL_REBASE=$(git config --global pull.rebase 2>/dev/null || echo "")
if [[ "$CURRENT_PULL_REBASE" != "$DESIRED_REBASE" ]]; then
    git config --global pull.rebase "$DESIRED_REBASE"
    if [[ "$DESIRED_REBASE" == "false" ]]; then
        log_success "Pull strategy set to merge (not rebase)"
    else
        log_success "Pull strategy set to rebase"
    fi
else
    log_success "Pull strategy already configured"
fi

# =================================================================
# Verification
# =================================================================
log_info "🔍 Verifying Git configuration..."

echo ""
log_info "📋 Current Git configuration:"
echo "  Name: $(git config --global user.name)"
echo "  Email: $(git config --global user.email)"
echo "  Signing Key: $(git config --global user.signingkey)"
echo "  GPG Signing: $(git config --global commit.gpgsign)"
echo "  GPG Program: $(git config --global gpg.program)"
echo "  Default Branch: $(git config --global init.defaultBranch)"
echo "  Pull Strategy: $(git config --global pull.rebase | sed 's/false/merge/' | sed 's/true/rebase/')"
echo ""

# =================================================================
# GPG Key Verification
# =================================================================
log_info "🔐 Verifying GPG key..."

if command -v gpg &> /dev/null; then
    if gpg --list-secret-keys --keyid-format LONG | grep -q "$DON_GPG_KEY"; then
        log_success "GPG key $DON_GPG_KEY found in keyring"

        # Test GPG signing
        if echo "test" | gpg --clear-sign --local-user "$DON_GPG_KEY" > /dev/null 2>&1; then
            log_success "GPG signing test successful"
        else
            log_warning "GPG signing test failed - you may need to enter your passphrase"
        fi
    else
        log_warning "GPG key $DON_GPG_KEY not found in keyring"
        log_info "You may need to import your GPG key. See KEY-TRANSFER-GUIDE.md for instructions."
    fi
else
    log_warning "GPG not found - install with: brew install gnupg"
fi

# =================================================================
# Success Summary
# =================================================================
log_success "🎉 Git configuration completed!"
echo ""
log_info "📝 Next steps (if needed):"
echo "  1. Import GPG keys: See KEY-TRANSFER-GUIDE.md"
echo "  2. Test commit signing: git commit --allow-empty -m 'Test signing'"
echo "  3. Verify signature: git log --show-signature -1"
echo ""
log_info "✨ Your commits will now be signed automatically!"
