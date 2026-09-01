{ lib, pkgs, username, ... }:
let
  sockseek = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "sockseek";
    version = "3.0.5";
    src = pkgs.fetchurl {
      url = "https://github.com/fiso64/sockseek/releases/download/v${version}/sockseek_${version}_osx-arm64.tar.gz";
      sha256 = "1l7dl1vrj7pskvp2l0f3dizzhyvak5s5b4i3sybrg2prg25hf63a";
    };
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/bin
      install -m755 sockseek $out/bin/sockseek
    '';
  };
  # stemdeck: DMG is APFS format; undmg only supports HFS — install manually
  # stemdeck = pkgs.stdenvNoCC.mkDerivation rec {
  #   pname = "stemdeck";
  #   version = "0.15.2";
  #   src = pkgs.fetchurl {
  #     url = "https://github.com/stemdeckapp/stemdeck/releases/download/v${version}/StemDeck-macOS-arm64.dmg";
  #     sha256 = "0ff3317x14ss1ixhy2jhrb639n85wjm03jgdz0h3rs44v3myi4g1";
  #   };
  #   nativeBuildInputs = [ pkgs.undmg ];
  #   sourceRoot = ".";
  #   installPhase = ''
  #     mkdir -p $out/Applications
  #     cp -r StemDeck.app $out/Applications/
  #   '';
  # };
