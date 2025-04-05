{ pkgs, ... }: {

  ##########################################################################
  # 
  #  Install all apps and packages here.
  #
  # TODO Fell free to modify this file to fit your needs.
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
  ];
  environment.variables.EDITOR = "nano";

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
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas 
    masApps = {
      "Amphetamine" = 937984704;   # Keep-awake utility to prevent Mac from sleeping
      "Bitwarden" = 1352778147;    # Password manager application
      "Ferromagnetic" = 1546537151; # Utility for managing magnet links
      "Magnet" = 441258766;        # Window management tool for arranging windows
      "iMovie" = 408981434;        # Apple's video editing software
    };

    taps = [
      "homebrew/services"
      "hashicorp/tap"
      "nikitabobko/tap" # aerospace - an i3-like tiling window manager for macOS
      "FelixKratz/formulae" # janky borders - highlight active window borders
      "trycua/lume"
    ];

    brews = [
      "btop"           # Resource monitor showing CPU, memory, disks, network
      "ca-certificates" # Bundle of CA root certificates
      "cask"           # Extension mechanism for Homebrew
      "coreutils"      # GNU core utilities (ls, cat, etc)
      "ffmpeg"         # Audio and video converter/processor
      "gallery-dl"     # Command-line downloader for image galleries
      "gettext"        # GNU internationalization (i18n) library
      "gmp"            # GNU Multiple Precision Arithmetic Library
      "gnutls"         # GNU Transport Layer Security Library
      "htop"           # Interactive process viewer
      "jansson"        # C library for encoding/decoding JSON
      "libidn2"        # International domain name library
      "lume"           # Command-line tool for virtual machines
      "nettle"         # Low-level cryptographic library
      "openssl@3"      # Cryptography and SSL/TLS toolkit
      "p11-kit"        # Library to load and share PKCS#11 modules
      "syncthing"      # Open source continuous file synchronization tool
      "tfenv"          # Terraform version manager
      "tmux"           # Terminal multiplexer
      "tree-sitter"    # Parser generator tool and library
      "unbound"        # Validating, recursive, and caching DNS resolver
      "yt-dlp"         # YouTube video downloader
    ];

    casks = [ 
      "aerospace"      # an i3-like tiling window manager for macOS
      "android-studio" # Android development environment
      "aural"          # audio player
      "blackhole-16ch" # Virtual audio driver for routing audio between applications
      "cursor"        # Cursor AI code editor
      "cyberduck"      # FTP, SFTP, WebDAV, S3 file transfer client
      "discord"        # Voice, video, and text chat app
      "firefox"        # Web browser
      "ghostty"        # terminal emulator
      "google-chrome"  # Web browser
      "ibkr"           # Interactive Brokers trading platform
      "knockknock"     # Security tool to show persistent apps
      "lm-studio"      # Local AI model runner and chat interface
      "logitech-options" # Configuration tool for Logitech devices
      "lulu"           # Open-source firewall for macOS
      "microsoft-edge" # Web browser
      "mixxx"          # DJ software
      "moonlight"      # Game streaming client
      "obsidian"       # Markdown knowledge base and note-taking app
      "oversight"      # Monitors and notifies when microphone or camera is activated
      "protonvpn"      # VPN client
      "spotify"        # Music streaming service
      "stats"          # System monitor for the menu bar
      "transmission"   # BitTorrent client
      "vagrant"        # Tool for building and managing virtual machine environments
      "vagrant-vmware-utility" # Vagrant plugin for VMware
      "visual-studio-code" # Code editor
      "vmware-fusion"  # Virtualization software
      "vox"            # Music player for macOS
      "whatsapp"       # Messaging app
      "yubico-authenticator" # Authentication tool for YubiKey devices
    ];
  };
}
