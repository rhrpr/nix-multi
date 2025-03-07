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
      "Amphetamine" = 937984704;
      "Bitwarden" = 1352778147;
      "Ferromagnetic" = 1546537151;
      "Magnet" = 441258766;
      "iMovie" = 408981434;
    };

    taps = [
      "homebrew/services"
      "hashicorp/tap"
      "nikitabobko/tap" # aerospace - an i3-like tiling window manager for macOS
      "FelixKratz/formulae" # janky borders - highlight active window borders
      "trycua/lume"
    ];

    brews = [
      "lume"
      "syncthing"
      # Deps
      "ca-certificates"
      "gmp"
      "coreutils"
      "gettext"
      "libidn2"
      "ffmpeg"
      "nettle"
      "p11-kit"
      "unbound"
      "gnutls"
      "jansson"
      "tree-sitter"
      "cask"
      "openssl@3"
    ];

    casks = [
      "aerospace" # an i3-like tiling window manager for macOS
      "blackhole-16ch"
      "cyberduck"
      "discord"
      "firefox"
      "ghostty" # terminal emulator
      "ibkr"
      "iterm2"
      "moonlight"
      "lm-studio"
      "logitech-options"
      "obsidian"
      "protonvpn"
      "raycast"
      "spotify"
      "stats"
      "transmission"
      "vagrant"
      "vagrant-vmware-utility"
      "visual-studio-code"
      "vmware-fusion"
      "whatsapp"
      "yubico-authenticator"
# Security Apps
      "lulu"
      "knockknock"
      "oversight"
    ];
  };
}
