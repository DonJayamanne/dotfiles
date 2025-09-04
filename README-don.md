# Don's Dotfiles Setup Guide

> **🔥 Modern Mac Setup** - Complete au├── scripts/
    ├── setup-mac.sh       # ← Don's main installer
    ├── export-keys-don.sh # ← Key export automationation for new Mac development environment

This is Don's customized fork of [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles) with additional modern development tools and streamlined setup process.

## 🚀 Quick Setup for New Mac

**One command to set up everything:**

```bash
git clone https://github.com/DonJayamanne/dotfiles.git && cd dotfiles/scripts
./setup-mac.sh
```

⏱️ **Time:** ~15-30 minutes (depending on internet speed)

The script will:
- Prompt for your exported keys location (optional)
- Install Homebrew and all development tools
- Configure Git with GPG signing (if keys provided)
- Set up Zsh, Oh My Zsh, and Starship prompt
- Install programming fonts
- Configure macOS preferences (optional)

## 🎯 What Gets Installed

### **Core Development Stack**
- **Shell:** Zsh (latest) + Oh My Zsh + custom plugins
- **Prompt:** Starship (via Homebrew) with custom configuration
- **Languages:** Python (pyenv), Node.js (fnm via Homebrew), Rust (rustup)
- **Package Managers:** UV (Python), Homebrew, Cargo

### **Essential Development Tools**
- **Editors:** VS Code (stable & insiders), Xcode
- **Version Control:** Git + Git LFS + GitHub CLI
- **Containerization:** Docker Desktop
- **API Testing:** Postman
- **Security:** GPG Suite with macOS keychain integration

### **Modern CLI Improvements**
- `bat` → better `cat` with syntax highlighting
- `exa` → better `ls` with colors and icons
- `ripgrep` → faster `grep`
- `fd` → better `find`
- `tree` → directory visualization

### **Productivity Apps**
- Microsoft Edge, Slack, Rectangle (window management)
- Ollama (local AI), Okta Verify

### **Fonts & Aesthetics**
- Nerd Fonts: FiraCode, Monaspace, Symbols
- Custom Starship prompt with programming language detection

## 🔧 Architecture

### **Merge-Friendly Design**
This fork uses a **modular approach** to avoid merge conflicts:

```
├── README.md           # ← Upstream (automatically updated to point to README-don.md)
├── README-don.md       # ← This file (Don's instructions)
├── brew.sh             # ← Upstream (never modified)
├── scripts/brew-don.sh  # ← Don's additional packages
├── .zshrc              # ← Don's customized zsh config
├── scripts/.zshrc   # ← Don's additional zsh customizations (modular)
├── scripts/git-setup-don.sh # ← Don's git configuration script
├── starship.toml       # ← Don's prompt config
└── scripts/
    ├── setup-new-mac.sh   # ← Don's main installer
    ├── export-keys-don.sh # ← Key export automation
    ├── import-keys-don.sh # ← Key import automation
    └── upstream-sync.sh   # ← Easy upstream sync
```

### **Easy Upstream Syncing**
Get latest improvements from upstream with zero conflicts:

```bash
./scripts/upstream-sync.sh
```

This safely merges all upstream improvements while preserving your customizations.

## 📋 Post-Installation Steps

### 1. **Transfer Your Keys & Configuration**

**🚀 AUTOMATED (Recommended):**
```bash
# On OLD Mac: Export everything
./scripts/export-keys-don.sh
# This creates a folder with SSH keys, GPG keys, AND git configuration

# Transfer the exported folder to new Mac, then:
./scripts/import-keys-don.sh ~/path/to/exported/keys
# This imports keys AND saves git config for later use
```

✅ **This automated process exports/imports:**
- SSH keys (private & public) with correct permissions
- GPG keys (private, public & trust database)
- **Git configuration** (name, email, GPG key, preferences) - travels with keys!
- SSH config and known_hosts
- Key verification and testing

**📋 Manual Alternative:** Follow [`scripts/KEY-TRANSFER-GUIDE.md`](./scripts/KEY-TRANSFER-GUIDE.md) for step-by-step manual transfer.

