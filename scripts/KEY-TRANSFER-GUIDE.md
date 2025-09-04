# SSH and GPG Key Transfer Guide

This guide walks you through securely transferring your SSH and GPG keys from your old Mac to your new Mac.

## 🚀 Automated Key Transfer (Recommended)

**The easiest way to transfer your keys is using the automated scripts:**

### On your OLD Mac:
```bash
./scripts/export-keys-don.sh
```
This script will:
- Export all SSH keys (private, public, config, known_hosts)
- Export all GPG keys (private, public, trust database) 
- Export Git configuration (name, email, GPG key, preferences)
- Create secure backup with instructions

### On your NEW Mac:
```bash
./scripts/import-keys-don.sh ~/path/to/exported/keys
```
This script will:
- Import SSH and GPG keys with correct permissions
- Import and apply Git configuration via `git-setup-don.sh`
- Test imported keys
- Optionally clean up the export directory

**Continue reading below for manual transfer instructions if needed.**

---

## 🔑 Manual SSH Key Transfer

> **Note**: Use this section only if you prefer manual transfer over the automated scripts above.

Your current SSH key setup:
- **Ed25519 key**: `~/.ssh/id_ed25519` (private) and `~/.ssh/id_ed25519.pub` (public)
- **SSH config**: `~/.ssh/config`

### Step 1: Backup SSH Keys from Old Mac

```bash
# Create a secure backup directory
mkdir -p ~/key-backup/ssh

# Copy SSH keys (do this on your OLD Mac)
cp ~/.ssh/id_ed25519* ~/key-backup/ssh/
cp ~/.ssh/config ~/key-backup/ssh/

# Optional: Copy known_hosts if you want to preserve trusted hosts
cp ~/.ssh/known_hosts ~/key-backup/ssh/
```

### Step 2: Transfer to New Mac

Choose one of these methods:

**Option A: AirDrop (Recommended)**
- Select the `~/key-backup` folder and AirDrop to your new Mac

**Option B: USB Drive**
- Copy `~/key-backup` to an encrypted USB drive
- Transfer to new Mac

**Option C: Secure Cloud Storage**
- Zip with password: `zip -er ssh-keys.zip ~/key-backup`
- Upload to iCloud/Dropbox, download on new Mac, then delete from cloud

### Step 3: Install SSH Keys on New Mac

```bash
# Restore SSH keys (do this on your NEW Mac)
mkdir -p ~/.ssh
cp ~/key-backup/ssh/* ~/.ssh/

# Set correct permissions (IMPORTANT!)
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/config
chmod 644 ~/.ssh/known_hosts  # if you copied it

# Test the key
ssh -T git@github.com
```

## 🔐 Manual GPG Key Transfer

> **Note**: Use this section only if you prefer manual transfer over the automated scripts above.

Your current GPG key setup:
- **RSA 3072-bit key**: `5049E2207BCC4204` (for Don Jayamanne <don.jayamanne@outlook.com>)
- **Ed25519 key**: `6E3F5E00E1354B5F` (for Don Jayamanne <don.jayamanne@outlook.com>)
- **GPG Agent**: Configured to use `pinentry-mac` for macOS keychain integration

### Step 1: Export GPG Keys from Old Mac

```bash
# Export your public keys
gpg --export --armor > ~/key-backup/gpg-public-keys.asc

# Export your private keys (THIS IS SENSITIVE!)
gpg --export-secret-keys --armor > ~/key-backup/gpg-private-keys.asc

# Export trust database
gpg --export-ownertrust > ~/key-backup/gpg-trust.txt

# List your keys to confirm
gpg --list-secret-keys --keyid-format LONG
```

### Step 2: Transfer GPG Keys to New Mac

Use the same secure transfer method as SSH keys (AirDrop, encrypted USB, etc.)

### Step 3: Import GPG Keys on New Mac

```bash
# Import public keys
gpg --import ~/key-backup/gpg-public-keys.asc

# Import private keys
gpg --import ~/key-backup/gpg-private-keys.asc

# Import trust settings
gpg --import-ownertrust ~/key-backup/gpg-trust.txt

# Verify import
gpg --list-secret-keys --keyid-format LONG

# Test GPG (sign a test file)
echo "test" | gpg --clearsign
```

### Step 4: Configure Git with GPG (if you use signed commits)

**Automated approach (recommended):**
```bash
# The git-setup-don.sh script configures Git automatically based on imported keys
./scripts/git-setup-don.sh
```

**Manual approach:**
```bash
# Configure Git to use your GPG key for signing
git config --global user.signingkey 5049E2207BCC4204  # or your preferred key ID
git config --global commit.gpgsign true

# Test GPG signing
git commit --allow-empty -m "Test GPG signing"
```

## 🔒 macOS Keychain Integration

Your setup uses `pinentry-mac` to integrate GPG with macOS Keychain, so you don't have to remember your GPG passphrase. This is configured in your `~/.gnupg/gpg-agent.conf`:

```
pinentry-program /opt/homebrew/bin/pinentry-mac
default-cache-ttl 600
max-cache-ttl 7200
```

The new Mac setup script will configure this automatically, but you can verify with:

```bash
# Check if pinentry-mac is configured
cat ~/.gnupg/gpg-agent.conf

# Restart GPG agent to apply config
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

## 🧹 Cleanup (Important!)

After successfully transferring your keys:

```bash
# Securely delete the backup files
rm -rf ~/key-backup

# On old Mac, if you have backups there:
shred -vfz -n 3 ~/key-backup/gpg-private-keys.asc  # Linux
rm -P ~/key-backup/gpg-private-keys.asc            # macOS
```

## ✅ Verification Checklist

- [ ] SSH key works with GitHub/GitLab: `ssh -T git@github.com`
- [ ] GPG key imported successfully: `gpg --list-secret-keys`
- [ ] GPG signing works: `echo "test" | gpg --clearsign`
- [ ] Git signing configured: `git config --get user.signingkey`
- [ ] macOS Keychain stores GPG passphrase (test by signing something)
- [ ] Backup files securely deleted

## 🆘 Troubleshooting

### SSH Issues

```bash
# If SSH key is not recognized
ssh-add ~/.ssh/id_ed25519

# Check SSH agent
ssh-add -l

# Debug SSH connection
ssh -vT git@github.com
```

### GPG Issues

```bash
# If GPG agent is not working
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# Check GPG agent status
gpg-connect-agent 'getinfo version' /bye

# Re-configure pinentry if needed
echo "pinentry-program /opt/homebrew/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
```

### Git Signing Issues

```bash
# Test commit signing
git config --global gpg.program gpg
GIT_TRACE=1 git commit --allow-empty -m "test signing"
```

---

**Security Note**: Your private keys are extremely sensitive. Never share them or store them in unsecured locations. The GPG private key backup should be deleted immediately after successful import.