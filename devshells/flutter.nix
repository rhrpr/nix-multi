{ pkgs, treefmtWrapper }:

let
  isMacOS = pkgs.stdenv.hostPlatform.isDarwin;
  isMacosArm = isMacOS && pkgs.stdenv.isAarch64;

  androidSdk = pkgs.androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "37.0.1";
    buildToolsVersions = [
      "34.0.0"
      "36.0.0"
    ];
    platformVersions = [
      "27"
      "33"
      "34"
      "35"
      "36"
    ];
    includeSources = false;
    includeSystemImages = true;
    # Apple Silicon only has google_apis arm64-v8a images; x86 hosts use google_apis_playstore
    systemImageTypes = if isMacosArm then [ "google_apis" ] else [ "google_apis_playstore" ];
    abiVersions = if isMacosArm then [ "arm64-v8a" ] else [ "x86" ];
    # nixpkgs emulator broken on Apple Silicon; use Android Studio's emulator
    includeEmulator = !isMacosArm;
    emulatorVersion = "35.6.9";
    includeNDK = true;
    # r25c — Flutter's officially recommended NDK version
    ndkVersion = "25.2.9519653";
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;
  };

  # iOS tools — macOS only
  iosPackages = pkgs.lib.optionals isMacOS (
    with pkgs;
    [
      cocoapods
      ios-deploy
      libimobiledevice
      ideviceinstaller
    ]
  );

  # Linux desktop / web packages
  linuxPackages = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (
    with pkgs;
    [
      chromium
      pkg-config
      gtk3
      glib
      clang
    ]
  );