in
{

  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    git
    ripgrep
    neovim
    just # use Justfile to simplify nix-darwin's commands
    devbox # a toolbox for developers
    nodejs_latest
    nixfmt # Nix formatter
    treefmt
    libfido2
    cmake
    sockseek
    # stemdeck  # APFS DMG not supported by undmg — install manually
  ];
  environment.variables.EDITOR = "nano";

  # Set the primary user for homebrew and user-specific settings
  system.primaryUser = username;

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      # NOTE: changed from "zap" to "none" — newer Homebrew requires --force for --cleanup,
      # which nix-darwin doesn't pass yet. Run `brew bundle cleanup --force --zap` manually.
      cleanup = lib.mkForce "none";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas
    masApps = {
      #"Amphetamine" = 937984704; # Keep-awake utility to prevent Mac from sleeping
      "Bitwarden" = 1352778147; # Password manager application
      #"Ferromagnetic" = 1546537151; # Utility for managing magnet links
      #"Magnet" = 441258766; # Window management tool for arranging windows
      "iMovie" = 408981434; # Apple's video editing software
      "Xcode" = 497799835; # Apple xCode
      #"Pages" = 409201541; # Apple's word processing software
      #"Keynote" = 409183694; # Apple's presentation software
      #"Numbers" = 409203825; # Apple's spreadsheet software
    };

    taps = [
      "hashicorp/tap"
      "nikitabobko/tap" # aerospace - an i3-like tiling window manager for macOS
      "FelixKratz/formulae" # janky borders - highlight active window borders
      "trycua/lume"
    ];

    brews = [
      "awk" # Pattern-directed scanning and processing language
      "age" # Age (Agenix)
      "azure-cli" # Azure CLI (az)
      "btop" # Resource monitor showing CPU, memory, disks, network
      "ca-certificates" # Bundle of CA root certificates
      "cask" # Extension mechanism for Homebrew
      "coreutils" # GNU core utilities (ls, cat, etc)
      "fastlane" # Automate beta deployment and releases for your iOS and Android apps
      "ffmpeg" # Audio and video converter/processor
      "jq" # Command-line JSON processor
      "gallery-dl" # Command-line downloader for image galleries
      # gemini-cli moved to modules/darwin/ai-tools.nix (llm-agents.nix)
      "gettext" # GNU internationalization (i18n) library
      "gnutls" # GNU Transport Layer Security Library
      "htop" # Interactive process viewer
      "jansson" # C library for encoding/decoding JSON
      "libidn2" # International domain name library
      "lume" # Command-line tool for virtual machines
      "mas" # Mac App Store command line interface
      "nettle" # Low-level cryptographic library
      "openssl@3" # Cryptography and SSL/TLS toolkit
      # openspec moved to modules/darwin/ai-tools.nix (llm-agents.nix)
      "p11-kit" # Library to load and share PKCS#11 modules
      "regclient" # Docker registry synchronization utility
      "taglib" # TagLib library
      "syncthing" # Open source continuous file synchronization tool
      "terraform-ls" # Language server for Terraform
      "tfenv" # Terraform version manager
      "tmux" # Terminal multiplexer
      "tree-sitter" # Parser generator tool and library
      "unbound" # Validating, recursive, and caching DNS resolver
      "yt-dlp" # YouTube video downloader
      "wget" # Command-line utility for downloading files from the web
      "xcodegen" # Command line tool to generate Xcode project files
    ];

    casks = [
      "ableton-live-standard" # Digital audio workstation for music production
      "android-studio" # Android development environment
      "antigravity" # Google Antigravity multi-agent command centre
      "aural" # audio player
      "arturia-software-center" # Arturia software management tool
      "battery" # Battery management tool
      "balenaetcher" # ISO to USB
      "betterdisplay" # Display scaling (hidpi)
      "brave-browser" # Privacy focused browser
      "blender" # Blender app for video editin
      "caffeine" # Keepalive app for macos
      "chatgpt" # ChatGPT Desktop App
      "codex" # ChatGPT Codex
      "cursor" # Cursor AI code editor
      "claude" # Claude AI desktop app (.app bundle via homebrew)
      "cyberduck" # FTP, SFTP, WebDAV, S3 file transfer client
      "discord" # Voice, video, and text chat app
      "docker-desktop" # Docker Desktop App
      "firefox" # Web browser
      "ghostty" # terminal emulator
      "google-chrome" # Web browser
      "gimp" # GNU Multiple Precision Arithmetic Library
      # "github-copilot-for-xcode" # Github Copilot for xCode
      # "ibkr" # Interactive Brokers trading platform
      "iterm2" # MacOS Terminal emulator
      "intellij-idea-ce" # IntelliJ Idea Community Edition
      "jetbrains-air" # Intellij Agentic AI Manager
      #"knockknock"     # Security tool to show persistent apps
      "lm-studio" # Local AI model runner and chat interface
      #"logitech-g-hub" # Logitech gaming configuration app
      #"logitech-options" # Configuration tool for Logitech devices
      #"libreoffice" # Open-source office software
      # "little-snitch" # Paid Firewall App
      #"lulu"           # Open-source firewall for macOS
      #"mixxx" # DJ software
      #"mixed-in-key" # Key detection and management tool for DJs
      #"moonlight" # Game streaming client
      #"musicbrainz-picard" # Audio Tagger
      "obsidian" # Markdown knowledge base and note-taking app
      "obs" # Open Source Streaming Software
      #"oversight"      # Monitors and notifies when microphone or camera is activated
      #"philips-hue-sync" # Phillips Hue Sync App
      "proton-mail-bridge" # Proton email
      "protonvpn" # VPN client
      "postman" # API Client
      "rekordbox" # DJ software
      "spotify" # Music streaming service
      #"stats" # System monitor for the menu bar
      #"steam" # Gaming platform and store
      #"microsoft-teams" # MS Teams
      #"rancher" # Kubernetes and containers host
      #"reamp" # WinAMP reimplementation for macOS
      "rectangle" # OSS Window snapping for MacOS
      #"telegram" # Messaging app
      "transmission" # BitTorrent client
      #"utm" # Virtual machines UI using QEMU
      #"vagrant" # Tool for building and managing virtual machine environments
      #"vagrant-vmware-utility" # Vagrant plugin for VMware
      "yubico-authenticator" # Authentication tool for YubiKey devices
      #"vanilla" # macOS app to hide menu bar icons
      #"xbar" # Bar Display Tool
    ];
  };
}
