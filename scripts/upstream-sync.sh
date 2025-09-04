#!/usr/bin/env bash

# =================================================================
# Upstream Sync Script
# =================================================================
# This script safely merges changes from the upstream repository
# (mathiasbynens/dotfiles) while preserving Don's customizations.
# 
# Don's Custom Files (protected during sync):
# • scripts/.zshrc - Don's zsh customizations
# • .zshrc - Don's customized version  
# • scripts/brew-don.sh - Don's additional packages
# • scripts/git-setup-don.sh - Don's git configuration script
# • README-don.md - Don's setup instructions (main documentation)
# • starship.toml - Don's prompt configuration
# • scripts/KEY-TRANSFER-GUIDE.md - Don's key transfer guide
# • scripts/setup-new-mac.sh - Don's main installer
# • scripts/install-fonts.sh - Don's font installer
# • scripts/export-keys-don.sh - Don's key export automation
# • scripts/import-keys-don.sh - Don's key import automation
# • scripts/upstream-sync.sh - This script
#
# README.md Strategy:
# • README.md will be overwritten with upstream content during sync
# • Then automatically updated to point to README-don.md
# • This prevents merge conflicts while maintaining Don's documentation
# 
# Usage: ./scripts/upstream-sync.sh
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

# Ensure we're in the dotfiles directory
cd "$(dirname "${BASH_SOURCE[0]}")/.."

log_info "🔄 Starting upstream sync process..."

# =================================================================
# 1. Safety Checks
# =================================================================
log_info "Performing safety checks..."

# Check if we're in a git repository
if [[ ! -d .git ]]; then
    log_error "Not in a git repository! Please run from dotfiles directory."
    exit 1
fi

# Check if upstream remote exists
if ! git remote | grep -q "upstream"; then
    log_warning "Upstream remote not found. Adding it..."
    git remote add upstream https://github.com/mathiasbynens/dotfiles.git
    log_success "Upstream remote added"
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    log_error "You have uncommitted changes. Please commit or stash them first:"
    git status --short
    exit 1
fi

# =================================================================
# 2. Fetch Latest Changes
# =================================================================
log_info "Fetching latest changes from upstream..."
git fetch upstream

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
log_info "Current branch: $CURRENT_BRANCH"

# =================================================================
# 3. Show What Will Be Updated
# =================================================================
UPSTREAM_COMMITS=$(git rev-list --count HEAD..upstream/master 2>/dev/null || echo "0")
if [[ $UPSTREAM_COMMITS -eq 0 ]]; then
    log_success "✅ Already up to date with upstream!"
    exit 0
fi

log_info "📋 Found $UPSTREAM_COMMITS new commits from upstream:"
git log --oneline HEAD..upstream/master | head -10
if [[ $UPSTREAM_COMMITS -gt 10 ]]; then
    echo "   ... and $((UPSTREAM_COMMITS - 10)) more commits"
fi
echo ""

# =================================================================
# 4. Confirm Update
# =================================================================
read -p "🤔 Continue with upstream sync? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Sync cancelled by user"
    exit 0
fi

# =================================================================
# 5. Create Backup Branch
# =================================================================
BACKUP_BRANCH="backup-before-sync-$(date +%Y%m%d-%H%M%S)"
log_info "Creating backup branch: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH"
log_success "Backup created: $BACKUP_BRANCH"

# =================================================================
# 6. Perform the Merge/Rebase
# =================================================================
log_info "🚀 Syncing with upstream..."

# Try rebase first (cleaner history)
if git rebase upstream/master; then
    log_success "✅ Clean rebase completed!"
else
    log_warning "⚠️  Rebase failed, trying merge instead..."
    git rebase --abort
    
    if git merge upstream/master; then
        log_success "✅ Merge completed!"
    else
        log_error "❌ Merge failed! Please resolve conflicts manually."
        log_info "Your backup is saved in branch: $BACKUP_BRANCH"
        log_info "To restore: git checkout $BACKUP_BRANCH"
        exit 1
    fi
fi

# =================================================================
# 7. Verification
# =================================================================
log_info "🔍 Verifying sync..."

# Check that Don's custom files are still present
CUSTOM_FILES=(
    "scripts/.zshrc" 
    "scripts/brew-don.sh"
    "scripts/git-setup-don.sh" 
    "README-don.md" 
    "starship.toml"
    ".zshrc"
    "scripts/KEY-TRANSFER-GUIDE.md"
    "scripts/setup-new-mac.sh"
    "scripts/install-fonts.sh"
    "scripts/export-keys-don.sh"
    "scripts/import-keys-don.sh"
    "scripts/upstream-sync.sh"
)
# Note: README.md is NOT protected - it will be overwritten with upstream content
MISSING_FILES=()

for file in "${CUSTOM_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        MISSING_FILES+=("$file")
    fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    log_error "❌ Some of Don's custom files are missing:"
    printf '%s\n' "${MISSING_FILES[@]}"
    log_info "Your backup is saved in branch: $BACKUP_BRANCH"
    exit 1
fi

# =================================================================
# 7b. Post-Sync: Update README.md to point to Don's version
# =================================================================
log_info "📝 Updating README.md to reference Don's setup guide..."

# Create a simple README.md that points to README-don.md
cat > README.md << 'EOF'
# Don's Dotfiles

> **🚀 For the complete setup guide and installation instructions, see [README-don.md](./README-don.md)**

This is Don's customized fork of [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles) with modern development tools and streamlined setup process.

## Quick Start

```bash
git clone https://github.com/DonJayamanne/dotfiles.git && cd dotfiles
./scripts/setup-new-mac.sh
```

**📖 Full documentation:** [README-don.md](./README-don.md)

---

## Original Upstream Documentation

For the original dotfiles documentation from Mathias Bynens, see the upstream repository: https://github.com/mathiasbynens/dotfiles

The upstream README.md is preserved in this fork but not used as the primary documentation to avoid merge conflicts during upstream syncing.
EOF

log_success "README.md updated to point to Don's guide"

# =================================================================
# 8. Success Summary
# =================================================================
log_success "🎉 Upstream sync completed successfully!"
echo ""
log_info "📊 Summary:"
echo "  • Synced $UPSTREAM_COMMITS commits from upstream"
echo "  • All your customizations preserved"
echo "  • Backup branch: $BACKUP_BRANCH"
echo ""
log_info "🧹 Cleanup (optional):"
echo "  To remove backup branch: git branch -d $BACKUP_BRANCH"
echo ""
log_info "🚀 Next steps:"
echo "  • Test your setup: source ~/.zshrc"
echo "  • Run setup script: ./scripts/setup-new-mac.sh --check"
echo ""
log_success "Happy coding! ✨"