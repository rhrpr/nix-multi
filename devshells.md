# Development Shells

This repo exposes four development shells via `flake.nix`. They work on both `aarch64-darwin` (macOS) and `x86_64-linux`.

## Entering a shell

```bash
# From the repo root (any shell):
nix develop .#flutter     # Flutter — iOS, Android, Web, macOS desktop
nix develop .#web         # Node.js, TypeScript, ESLint, Prettier
nix develop .#python      # Python 3, pip, virtualenv, linting
nix develop .#rust        # Rust stable, cargo tools, rust-analyzer

# Default shell (just treefmt for formatting):
nix develop
```

For a persistent shell in a project directory, add a `flake.nix` that references this config, or use `direnv`:

```bash
# .envrc  (requires direnv + nix-direnv)
use flake /Users/hrpr/.config/nix-multi#flutter
```

---

## Flutter shell (`nix develop .#flutter`)

Full cross-platform Flutter environment for iOS, Android, Web, and macOS desktop.

### What's included

| Category | Tools |
|---|---|
| SDK | `flutter`, `dart` |
| Android | Android SDK (API 34/35), platform-tools, build-tools 34.0.0, NDK r25c |
| Java | JDK 17 (required by Gradle 8.x and Flutter 3.x) |
| iOS (macOS) | `cocoapods`, `ios-deploy`, `libimobiledevice`, `ideviceinstaller` |
| Web | `nodejs_20`, `firebase-tools`, Chrome auto-detected |
| Build | `cmake`, `ninja`, `clang` (Linux), `gtk3` (Linux) |
| Utilities | `git`, `gh`, `curl`, `unzip`, `lcov` |

### Prerequisites (macOS / nix-darwin)

These are **not** managed by the devshell and must be installed separately. All are already in `modules/darwin/apps.nix`:

| Requirement | How it's installed | Purpose |
|---|---|---|
| Xcode | `masApps.Xcode` (App Store) | iOS/macOS compilation, Simulator |
| Xcode Command Line Tools | `xcode-select --install` | compilers, SDKs |
| Android Studio | install manually from developer.android.com/studio | AVD emulator on Apple Silicon |
| Google Chrome | `casks.google-chrome` (Homebrew) | `flutter run -d chrome` |
| CocoaPods gem cache | `pod install` on first use | resolves iOS dependencies |
| fastlane | `brews.fastlane` (Homebrew) | CI/CD deployment |

### First-time setup

```bash
nix develop .#flutter

# 1. Verify environment
flutter doctor -v

# 2. Accept any remaining Android licenses
flutter doctor --android-licenses

# 3. Configure Xcode (macOS)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# 4. Install CocoaPods dependencies (per project)
cd ios && pod install
```

### Environment variables set automatically

```
FLUTTER_ROOT       — Flutter SDK path (nix store)
ANDROID_HOME       — Android SDK root
ANDROID_SDK_ROOT   — same as ANDROID_HOME (alias)
JAVA_HOME          — JDK 17
CHROME_EXECUTABLE  — path to Chrome/Brave (macOS) or chromium (Linux)
DEVELOPER_DIR      — Xcode developer dir (macOS, if Xcode installed)
COCOAPODS_DISABLE_STATS — set to true (no telemetry)
```

### Running on each platform

```bash
# Android (requires connected device or running emulator)
flutter run -d android

# Android emulator (create AVD in Android Studio first)
flutter emulators --launch <emulator-id>
flutter run

# iOS Simulator (macOS only, requires Xcode)
open -a Simulator
flutter run -d ios

# iOS physical device
flutter run -d <device-id>

# Web
flutter run -d chrome
flutter run -d web-server --web-port 8080

# macOS desktop
flutter run -d macos

# Release builds
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android AAB (Play Store)
flutter build ipa --release          # iOS IPA (requires Xcode)
flutter build web --release          # Web
flutter build macos --release        # macOS app bundle
```

### Android emulator on Apple Silicon

The nixpkgs Android emulator does not run on `aarch64-darwin`. Use Android Studio's built-in AVD Manager instead:

1. Install Android Studio manually (or via `brew install --cask android-studio`)
2. Open **Tools > Device Manager > Create Virtual Device**
3. Choose an ARM64 system image (e.g., `arm64-v8a`)
4. Start the emulator, then `flutter run -d android` from within the devshell

### Troubleshooting

```bash
# Full diagnostics
flutter doctor -v

# Re-accept Android licenses
flutter doctor --android-licenses

# Clear Flutter cache
flutter clean && flutter pub get

# Reset CocoaPods (iOS)
cd ios
rm -rf Pods Podfile.lock
pod install

# Check connected devices
flutter devices

# Verbose run output
flutter run -v
```

---

## Web shell (`nix develop .#web`)

Node.js environment with TypeScript and linting tools.

```
node, yarn, typescript, eslint, prettier, treefmt
```

---

## Python shell (`nix develop .#python`)

Python 3 with a virtualenv auto-created in `.venv/`.

```
python3, pip, virtualenv, pylint, black, isort, treefmt
```

---

## Rust shell (`nix develop .#rust`)

Rust stable with the standard cargo workflow tools.

```
rustc, cargo, rustfmt, rust-analyzer, clippy
cargo-watch, cargo-edit, cargo-audit, cargo-outdated
```

Aliases: `cb` (build), `cr` (run), `ct` (test), `cc` (check), `cf` (fmt), `ccl` (clippy)

---

## Tips

**Stay in the shell across multiple terminals**

```bash
# Use tmux (already in PATH on this system)
tmux new-session -s flutter
nix develop .#flutter
```

**IDE integration**

For VS Code, install the `Nix Environment Selector` extension and point it at the flake. For Cursor/JetBrains, launch the IDE from inside the active devshell so it inherits all env vars:

```bash
nix develop .#flutter --command cursor .
nix develop .#flutter --command idea-community .
```

**Run a single command without entering the shell**

```bash
nix develop .#flutter --command flutter doctor
nix develop .#flutter --command flutter build apk
```
