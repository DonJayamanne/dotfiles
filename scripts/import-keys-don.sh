#!/usr/bin/env bash

# =================================================================
# Don's Key Import Script (for New Mac)
# =================================================================
# This script imports SSH and GPG keys that were exported from your
# old Mac. Run this on your NEW Mac after transferring the keys.
#
# Usage: ./scripts/import-keys-don.sh [path-to-exported-keys]
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

# Get import directory from argument or prompt
IMPORT_DIR="$1"

if [[ -z "$IMPORT_DIR" ]]; then
    read -p "Enter path to your exported keys directory: " IMPORT_DIR
fi

# Expand tilde and resolve path
IMPORT_DIR="${IMPORT_DIR/#\~/$HOME}"
IMPORT_DIR="$(cd "$(dirname "$IMPORT_DIR")" && pwd)/$(basename "$IMPORT_DIR")"

log_info "🔑 Starting key import process..."
log_info "Import directory: $IMPORT_DIR"

# =================================================================
# 1. Validate Import Directory
# =================================================================
if [[ ! -d "$IMPORT_DIR" ]]; then
    log_error "Import directory not found: $IMPORT_DIR"
    exit 1
fi

if [[ ! -d "$IMPORT_DIR/ssh" && ! -d "$IMPORT_DIR/gpg" ]]; then
    log_error "Invalid export directory - missing ssh/ or gpg/ subdirectories"
    exit 1
fi

log_success "Found valid export directory"

# =================================================================
# 2. Import SSH Keys
# =================================================================
if [[ -d "$IMPORT_DIR/ssh" ]] && [[ -n "$(ls -A "$IMPORT_DIR/ssh" 2>/dev/null)" ]]; then
    log_info "📡 Importing SSH keys..."

    # Create SSH directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # SSH_IMPORTED=0

    # Import private keys
    for keyfile in "$IMPORT_DIR/ssh/id_"*; do
        if [[ -f "$keyfile" && ! "$keyfile" =~ \.pub$ ]]; then
            keyname=$(basename "$keyfile")
            cp "$keyfile" ~/.ssh/
            chmod 600 ~/.ssh/"$keyname"
            log_success "Imported private key: $keyname"
            # ((SSH_IMPORTED++))
        fi
    done

    # Import public keys
    for keyfile in "$IMPORT_DIR/ssh/"*.pub; do
        if [[ -f "$keyfile" ]]; then
            keyname=$(basename "$keyfile")
            cp "$keyfile" ~/.ssh/
            chmod 644 ~/.ssh/"$keyname"
            log_success "Imported public key: $keyname"
        fi
    done

    # Import SSH config
    if [[ -f "$IMPORT_DIR/ssh/config" ]]; then
        if [[ -f ~/.ssh/config ]]; then
            log_warning "SSH config already exists. Creating backup..."
            cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)
        fi
        cp "$IMPORT_DIR/ssh/config" ~/.ssh/
        chmod 644 ~/.ssh/config
        log_success "Imported SSH config"
    fi

    # Import known_hosts
    if [[ -f "$IMPORT_DIR/ssh/known_hosts" ]]; then
        if [[ -f ~/.ssh/known_hosts ]]; then
            # Merge with existing known_hosts
            cat "$IMPORT_DIR/ssh/known_hosts" >> ~/.ssh/known_hosts
            # Remove duplicates
            sort -u ~/.ssh/known_hosts > ~/.ssh/known_hosts.tmp && mv ~/.ssh/known_hosts.tmp ~/.ssh/known_hosts
            log_success "Merged known_hosts"
        else
            cp "$IMPORT_DIR/ssh/known_hosts" ~/.ssh/
            chmod 644 ~/.ssh/known_hosts
            log_success "Imported known_hosts"
        fi
    fi

    # if [[ $SSH_IMPORTED -gt 0 ]]; then
    #     # Add keys to SSH agent
    #     ssh-add ~/.ssh/id_* 2>/dev/null || true
    #     log_success "Added SSH keys to agent"
    # fi
    # log_success "Imported $SSH_IMPORTED SSH key(s)"

	# Add keys to SSH agent
	ssh-add ~/.ssh/id_* 2>/dev/null || true
	log_success "Added SSH keys to agent"

    log_success "Imported SSH key(s)"
else
    log_info "No SSH keys to import"
fi

