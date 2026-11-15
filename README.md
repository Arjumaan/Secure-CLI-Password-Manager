# SecureVault — Modern Cross-Platform Password Manager

SecureVault is an offline, zero-knowledge, encrypted password manager engineered for privacy and security. It offers:
1. **Interactive CLI**: Fast terminal-based credential manager in Python.
2. **Minimal Clean Frosted Web Interface**: Modern Neomorphism + Glassmorphism UI with client-side Web Crypto API.
3. **Cross-Platform App (Flutter)**: Single unified codebase targeting **Windows Desktop (.exe)** and **Android (.apk)**.
4. **"One Login" Local Wi-Fi Sync**: Synchronize encrypted credentials between laptop and mobile phone over local Wi-Fi with zero third-party cloud dependency.

---

## ✨ Features & Architecture

- **Zero-Knowledge Encryption**: Uses PBKDF2 (SHA-256 with 480,000 iterations) for key derivation and AES-256-GCM / Fernet for symmetric credential encryption. Keys never touch persistent storage.
- **Built-in 2FA / TOTP Authenticator**: Live rolling 6-digit one-time passcodes with 30-second circular countdown timers.
- **Emergency Recovery Kit**: 12-word cryptographic recovery phrase and printable emergency backup sheet.
- **Decoy Vault (Duress Mode)**: Plausible deniability master password that seamlessly unlocks an isolated decoy vault with dummy records.
- **Multi-Category Vault**: Organize **🔑 Logins**, **💳 Payment Cards**, **📝 Secure Notes**, and **🪪 Identities**, plus **⭐ Favorites**.
- **Brand Logos / Auto-Favicon**: Automatic resolution of service logos (GitHub, Google, AWS, etc.) with monogram fallbacks.
- **Password History**: Encrypted historical password timeline with one-click restore.
- **Active Clipboard Auto-Wipe**: OS and browser clipboard memory actively cleared 30 seconds after copying credentials.
- **Encrypted `.svault` Backups**: Password-protected encrypted backups for offline air-gapped storage.
- **Command Palette (`Ctrl+K`)**: Instant spotlight search across all credentials from anywhere.

---

## 📁 Repository Structure

```
├── main.py                    # CLI main application loop
├── auth.py                    # CLI master password verification & bcrypt hashing
├── vault.py                   # CLI vault CRUD operations
├── crypto.py                  # CLI Fernet encryption & PBKDF2 derivation
├── utils.py                   # CLI password generator & table formatting
├── migrate_to_app.py          # Migration script bridging CLI data to the app
├── build_apps.bat             # Build helper script for Windows .exe & Android .apk
├── data/                      # Local CLI encrypted storage
│   ├── config.json            # Master password salt & bcrypt hash
│   └── vault.json             # Encrypted credentials store
├── web/                       # Modern Minimal Clean Frosted Web Application
│   ├── index.html             # Neomorphic + Glassmorphism UI markup
│   ├── style.css              # Design tokens (dual shadows, frosted blur, typography)
│   └── app.js                 # Web Crypto API engine & product features 2-10
└── securevault_app/           # Cross-Platform Flutter Codebase (Windows & Android)
    ├── pubspec.yaml           # Flutter dependencies (cryptography, local_auth, shelf)
    ├── README.md              # Flutter compilation and packaging guide
    └── lib/                   # Dart source code (screens, widgets, sync protocol)
```

---

## 🚀 Quick Start

### 1. Web Application (Neomorphism + Glassmorphism UI)
To run the interactive web app locally:
```bash
python -m http.server 8080 --directory web
```
Open **[http://localhost:8080](http://localhost:8080)** in your browser.

### 2. Python CLI Manager
```bash
pip install cryptography bcrypt
python main.py
```

### 3. Flutter Windows (.exe) & Android (.apk)
```bash
# Build Windows Desktop executable
cd securevault_app
flutter build windows --release

# Build Android APK
flutter build apk --release
```
*(Or run `build_apps.bat` directly on Windows).*

---

## 🔒 Security Model

- **Master Authentication**: Master passwords are never saved. Authenticated via bcrypt / HMAC verifiers.
- **Key Derivation**: 32-byte master encryption keys are derived dynamically in RAM using PBKDF2HMAC (SHA-256, 480,000 iterations).
- **Transport Security**: Local Wi-Fi sync exchanges only ciphertext blobs over TLS 1.3. Even if local Wi-Fi packets are intercepted, passwords cannot be decrypted without the master password.
