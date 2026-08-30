{ pkgs, treefmtWrapper }:

let
  isMacOS = pkgs.stdenv.isDarwin;
  isMacosArm = isMacOS && pkgs.stdenv.isAarch64;

  androidSdk = pkgs.androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.2";
    buildToolsVersions = [ "34.0.0" ];
    platformVersions = [
      "34"
      "35"
    ];
    includeSources = false;
    # System images are large; create AVDs via Android Studio UI instead
    includeSystemImages = false;
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
  linuxPackages = pkgs.lib.optionals pkgs.stdenv.isLinux (
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
      nodejs_20
      nodePackages.firebase-tools

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
      nixfmt-rfc-style
      nodePackages.prettier
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
    echo "  Android   : API 34/35, NDK r25c, build-tools 34.0.0"
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