in
pkgs.mkShell {
  name = "flutter-development";

  packages =
    with pkgs;
    [
      # Flutter / Dart SDK
      flutter
      dart

      # Android toolchain
      androidSdk.platform-tools
      jdk17

      # Web tooling
      nodejs_22
      firebase-tools

      # Native build tools
      cmake
      ninja

      # Utilities
      git
      gh
      curl
      unzip
      lcov

      # Formatting
      treefmtWrapper
      nixfmt
      prettier
    ]
    ++ iosPackages
    ++ linuxPackages;

  shellHook = ''
    # ── Flutter ────────────────────────────────────────────────────────────
    export FLUTTER_ROOT="${pkgs.flutter}"

    # ── Android ────────────────────────────────────────────────────────────
    # The composed SDK is read-only in the Nix store, so its licenses/ dir
    # can't be updated — and Google rotated the android-sdk-license hash,
    # which nixpkgs hasn't caught up with, so `flutter doctor` reports "Some
    # Android licenses not accepted". Two more nixpkgs quirks compound it:
    #   * the legacy tools/bin/sdkmanager crashes on JDK 11+ (javax.xml.bind
    #     was removed), and it's Flutter's fallback;
    #   * the modern cmdline-tools sdkmanager wrapper hardcodes --sdk_root to
    #     the store SDK, so it always checks the un-fixable store licenses.
    # Fix: a writable overlay SDK (symlinks into the store) with a real
    # licenses/ dir, and re-wrapped sdkmanager/avdmanager that re-point
    # --sdk_root at the overlay (the last --sdk_root on the line wins).
    _android_store="${androidSdk.androidsdk}/libexec/android-sdk"
    export ANDROID_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}/flutter-devshell/android-sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    # Rebuild from scratch — it's only symlinks, and a stale one pointing
    # into the read-only store would break the writes below.
    rm -rf "$ANDROID_HOME"
    mkdir -p "$ANDROID_HOME/licenses" "$ANDROID_HOME/cmdline-tools/latest/bin"
    for _entry in "$_android_store"/*; do
      case "$(basename "$_entry")" in
        licenses | cmdline-tools) ;;
        *) ln -sfn "$_entry" "$ANDROID_HOME/$(basename "$_entry")" ;;
      esac
    done

    _ctsrc="$_android_store/cmdline-tools/$(ls -1 "$_android_store/cmdline-tools" | sort -V | tail -1)"
    for _f in "$_ctsrc"/*; do
      [ "$(basename "$_f")" = bin ] || ln -sfn "$_f" "$ANDROID_HOME/cmdline-tools/latest/$(basename "$_f")"
    done
    for _f in "$_ctsrc"/bin/*; do
      _dst="$ANDROID_HOME/cmdline-tools/latest/bin/$(basename "$_f")"
      case "$(basename "$_f")" in
        sdkmanager | avdmanager)
          printf '#!/bin/sh\nexec "%s" --sdk_root="%s" "$@"\n' "$_f" "$ANDROID_HOME" > "$_dst"
          chmod +x "$_dst"
          ;;
        *) ln -sfn "$_f" "$_dst" ;;
      esac
    done

    export JAVA_HOME="${pkgs.jdk17}"
    export PATH="$PATH:$ANDROID_HOME/platform-tools"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
    # tools/bin deliberately omitted — its sdkmanager/avdmanager are the
    # broken legacy ones; cmdline-tools/latest provides working replacements.

    # Seed the rotated android-sdk-license hash, then let sdkmanager write
    # the authoritative set for every installed package into the overlay.
    printf '\n%s\n%s\n' \
      '24333f8a63b6825ea9c5514f83c2829b004d1fee' \
      'd56f5187479451eabf01fb78af6dfcb131a6481e' \
      > "$ANDROID_HOME/licenses/android-sdk-license"
    yes | sdkmanager --licenses >/dev/null 2>&1 || true

    flutter config --android-sdk "$ANDROID_HOME" &>/dev/null || true
    flutter config --jdk-dir "${pkgs.jdk17}" &>/dev/null || true

    # Belt-and-braces: accept every license through Flutter's own path too,
    # so `flutter doctor` is green on first shell entry.
    yes | flutter doctor --android-licenses >/dev/null 2>&1 || true

    # ── Web — Chrome / Chromium ────────────────────────────────────────────
    ${
      if isMacOS then
        ''
          for _chrome in \
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
            "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
            "/Applications/Chromium.app/Contents/MacOS/Chromium"; do
            if [ -f "$_chrome" ]; then
              export CHROME_EXECUTABLE="$_chrome"
              break
            fi
          done
        ''
      else
        ''
          export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"
        ''
    }

    # ── iOS (macOS only) ───────────────────────────────────────────────────
    ${
      if isMacOS then
        ''
          export COCOAPODS_DISABLE_STATS=true

          # nixpkgs' stdenv bakes DEVELOPER_DIR plus an xcbuild
          # xcrun/xcodebuild/xcode-select into the env, all pointing at a
          # Nix apple-sdk with no iOS simulator SDK — Flutter then reports
          # "Could not find SDK Platform Version" / "Unable to find the
          # iPhone Simulator SDK". Clear it and point the toolchain back at
          # the real Xcode. `/usr/bin/xcode-select -p` honours DEVELOPER_DIR,
          # so it must be unset *before* we query it.
          unset DEVELOPER_DIR SDKROOT
          if _dev="$(/usr/bin/xcode-select -p 2>/dev/null)" \
            && [ -d "$_dev/Platforms/iPhoneSimulator.platform" ]; then
            export DEVELOPER_DIR="$_dev"
            _xcode_shim="''${XDG_CACHE_HOME:-$HOME/.cache}/flutter-devshell/xcode-bin"
            mkdir -p "$_xcode_shim"
            for _t in xcrun xcodebuild xcode-select PlistBuddy; do
              [ -e "/usr/bin/$_t" ] && ln -sfn "/usr/bin/$_t" "$_xcode_shim/$_t"
            done
            export PATH="$_xcode_shim:$PATH"

            # Xcode 16+ ships without the iOS platform bundle; Flutter then
            # reports "Unable to find the iPhone Simulator SDK". Fetch it once
            # (idempotent — a no-op when already installed).
            if ! /usr/bin/xcrun --sdk iphonesimulator --show-sdk-path &>/dev/null; then
              echo "  Downloading the iOS platform (one-time, large)…"
              /usr/bin/xcodebuild -downloadPlatform iOS 2>/dev/null || true
            fi
          else
            echo "  WARNING: real Xcode not found — iOS builds unavailable (install Xcode from the App Store)"
          fi
        ''
      else
        ""
    }

    # ── Enable Flutter target platforms ────────────────────────────────────
    flutter config --enable-web &>/dev/null || true
    ${
      if isMacOS then
        ''
          flutter config --enable-macos-desktop &>/dev/null || true
          flutter config --enable-ios &>/dev/null || true
        ''
      else
        ''
          flutter config --enable-linux-desktop &>/dev/null || true
        ''
    }

    # ── Status ─────────────────────────────────────────────────────────────
    echo ""
    echo "Flutter ${pkgs.flutter.version} development environment"
    echo "  Platforms : Android | Web${if isMacOS then " | iOS | macOS" else " | Linux"}"
    echo "  Java      : ${pkgs.jdk17.version}"
    ${
      if isMacosArm then
        ''
          echo "  Android   : API 27/33/34/35/36, NDK r25c, build-tools 34.0.0+36.0.0, system-images google_apis arm64-v8a"
          echo ""
          echo "  AVD setup (run once to create emulators):"
          echo "    avdmanager create avd -n pixel_api27 -k 'system-images;android-27;google_apis;arm64-v8a' --device pixel"
          echo "    avdmanager create avd -n pixel_api33 -k 'system-images;android-33;google_apis;arm64-v8a' --device pixel"
          echo "    avdmanager create avd -n pixel_api34 -k 'system-images;android-34;google_apis;arm64-v8a' --device pixel"
          echo "    avdmanager create avd -n pixel_api35 -k 'system-images;android-35;google_apis;arm64-v8a' --device pixel"
          echo "    avdmanager create avd -n pixel_api36 -k 'system-images;android-36;google_apis;arm64-v8a' --device pixel"
          echo "  Then launch with: flutter emulators --launch pixel_api<version>"
        ''
      else
        ''
          echo "  Android   : API 27/33/34/35/36, NDK r25c, build-tools 34.0.0+36.0.0, system-images google_apis_playstore x86"
          echo ""
          echo "  AVD setup (run once to create emulators):"
          echo "    avdmanager create avd -n pixel_api27 -k 'system-images;android-27;google_apis_playstore;x86' --device pixel"
          echo "    avdmanager create avd -n pixel_api33 -k 'system-images;android-33;google_apis_playstore;x86' --device pixel"
          echo "    avdmanager create avd -n pixel_api34 -k 'system-images;android-34;google_apis_playstore;x86' --device pixel"
          echo "    avdmanager create avd -n pixel_api35 -k 'system-images;android-35;google_apis_playstore;x86' --device pixel"
          echo "    avdmanager create avd -n pixel_api36 -k 'system-images;android-36;google_apis_playstore;x86' --device pixel"
          echo "  Then launch with: flutter emulators --launch pixel_api<version>"
        ''
    }
    ${
      if isMacOS then
        ''
          echo "  CocoaPods : $(pod --version 2>/dev/null || echo 'unavailable')"
          if ! xcode-select -p &>/dev/null 2>&1; then
            echo ""
            echo "  WARNING: Xcode not found — install from the App Store for iOS builds"
          fi
          ${
            if isMacosArm then
              ''
                echo "  NOTE: Android Studio emulator preferred on Apple Silicon"
                echo "        Install from https://developer.android.com/studio"
              ''
            else
              ""
          }
        ''
      else
        ""
    }
    echo ""
    echo "  Run 'flutter doctor -v' to verify your full environment"
    echo ""
  '';
}
