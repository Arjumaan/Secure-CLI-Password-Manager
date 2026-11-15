# SecureVault — Cross-Platform App (Windows .exe & Android .apk)

SecureVault is an offline, peer-to-peer encrypted password manager featuring:
- **One Login across Devices**: Synchronize encrypted credentials directly over local Wi-Fi between your Laptop (.exe) and Android phone (.apk) without any cloud dependency.
- **Minimal Clean Frosted UI**: A refined design system combining tactile **Neomorphism** (soft dual shadows, sunken inset input grooves) and ethereal **Glassmorphism** (frosted translucent cards with specular highlights).
- **Client-Side Zero-Knowledge**: Passwords are encrypted with AES-256 before leaving your device memory.

---

## 📁 Project Architecture

```
securevault_app/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart                      # App entry point & activity detector
│   ├── core/
│   │   ├── crypto/
│   │   │   └── vault_crypto.dart       # AES-256-GCM & PBKDF2 key derivation
│   │   ├── sync/
│   │   │   ├── sync_payload.dart      # Exchange packages & manifests
│   │   │   └── sync_service.dart      # Local Wi-Fi HTTP host & client engine
│   │   └── theme/
│   │       ├── app_colors.dart         # Neomorphic & glass design tokens
│   │       └── app_theme.dart          # Light frosted theme configuration
│   ├── models/
│   │   └── credential.dart             # Credential model with tombstone support
│   ├── services/
│   │   ├── auth_service.dart           # Master authentication & local biometrics
│   │   ├── password_generator.dart     # Password generator & entropy evaluator
│   │   ├── vault_service.dart          # In-memory vault CRUD & CRDT merge
│   │   └── vault_storage.dart          # Local persistent encrypted JSON storage
│   └── ui/
│       ├── widgets/
│       │   ├── frosted_glass_card.dart # BackdropFilter glass container
│       │   ├── neumorphic_box.dart     # Tactile extruded container
│       │   ├── neumorphic_input.dart   # Sunken inset text field
│       │   └── tactile_button.dart     # Springy micro-animated button
│       └── screens/
│           ├── lock_screen.dart        # Unlock & Master Setup Gateway
│           ├── dashboard_screen.dart   # Responsive dashboard (Desktop & Mobile)
│           ├── credential_sheet.dart   # Add / Edit / Delete modal
│           ├── generator_screen.dart   # Password generator suite with entropy meter
│           └── sync_screen.dart        # Local Wi-Fi sync hub with QR pairing
```

---

## 🛠️ Build & Compilation Guide

### Prerequisites
1. **Flutter SDK** (Version 3.19 or higher): [flutter.dev](https://flutter.dev)
2. **For Windows (.exe)**:
   - Visual Studio 2022 with "Desktop development with C++" workload installed.
3. **For Android (.apk)**:
   - Android Studio / Android SDK with Platform-Tools and JDK 17+.

---

### Step 1: Install Dependencies
```bash
cd securevault_app
flutter pub get
```

---

### Step 2: Build Windows Desktop (.exe)
```bash
flutter build windows --release
```
The compiled executable will be located at:
`build/windows/x64/runner/Release/securevault_app.exe`

---

### Step 3: Build Android (.apk)
```bash
flutter build apk --release
```
The compiled Android installer will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🔄 How Local Wi-Fi "One Login" Sync Works

1. **Laptop (.exe)**: Open SecureVault -> Navigate to **Wi-Fi Sync** -> Click **Start Host Server**. A dynamic pairing QR code and token are generated.
2. **Android (.apk)**: Open SecureVault -> Navigate to **Sync** -> Tap **Scan QR on Laptop** (or enter the IP and Token manually) -> Tap **Sync Now**.
3. **End-to-End Encrypted Transfer**:
   - Only encrypted ciphertext records are exchanged over your local Wi-Fi.
   - Credentials modified on either device are merged using timestamp resolution with tombstone preservation.
   - Master Password remains identical across both devices.
