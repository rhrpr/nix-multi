{ pkgs, treefmtWrapper }:

let
  # Create a properly configured Android SDK
  androidSdk = pkgs.androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.2";
    buildToolsVersions = [ "30.0.3" ];
    platformVersions = [ "33" ];
    includeSources = false;
    includeSystemImages = false;
    includeEmulator = true;
    emulatorVersion = "35.6.9";
    includeNDK = true;
    ndkVersion = "25.2.9519653";
  };

  # Check if we're on macOS ARM64
  isMacosArm = pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64;
in
pkgs.mkShell {
  name = "flutter-development";
  buildInputs = with pkgs; [
    # Flutter and Dart
    flutter
    dart

    # Android development - conditionally include Android Studio
    (lib.optional (!isMacosArm) androidStudioPackages.stable)
    androidSdk.platform-tools
    jdk11

    # iOS development (macOS specific)
    cocoapods

    # General development tools
    git
    gh
    wget

    # Firebase tools for Flutter development
    nodePackages.firebase-tools

    # Build utilities
    cmake
    ninja

    # Add treefmt and formatters
    treefmtWrapper
    nixfmt-rfc-style
    nodePackages.prettier
  ];

  # Environment variables
  shellHook = ''
    # Flutter environment setup
    export FLUTTER_ROOT=${pkgs.flutter}

    # Android environment setup
    export ANDROID_HOME=${androidSdk.androidsdk}/libexec/android-sdk
    export ANDROID_SDK_ROOT=$ANDROID_HOME
    export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

    # Accept Android SDK licenses automatically
    yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses &>/dev/null || true

    # iOS environment setup (macOS specific)
    export COCOAPODS_DISABLE_STATS=true

    echo "🚀 Flutter development environment activated!"
    echo "Flutter SDK: ${pkgs.flutter.version}"

    # Display message about Android Studio on ARM macOS
    ${
      if isMacosArm then
        ''
          echo ""
          echo "⚠️  Note: Android Studio is not available from nixpkgs for Apple Silicon."
          echo "Please install Android Studio manually from:"
          echo "https://developer.android.com/studio"
        ''
      else
        ""
    }

    echo ""
    echo "Run 'flutter doctor' to verify your setup"
  '';
}
