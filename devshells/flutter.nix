{ pkgs ? import <nixpkgs> {}, treefmtWrapper }:

pkgs.mkShell {
  name = "flutter-development";
  buildInputs = with pkgs; [
    # Flutter and Dart
    flutter
    dart
    
    # Android development
    androidStudioPackages.stable
    androidenv.androidPkgs_9_0.platform-tools
    jdk11 # Flutter recommends JDK 11 for Android development
    
    # iOS development (macOS specific)
    cocoapods
    xcodeenv.compilers.xcode_13_2
    
    # General development tools
    git
    gh # GitHub CLI
    rsync
    wget
    
    # Debugging and analysis
    clang # For native code
    lldb # Debugger
    
    # Build utilities
    cmake
    ninja
    
    # Add treefmt and formatters
    treefmtWrapper
    nixfmt-rfc-style
    shfmt
    nodePackages.prettier # For formatting markdown and other files
  ];
  
  # Environment variables
  shellHook = ''
    # Flutter environment setup
    export FLUTTER_ROOT=${pkgs.flutter}
    
    # Android environment setup
    export ANDROID_HOME=${pkgs.androidenv.androidPkgs_9_0.androidsdk}/libexec/android-sdk
    export ANDROID_SDK_ROOT=$ANDROID_HOME
    export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
    
    # iOS environment setup (macOS specific)
    export COCOAPODS_DISABLE_STATS=true
    
    # Use a local pub cache to avoid permission issues
    export PUB_CACHE=$(pwd)/.pub-cache
    
    # Display welcome message
    echo "🚀 Flutter development environment activated!"
    echo "Flutter SDK: ${pkgs.flutter.version}"
    echo "Dart SDK: ${pkgs.dart.version}"
    echo "treefmt available for code formatting"
    echo ""
    echo "Run 'flutter doctor' to verify your setup"
  '';
  
  # VS Code settings for Flutter development (if needed)
  # These would need to be manually added to your VS Code settings
  # but are here for reference
  vscodeSettings = {
    "dart.flutterSdkPath" = "${pkgs.flutter}";
    "dart.sdkPath" = "${pkgs.dart}/lib/dart";
  };
}