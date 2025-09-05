#!/usr/bin/env bash

# =================================================================
# Don's Key Export Script (for Old Mac)
# =================================================================
# This script exports SSH and GPG keys from your current Mac for
# transfer to a new Mac. Run this on your OLD Mac.
#
# Usage: ./scripts/export-keys.sh [export-directory]
# =================================================================

# Load common utilities
source "$(dirname "$0")/common.sh"

# Default export directory
EXPORT_DIR="${1:-$HOME/don-keys-export}"

mkdir -p "$EXPORT_DIR/ssh"
mkdir -p "$EXPORT_DIR/gpg"

# Set secure permissions
chmod 700 "$EXPORT_DIR"
chmod 700 "$EXPORT_DIR/ssh"
chmod 700 "$EXPORT_DIR/gpg"

# =================================================================
# 2. Export SSH Keys
# =================================================================

SSH_EXPORTED=0

if [[ -f ~/.ssh/id_ed25519 ]]; then
    cp ~/.ssh/id_ed25519 "$EXPORT_DIR/ssh/"
    cp ~/.ssh/id_ed25519.pub "$EXPORT_DIR/ssh/"
    ((SSH_EXPORTED++))
fi

if [[ -f ~/.ssh/id_rsa ]]; then
    cp ~/.ssh/id_rsa "$EXPORT_DIR/ssh/"
    cp ~/.ssh/id_rsa.pub "$EXPORT_DIR/ssh/"
    ((SSH_EXPORTED++))
fi

if [[ -f ~/.ssh/config ]]; then
    cp ~/.ssh/config "$EXPORT_DIR/ssh/"
fi

if [[ -f ~/.ssh/known_hosts ]]; then
    cp ~/.ssh/known_hosts "$EXPORT_DIR/ssh/"
fi

if [[ $SSH_EXPORTED -eq 0 ]]; then
    log_warning "No SSH keys found in ~/.ssh/"
fi

# =================================================================
# 3. Export Git Configuration
# =================================================================

# Get current git configuration
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
GIT_GPG_KEY=$(git config --global user.signingkey 2>/dev/null || echo "")
GIT_DEFAULT_BRANCH=$(git config --global init.defaultBranch 2>/dev/null || echo "main")
GIT_PULL_REBASE=$(git config --global pull.rebase 2>/dev/null || echo "false")
GIT_GPG_PROGRAM=$(git config --global gpg.program 2>/dev/null || echo "")

if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
    # Create git configuration script
    cat > "$EXPORT_DIR/git-config.sh" << EOF
# Git Configuration Export
# Generated on: $(date)

DON_GIT_NAME="$GIT_NAME"
DON_GIT_EMAIL="$GIT_EMAIL"
DON_GPG_KEY="$GIT_GPG_KEY"
DON_DEFAULT_BRANCH="$GIT_DEFAULT_BRANCH"
DON_PULL_REBASE="$GIT_PULL_REBASE"
DON_GPG_PROGRAM="$GIT_GPG_PROGRAM"
EOF
else
    log_warning "No Git user configuration found"
    echo "# No Git configuration found" > "$EXPORT_DIR/git-config.sh"
fi

# =================================================================
# 4. Export GPG Keys
# =================================================================

if command -v gpg &> /dev/null; then
    # Check if any secret keys exist
    SECRET_KEYS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "^sec" || echo "0")
    
    if [[ $SECRET_KEYS -gt 0 ]]; then
        # Export public keys
        if ! gpg --export --armor > "$EXPORT_DIR/gpg/gpg-public-keys.asc"; then
            log_error "Failed to export GPG public keys"
        fi
        
        # Export private keys (most sensitive!)
        if gpg --export-secret-keys --armor > "$EXPORT_DIR/gpg/gpg-private-keys.asc"; then
            chmod 600 "$EXPORT_DIR/gpg/gpg-private-keys.asc"  # Extra security
        else
            log_error "Failed to export GPG private keys"
        fi
        
        # Export trust database
        if ! gpg --export-ownertrust > "$EXPORT_DIR/gpg/gpg-trust.txt"; then
            log_warning "Failed to export GPG trust database"
        fi
        
        # Save key list for reference
        gpg --list-secret-keys --keyid-format LONG > "$EXPORT_DIR/gpg/key-list.txt"
    else
        log_warning "No GPG secret keys found"
        echo "No GPG keys to export" > "$EXPORT_DIR/gpg/no-keys.txt"
    fi
else
    log_warning "GPG not found on this system"
    echo "GPG not available" > "$EXPORT_DIR/gpg/no-gpg.txt"
fi

# =================================================================
# 4. Create Transfer Instructions
# =================================================================

cat > "$EXPORT_DIR/TRANSFER-INSTRUCTIONS.md" << EOF
# Key Transfer Instructions

## 📦 Contents of this export:

**SSH Keys:**
$(ls -la "$EXPORT_DIR/ssh/" 2>/dev/null || echo "No SSH keys exported")

**GPG Keys:**
$(ls -la "$EXPORT_DIR/gpg/" 2>/dev/null || echo "No GPG keys exported")

## 🚀 Next Steps:

1. **Transfer this entire folder** to your new Mac using:
   - AirDrop (recommended for local transfer)
   - Encrypted USB drive
   - Secure cloud storage (password-protected zip)

2. **On your new Mac**, run the import script:
   \`\`\`bash
   ./scripts/import-keys-don.sh ~/path/to/don-keys-export
   \`\`\`

3. **After successful import**, securely delete this export:
   \`\`\`bash
   rm -rf "$EXPORT_DIR"
   \`\`\`

## ⚠️  Security Notes:
- This export contains your PRIVATE keys - keep it secure!
- Transfer via secure method only
- Delete the export immediately after successful import
- Never store these files in unsecured locations

## 🔍 Verification:
After import, verify on new Mac:
- SSH: \`ssh -T git@github.com\`
- GPG: \`gpg --list-secret-keys\`
- Git signing: \`echo "test" | gpg --clearsign\`

Export created: $(date)
EOF

# =================================================================
# 5. Create Archive (Optional)
# =================================================================

read -p "Create password-protected zip archive? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    ARCHIVE_NAME="don-keys-$(date +%Y%m%d-%H%M%S).zip"
    
    # Create password-protected archive
    if command -v zip &> /dev/null; then
        echo "Enter password for the archive (will be hidden):"
        if ! zip -er "$HOME/$ARCHIVE_NAME" "$EXPORT_DIR"; then
            log_error "Failed to create archive"
        fi
    else
        log_warning "zip command not available - skipping archive creation"
    fi
fi

log_warning "🔒 Security Reminder: This export contains private keys!"
log_success "🎉 Key export completed!"