# =================================================================
# 3. Import GPG Keys
# =================================================================
if [[ -d "$IMPORT_DIR/gpg" ]] && [[ -n "$(ls -A "$IMPORT_DIR/gpg" 2>/dev/null)" ]]; then
    log_info "🔐 Importing GPG keys..."

    # Check if GPG is available
    if ! command -v gpg &> /dev/null; then
        log_error "GPG not found. Install with: brew install gnupg"
        exit 1
    fi

    # Create GPG directory if needed
    mkdir -p ~/.gnupg
    chmod 700 ~/.gnupg

    GPG_IMPORTED=false

    # Import public keys
    if [[ -f "$IMPORT_DIR/gpg/gpg-public-keys.asc" ]]; then
        if gpg --import "$IMPORT_DIR/gpg/gpg-public-keys.asc"; then
            log_success "Imported GPG public keys"
            GPG_IMPORTED=true
        else
            log_error "Failed to import GPG public keys"
        fi
    fi

    # Import private keys
    if [[ -f "$IMPORT_DIR/gpg/gpg-private-keys.asc" ]]; then
        log_info "Importing private keys (you may need to enter passphrases)..."
        if gpg --import "$IMPORT_DIR/gpg/gpg-private-keys.asc"; then
            log_success "Imported GPG private keys"
            GPG_IMPORTED=true
        else
            log_error "Failed to import GPG private keys"
        fi
    fi

    # Import trust database
    if [[ -f "$IMPORT_DIR/gpg/gpg-trust.txt" ]]; then
        if gpg --import-ownertrust "$IMPORT_DIR/gpg/gpg-trust.txt"; then
            log_success "Imported GPG trust database"
        else
            log_warning "Failed to import GPG trust database"
        fi
    fi

    if [[ "$GPG_IMPORTED" == "true" ]]; then
        log_success "GPG keys imported successfully"

        # Show imported keys
        log_info "Imported GPG keys:"
        gpg --list-secret-keys --keyid-format LONG
    fi
else
    log_info "No GPG keys to import"
fi

# =================================================================
# 4. Test Imported Keys
# =================================================================
log_info "🧪 Testing imported keys..."

# Test SSH
if [[ -f ~/.ssh/id_ed25519 || -f ~/.ssh/id_rsa ]]; then
    log_info "Testing SSH connection to GitHub..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_success "SSH key works with GitHub"
    else
        log_warning "SSH test failed or GitHub is unreachable"
        log_info "You can test manually later: ssh -T git@github.com"
    fi
fi

# Test GPG
if command -v gpg &> /dev/null && gpg --list-secret-keys --keyid-format LONG | grep -q "^sec"; then
    log_info "Testing GPG signing..."
    if echo "test message" | gpg --clearsign > /dev/null 2>&1; then
        log_success "GPG signing works"
    else
        log_warning "GPG signing test failed - you may need to enter your passphrase"
    fi
fi

# =================================================================
# 4. Import Git Configuration
# =================================================================
log_info "🔧 Importing Git configuration..."

if [[ -f "$IMPORT_DIR/git-config.sh" ]]; then
    # Create Don's config directory
    mkdir -p ~/.config/don

    # Copy the git configuration
    cp "$IMPORT_DIR/git-config.sh" ~/.config/don/git-config.sh
    log_success "Imported Git configuration to ~/.config/don/git-config.sh"

    # Source the configuration and display what was imported
    source "$IMPORT_DIR/git-config.sh"
    log_info "Imported Git settings:"
    log_info "  Name: ${DON_GIT_NAME:-'(not set)'}"
    log_info "  Email: ${DON_GIT_EMAIL:-'(not set)'}"
    log_info "  GPG Key: ${DON_GPG_KEY:-'(none)'}"
    log_info "  Default Branch: ${DON_DEFAULT_BRANCH:-'main'}"
    log_info "  Pull Strategy: ${DON_PULL_REBASE:-'false'}"
else
    log_warning "No git configuration found in export"
fi

# =================================================================
# 5. Configure Git (if keys available)
# =================================================================
log_info "🔧 Applying Git configuration..."

# Run git setup if available
if [[ -f "./scripts/git-setup-don.sh" ]]; then
    log_info "Running Git configuration script..."
    chmod +x "./scripts/git-setup-don.sh"
    "./scripts/git-setup-don.sh"
else
    log_warning "Git setup script not found. Configure manually if needed."
    log_info "Expected location: ./scripts/git-setup-don.sh"
fi

# =================================================================
# 6. Security Cleanup Reminder
# =================================================================
log_info "🧹 Security cleanup recommendations..."

echo ""
log_warning "🔒 IMPORTANT SECURITY STEPS:"
echo "1. Verify all keys work correctly"
echo "2. Test SSH: ssh -T git@github.com"
echo "3. Test GPG: echo 'test' | gpg --clearsign"
echo "4. SECURELY DELETE the export directory:"
echo "   rm -rf '$IMPORT_DIR'"
echo ""

read -p "Delete the import directory now? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Securely deleting import directory..."
    rm -rf "$IMPORT_DIR"
    log_success "Import directory deleted"
else
    log_warning "Remember to delete '$IMPORT_DIR' after verifying everything works!"
fi

# =================================================================
# 7. Final Summary
# =================================================================
log_success "🎉 Key import completed!"
echo ""
log_info "📋 Import Summary:"
echo "  • SSH keys: $(ls ~/.ssh/id_* 2>/dev/null | grep -v ".pub" | wc -l | tr -d ' ') imported"
echo "  • GPG keys: $(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "^sec" || echo "0") imported"
echo ""
log_info "✅ Verification Checklist:"
echo "  [ ] SSH to GitHub: ssh -T git@github.com"
echo "  [ ] GPG signing: echo 'test' | gpg --clearsign"
echo "  [ ] Git config: git config --get user.signingkey"
echo "  [ ] Test commit: git commit --allow-empty -m 'Test signing'"
echo ""
log_info "🎯 Your keys are now ready for use on this new Mac!"
