#!/usr/bin/env bash

# =================================================================
# Don's Key Import & Git Setup Script (for New Mac)
# =================================================================
# This script imports SSH and GPG keys that were exported from your
# old Mac, then configures Git with the imported settings.
# Run this on your NEW Mac after transferring the keys.
#
# Usage: ./scripts/import-keys.sh [path-to-exported-keys]
# =================================================================

# Load common utilities
source "$(dirname "$0")/common.sh"

# Get import directory from argument or interactive prompt
IMPORT_DIR="$1"

if [[ -z "$IMPORT_DIR" ]]; then
    echo ""
    read -p "Do you have exported keys from your old Mac to import? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    while true; do
        echo ""
        read -p "Path to exported keys (or 'exit' to cancel): " IMPORT_DIR
        
        if [[ "$IMPORT_DIR" == "exit" ]]; then
            exit 0
        fi
        
        # Expand and validate path
        IMPORT_DIR="$(expand_path "$IMPORT_DIR")"
        
        if [[ -d "$IMPORT_DIR" ]]; then
            break
        else
            log_error "Directory not found: $IMPORT_DIR"
            echo "Please check the path and try again, or type 'exit' to cancel"
        fi
    done
fi

# Expand tilde and resolve path
IMPORT_DIR="$(resolve_path "$IMPORT_DIR")"


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


# =================================================================
# 2. Import SSH Keys
# =================================================================
if [[ -d "$IMPORT_DIR/ssh" ]] && [[ -n "$(ls -A "$IMPORT_DIR/ssh" 2>/dev/null)" ]]; then

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
            # ((SSH_IMPORTED++))
        fi
    done

    # Import public keys
    for keyfile in "$IMPORT_DIR/ssh/"*.pub; do
        if [[ -f "$keyfile" ]]; then
            keyname=$(basename "$keyfile")
            cp "$keyfile" ~/.ssh/
            chmod 644 ~/.ssh/"$keyname"
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
    fi

    # Import known_hosts
    if [[ -f "$IMPORT_DIR/ssh/known_hosts" ]]; then
        if [[ -f ~/.ssh/known_hosts ]]; then
            # Merge with existing known_hosts
            cat "$IMPORT_DIR/ssh/known_hosts" >> ~/.ssh/known_hosts
            # Remove duplicates
            sort -u ~/.ssh/known_hosts > ~/.ssh/known_hosts.tmp && mv ~/.ssh/known_hosts.tmp ~/.ssh/known_hosts
        else
            cp "$IMPORT_DIR/ssh/known_hosts" ~/.ssh/
            chmod 644 ~/.ssh/known_hosts
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
fi

# =================================================================
# 3. Import GPG Keys
# =================================================================
if [[ -d "$IMPORT_DIR/gpg" ]] && [[ -n "$(ls -A "$IMPORT_DIR/gpg" 2>/dev/null)" ]]; then

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
            GPG_IMPORTED=true
        else
            log_error "Failed to import GPG public keys"
        fi
    fi

    # Import private keys
    if [[ -f "$IMPORT_DIR/gpg/gpg-private-keys.asc" ]]; then
        if gpg --import "$IMPORT_DIR/gpg/gpg-private-keys.asc"; then
            GPG_IMPORTED=true
        else
            log_error "Failed to import GPG private keys"
        fi
    fi

    # Import trust database
    if [[ -f "$IMPORT_DIR/gpg/gpg-trust.txt" ]]; then
        if ! gpg --import-ownertrust "$IMPORT_DIR/gpg/gpg-trust.txt"; then
            log_warning "Failed to import GPG trust database"
        fi
    fi

    # GPG keys imported if needed
fi

# =================================================================
# 4. Test Imported Keys
# =================================================================

# Test SSH
if [[ -f ~/.ssh/id_ed25519 || -f ~/.ssh/id_rsa ]]; then
    if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_warning "SSH test failed or GitHub is unreachable - test manually: ssh -T git@github.com"
    fi
fi

# Test GPG
if command -v gpg &> /dev/null && gpg --list-secret-keys --keyid-format LONG | grep -q "^sec"; then
    if ! echo "test message" | gpg --clearsign > /dev/null 2>&1; then
        log_warning "GPG signing test failed - you may need to enter your passphrase"
    fi
fi

# =================================================================
# 4. Load Git Configuration
# =================================================================

if [[ -f "$IMPORT_DIR/git-config.sh" ]]; then
    # Source the git configuration directly
    source "$IMPORT_DIR/git-config.sh"
else
    log_warning "No git configuration found in export"
fi

# =================================================================
# 5. Configure Git
# =================================================================
if [[ -f "$IMPORT_DIR/git-config.sh" ]]; then

    # Set user name
    CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
    if [[ "$CURRENT_NAME" != "$DON_GIT_NAME" ]]; then
        git config --global user.name "$DON_GIT_NAME"
    fi

    # Set user email
    CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
    if [[ "$CURRENT_EMAIL" != "$DON_GIT_EMAIL" ]]; then
        git config --global user.email "$DON_GIT_EMAIL"
    fi

    # =================================================================
    # GPG Signing Configuration
    # =================================================================

    # Set GPG signing key
    CURRENT_KEY=$(git config --global user.signingkey 2>/dev/null || echo "")
    if [[ "$CURRENT_KEY" != "$DON_GPG_KEY" ]]; then
        git config --global user.signingkey "$DON_GPG_KEY"
    fi

    # Enable commit signing
    CURRENT_SIGNING=$(git config --global commit.gpgsign 2>/dev/null || echo "false")
    if [[ "$CURRENT_SIGNING" != "true" ]]; then
        git config --global commit.gpgsign true
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
    fi

    # =================================================================
    # Additional Git Preferences
    # =================================================================

    # Set default branch name for new repositories
    DESIRED_BRANCH="${DON_DEFAULT_BRANCH:-main}"
    CURRENT_INIT_BRANCH=$(git config --global init.defaultBranch 2>/dev/null || echo "")
    if [[ "$CURRENT_INIT_BRANCH" != "$DESIRED_BRANCH" ]]; then
        git config --global init.defaultBranch "$DESIRED_BRANCH"
    fi

    # Configure pull strategy
    DESIRED_REBASE="${DON_PULL_REBASE:-false}"
    CURRENT_PULL_REBASE=$(git config --global pull.rebase 2>/dev/null || echo "")
    if [[ "$CURRENT_PULL_REBASE" != "$DESIRED_REBASE" ]]; then
        git config --global pull.rebase "$DESIRED_REBASE"
    fi

    # Test GPG signing
    if command -v gpg &> /dev/null; then
        if gpg --list-secret-keys --keyid-format LONG | grep -q "$DON_GPG_KEY"; then
            if ! echo "test" | gpg --clear-sign --local-user "$DON_GPG_KEY" > /dev/null 2>&1; then
                log_warning "GPG signing test failed - you may need to enter your passphrase"
            fi
        else
            log_warning "GPG key $DON_GPG_KEY not found in keyring"
        fi
    else
        log_warning "GPG not found - install with: brew install gnupg"
    fi
else
    log_warning "No git configuration found - skipping Git setup"
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
    rm -rf "$IMPORT_DIR"
else
    log_warning "Remember to delete '$IMPORT_DIR' after verifying everything works!"
fi

# =================================================================
# 7. Final Summary
# =================================================================
log_success "🎉 Key import and Git setup completed!"