### 2. **Configure Git (automated)**
Git configuration travels with your keys and is automatically handled:
1. `export-keys-don.sh` exports your git config FROM old Mac
2. `import-keys-don.sh` imports it TO new Mac (stored in `~/.config/don/`)
3. `git-setup-don.sh` applies the imported configuration
4. Sets up GPG signing, default branch, and all preferences

**Note:** Git setup happens automatically when you run `./setup-mac.sh` after importing keys.

### 3. **Restart Terminal**
```bash
source ~/.zshrc
# or restart Terminal.app
```

## 🛠 Manual Steps (Advanced Users Only)

> **Most users should just run `cd scripts && ./setup-mac.sh` above**

If you need to run individual components:

```bash
# Export keys from old Mac
./scripts/export-keys-don.sh

# Import keys on new Mac
./scripts/import-keys-don.sh ~/path/to/exported/keys

# Install development tools only
./scripts/brew-don.sh

# Configure Git only
./scripts/git-setup-don.sh

# Install fonts only
./scripts/install-fonts.sh

# Configure macOS only
./.macos
```

## 📱 Additional Applications

### Install These Apps Manually
Since GUI applications are commented out in `brew-don.sh`, install these manually:

#### **Development Tools**
- [**Visual Studio Code**](https://code.visualstudio.com/) - Main editor
- [**VS Code Insiders**](https://code.visualstudio.com/insiders/) - Preview builds
- [**Xcode**](https://apps.apple.com/us/app/xcode/id497799835) - iOS/macOS development (App Store)
- [**Docker Desktop**](https://www.docker.com/products/docker-desktop/) - Containerization
- [**Postman**](https://www.postman.com/downloads/) - API testing

#### **Browsers & Security**
- [**Microsoft Edge**](https://www.microsoft.com/en-us/edge) - Modern browser

#### **Productivity & Communication**
- [**Slack**](https://apps.apple.com/us/app/slack/id803453959) - Team communication (App Store)
- [**Rectangle**](https://rectangleapp.com/) - Window management
- [**Okta Verify**](https://apps.apple.com/us/app/okta-verify/id490179405) - 2FA authentication (App Store)

#### **AI & Development**
- [**Ollama**](https://ollama.ai/) - Local AI model runner


## 🔄 Maintaining Your Fork

### Update from Upstream
```bash
./scripts/upstream-sync.sh
```

### Add New Packages
- **CLI tools:** Add to `scripts/brew-don.sh` (all tools via Homebrew)
- **Zsh config:** Add to `scripts/.zshrc`
- **Setup steps:** Update `scripts/setup-mac.sh` (or individual scripts as needed)

### Backup Important Configs
The setup script automatically backs up existing configurations:
- `~/.zshrc.backup_YYYYMMDD_HHMMSS`
- `~/.config/starship.toml.backup_YYYYMMDD_HHMMSS`

## 🚀 Features

### **Smart Installation**
- ✅ Detects existing software and skips reinstallation
- ✅ Handles both Intel and Apple Silicon Macs
- ✅ Uses Homebrew for consistent package management (e.g., fnm, starship via brew)
- ✅ Backs up existing configurations before overwriting
- ✅ Provides clear progress logging with colors

### **Modern Development Environment**
- ✅ Latest versions of development tools
- ✅ Integrated GPG signing for commits
- ✅ VS Code integration for Python environments
- ✅ Fast Node.js switching with fnm (installed via Homebrew)

### **Zero-Conflict Upstream Merging**
- ✅ Your customizations in separate files
- ✅ One command to sync upstream changes
- ✅ Never lose your personal configurations

## 🎯 Philosophy

> **"Keep upstream pristine, extend with purpose"**

This setup maintains the excellent foundation from Mathias Bynens while adding modern development tools and a conflict-free update mechanism. You get the best of both worlds: proven dotfiles + bleeding-edge tools.

---

**Enjoy your perfectly configured development environment! 🎉**
