# Account Recovery & Key Backup Guide

## Overview

Skadoosh uses **encryption key-based authentication** instead of traditional passwords. Your encryption keys are the ONLY way to access your account and decrypt your notes. Without these keys, your account and all notes are permanently inaccessible.

## Critical Security Information

### ⚠️ What You MUST Understand

1. **Your encryption keys are stored ONLY on your device**
   - Keys are NOT stored on the server
   - Keys are NOT recoverable if lost
   - Clearing app data = losing keys = losing everything

2. **No backup = No recovery**
   - If you lose your device without a backup, your account is gone forever
   - If you uninstall the app without a backup, your account is gone forever
   - If you clear app data without a backup, your account is gone forever

3. **The backup file is your lifeline**
   - It contains your encryption keys
   - Anyone with this file can access your account
   - Store it securely (password manager, encrypted drive, etc.)

## How to Backup Your Account

### Method 1: From Device Management (Recommended)

1. Open Skadoosh app
2. Go to **Settings** → **Devices**
3. You'll see an **"Account Backup"** section
4. Tap **"Create Backup"** button
5. File will be saved to your Downloads folder as `skadoosh_backup_YYYY-MM-DD.json`
6. **IMMEDIATELY** move this file to a secure location:
   - Password manager (1Password, Bitwarden, etc.)
   - Encrypted cloud storage (Nextcloud, Cryptomator)
   - External encrypted USB drive
   - Another secure device

### Method 2: After Initial Registration

- When you create your account, you'll see a backup reminder dialog
- Tap **"Go to Backup"** to be taken to Device Management
- Follow steps from Method 1

## What's in the Backup File?

The backup file (`skadoosh_backup_YYYY-MM-DD.json`) contains:

```json
{
  "backup_version": "1.0",
  "timestamp": "2025-12-30T...",
  "account": {
    "username": "your_username",
    "userShareId": "username#abc123",
    "deviceId": "...",
    "fingerprint": "...",
    "groupName": "..."
  },
  "keys": {
    "publicKey": "{ RSA public key }",
    "privateKey": "{ RSA private key }"
  },
  "server": {
    "syncServerUrl": "https://your-server.com"
  }
}
```

### Security Notes:
- **NEVER share this file** with anyone
- **NEVER upload to public cloud** storage without encryption
- **NEVER commit to Git** repositories
- The private key can decrypt ALL your notes

## How to Restore Your Account

### Scenario 1: New Device
1. Install Skadoosh app
2. Go to **Settings** → **Devices**
3. Tap **"Restore"** button in Account Backup section
4. Select your backup file from secure storage
5. Your account will be restored with all keys
6. Go to **Settings** → **Sync** to configure sync and pull notes

### Scenario 2: Cleared App Data
Same as Scenario 1 - the restore process is identical

### Scenario 3: Lost Device
1. Get a new device
2. Install Skadoosh app
3. Use the backup file you stored securely
4. Follow Scenario 1 steps

## Best Practices

### 1. Create Multiple Backups
- Keep one in password manager
- Keep one on encrypted external drive
- Keep one in secure cloud storage
- Keep backups in different physical locations

### 2. Update Backups Regularly
- Create new backup if you pair with new devices
- Create new backup after major account changes
- Date stamps in filename help track backup age

### 3. Test Your Backup
- After creating backup, test restoring on another device
- Verify you can access the backup file
- Ensure you remember where you stored it

### 4. Secure Storage Options

**Recommended:**
- Password managers (1Password, Bitwarden, KeePassXC)
- Encrypted cloud (Nextcloud + Cryptomator)
- Hardware encrypted drives
- Self-hosted secure storage

**NOT Recommended:**
- Unencrypted cloud storage (Google Drive, Dropbox)
- Email attachments
- Public file sharing services
- Unencrypted USB drives

## Warning Signs You Need to Backup NOW

### 🔴 Critical - Backup Immediately:
- You just created your account
- You're about to factory reset your device
- You're about to switch to a new device
- You're about to uninstall/reinstall the app
- Your device is damaged/malfunctioning

### 🟡 Important - Backup Soon:
- It's been months since last backup
- You've paired with new devices
- You've changed device settings
- You're traveling with only one device

### 🟢 Good - You're Protected:
- You have recent backup (< 30 days old)
- Backup is stored in multiple secure locations
- You've tested restoration process
- You remember where backup is stored

## Frequently Asked Questions

### Q: Can the developers recover my account if I lose my keys?
**A: NO.** Your keys never reach the server. Even developers cannot recover your account.

### Q: What if I forget where I stored my backup?
**A: You're out of luck.** There is no recovery method. Always document where you store backups.

### Q: Can I use password instead of keys?
**A: No.** The app is designed for key-based authentication for maximum security. This is by design.

### Q: What happens to my notes if I lose keys?
**A: They're permanently inaccessible.** Notes are encrypted with your keys. Without keys, they're just encrypted data.

### Q: Can I export just my private key?
**A: No.** The backup system exports all necessary data as a complete package for easier restoration.

### Q: Is the backup file encrypted?
**A: No.** The backup file is JSON text. YOU must store it in an encrypted location (password manager, encrypted drive, etc.).

### Q: Can I email the backup file to myself?
**A: NOT RECOMMENDED.** Email is not secure. If someone intercepts it, they have full access to your account.

### Q: How often should I create backups?
**A: At minimum:**
- After account creation
- After pairing new devices
- Before major device changes
- Every 1-3 months

### Q: Can I share my backup with trusted family members?
**A: Only if you want them to have FULL ACCESS to all your notes.** The backup contains complete account access.

## Recovery Flow Diagram

```
┌─────────────────────────────────────┐
│  Lost Access to Account?            │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│  Do you have backup file?           │
└────┬─────────────────────┬──────────┘
     │ YES                 │ NO
     ▼                     ▼
┌─────────────┐   ┌──────────────────┐
│  RESTORE    │   │  ACCOUNT LOST    │
│  Use backup │   │  No recovery     │
│  file in    │   │  possible        │
│  app        │   └──────────────────┘
└─────────────┘
```

## Emergency Checklist

Before clearing app data, switching devices, or factory reset:

- [ ] Locate your most recent backup file
- [ ] Verify backup file can be opened (valid JSON)
- [ ] Backup file is stored in at least 2 different locations
- [ ] You have access to both backup locations
- [ ] Backup is less than 30 days old (optional but recommended)
- [ ] You've written down where backups are stored
- [ ] Close all sync operations before proceeding

## Support

If you have questions about account backup/recovery:

1. Check this guide first
2. Check the app's Device Management page for backup status
3. Test backup/restore on a secondary device before emergency
4. Remember: **Prevention is the only cure** - backup regularly!

## Version History

- **v1.0** (2025-12-30): Initial account backup/recovery system
  - Export to Downloads folder
  - Import from file picker
  - Backup reminders after registration
  - Backup status tracking
