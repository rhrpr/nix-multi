{ pkgs, treefmtWrapper }:

let
  isMacOS = pkgs.stdenv.hostPlatform.isDarwin;
  isMacosArm = isMacOS && pkgs.stdenv.isAarch64;

  androidSdk = pkgs.androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "37.0.1";
    buildToolsVersions = [ "34.0.0" ];
    platformVersions = [
      "27"
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
    export ANDROID_HOME="${androidSdk.androidsdk}/libexec/android-sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export JAVA_HOME="${pkgs.jdk17}"
    export PATH="$PATH:$ANDROID_HOME/platform-tools"
    export PATH="$PATH:$ANDROID_HOME/tools/bin"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

    # Accept Android SDK licenses
    yes | "$ANDROID_HOME/tools/bin/sdkmanager" --licenses &>/dev/null || true

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
          if xcode-select -p &>/dev/null 2>&1; then
            export DEVELOPER_DIR="$(xcode-select -p)"
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
          echo "  Android   : API 27/34/35/36, NDK r25c, build-tools 34.0.0, system-images google_apis arm64-v8a"
          echo ""
          echo "  AVD setup (run once to create emulators):"
          echo "    avdmanager create avd -n pixel_api27 -k 'system-images;android-27;google_apis;arm64-v8a' --device pixel"
          echo "    avdmanager create avd -n pixel_api34 -k 'system-images;android-34;google_apis;arm64-v8a' --device pixel"
          echo "    avdmanager create avd -n pixel_api35 -k 'system-images;android-35;google_apis;arm64-v8a' --device pixel"
          echo "    avdmanager create avd -n pixel_api36 -k 'system-images;android-36;google_apis;arm64-v8a' --device pixel"
          echo "  Then launch with: flutter emulators --launch pixel_api<version>"
        ''
      else
        ''
          echo "  Android   : API 27/34/35/36, NDK r25c, build-tools 34.0.0, system-images google_apis_playstore x86"
          echo ""
          echo "  AVD setup (run once to create emulators):"
          echo "    avdmanager create avd -n pixel_api27 -k 'system-images;android-27;google_apis_playstore;x86' --device pixel"
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
