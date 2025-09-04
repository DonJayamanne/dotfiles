#!/usr/bin/env bash

# =================================================================
# Don's Key Export Script (for Old Mac)
# =================================================================
# This script exports SSH and GPG keys from your current Mac for
# transfer to a new Mac. Run this on your OLD Mac.
#
# Usage: ./scripts/export-keys-don.sh [export-directory]
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

# Default export directory
EXPORT_DIR="${1:-$HOME/don-keys-export}"

log_info "🔑 Starting key export process..."
log_info "Export directory: $EXPORT_DIR"

# =================================================================
# 1. Create Export Directory Structure
# =================================================================
log_info "Creating export directory structure..."

mkdir -p "$EXPORT_DIR/ssh"
mkdir -p "$EXPORT_DIR/gpg"

# Set secure permissions
chmod 700 "$EXPORT_DIR"
chmod 700 "$EXPORT_DIR/ssh"
chmod 700 "$EXPORT_DIR/gpg"

log_success "Export directories created"

# =================================================================
# 2. Export SSH Keys
# =================================================================
log_info "📡 Exporting SSH keys..."

SSH_EXPORTED=0

if [[ -f ~/.ssh/id_ed25519 ]]; then
    cp ~/.ssh/id_ed25519 "$EXPORT_DIR/ssh/"
    cp ~/.ssh/id_ed25519.pub "$EXPORT_DIR/ssh/"
    log_success "Exported Ed25519 SSH key"
    ((SSH_EXPORTED++))
fi

if [[ -f ~/.ssh/id_rsa ]]; then
    cp ~/.ssh/id_rsa "$EXPORT_DIR/ssh/"
    cp ~/.ssh/id_rsa.pub "$EXPORT_DIR/ssh/"
    log_success "Exported RSA SSH key"
    ((SSH_EXPORTED++))
fi

if [[ -f ~/.ssh/config ]]; then
    cp ~/.ssh/config "$EXPORT_DIR/ssh/"
    log_success "Exported SSH config"
fi

if [[ -f ~/.ssh/known_hosts ]]; then
    cp ~/.ssh/known_hosts "$EXPORT_DIR/ssh/"
    log_success "Exported known_hosts"
fi

if [[ $SSH_EXPORTED -eq 0 ]]; then
    log_warning "No SSH keys found in ~/.ssh/"
else
    log_success "Exported $SSH_EXPORTED SSH key(s)"
fi

# =================================================================
# 3. Export Git Configuration
# =================================================================
log_info "💾 Exporting Git configuration..."

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
    
    log_success "Exported Git configuration"
    log_info "  Name: $GIT_NAME"
    log_info "  Email: $GIT_EMAIL"
    log_info "  GPG Key: ${GIT_GPG_KEY:-'(none)'}"
else
    log_warning "No Git user configuration found"
    echo "# No Git configuration found" > "$EXPORT_DIR/git-config.sh"
fi

# =================================================================
# 4. Export GPG Keys
# =================================================================
log_info "🔐 Exporting GPG keys..."

if command -v gpg &> /dev/null; then
    # Check if any secret keys exist
    SECRET_KEYS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "^sec" || echo "0")
    
    if [[ $SECRET_KEYS -gt 0 ]]; then
        log_info "Found $SECRET_KEYS secret key(s). Exporting..."
        
        # Export public keys
        if gpg --export --armor > "$EXPORT_DIR/gpg/gpg-public-keys.asc"; then
            log_success "Exported GPG public keys"
        else
            log_error "Failed to export GPG public keys"
        fi
        
        # Export private keys (most sensitive!)
        if gpg --export-secret-keys --armor > "$EXPORT_DIR/gpg/gpg-private-keys.asc"; then
            log_success "Exported GPG private keys"
            chmod 600 "$EXPORT_DIR/gpg/gpg-private-keys.asc"  # Extra security
        else
            log_error "Failed to export GPG private keys"
        fi
        
        # Export trust database
        if gpg --export-ownertrust > "$EXPORT_DIR/gpg/gpg-trust.txt"; then
            log_success "Exported GPG trust database"
        else
            log_warning "Failed to export GPG trust database"
        fi
        
        # Save key list for reference
        gpg --list-secret-keys --keyid-format LONG > "$EXPORT_DIR/gpg/key-list.txt"
        log_success "Saved GPG key list for reference"
        
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
log_info "📝 Creating transfer instructions..."

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
log_info "📦 Creating secure archive..."

read -p "Create password-protected zip archive? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    ARCHIVE_NAME="don-keys-$(date +%Y%m%d-%H%M%S).zip"
    
    # Create password-protected archive
    if command -v zip &> /dev/null; then
        echo "Enter password for the archive (will be hidden):"
        zip -er "$HOME/$ARCHIVE_NAME" "$EXPORT_DIR"
        
        if [[ $? -eq 0 ]]; then
            log_success "Created encrypted archive: ~/$ARCHIVE_NAME"
            log_info "You can now transfer the archive file instead of the folder"
        else
            log_error "Failed to create archive"
        fi
    else
        log_warning "zip command not available - skipping archive creation"
    fi
fi

# =================================================================
# 6. Summary and Next Steps
# =================================================================
log_success "🎉 Key export completed!"
echo ""
log_info "📋 Export Summary:"
echo "  • Location: $EXPORT_DIR"
echo "  • SSH keys: $(ls "$EXPORT_DIR/ssh" 2>/dev/null | wc -l | tr -d ' ') files"
echo "  • GPG keys: $(ls "$EXPORT_DIR/gpg" 2>/dev/null | wc -l | tr -d ' ') files"
echo ""
log_info "📱 Transfer Options:"
echo "  1. AirDrop the folder to your new Mac"
echo "  2. Copy to encrypted USB drive"
echo "  3. Use the password-protected zip archive (if created)"
echo ""
log_info "🔄 Next Steps:"
echo "  1. Transfer '$EXPORT_DIR' to your new Mac"
echo "  2. Run: ./scripts/import-keys-don.sh ~/path/to/export"
echo "  3. Verify keys work on new Mac"
echo "  4. Securely delete this export: rm -rf '$EXPORT_DIR'"
echo ""
log_warning "🔒 Security Reminder: This export contains private keys!"
log_info "Keep it secure and delete it after successful transfer."