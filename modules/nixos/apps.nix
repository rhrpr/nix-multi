{ pkgs, ... }: {

  ##########################################################################
  # 
  #  Install all apps and packages from nix's official package repository.
  #
  ##########################################################################

  environment.systemPackages = with pkgs; [
    git
    ripgrep
    neovim
    just # use Justfile to simplify nix-darwin's commands
    devbox # a toolbox for developers
    nodejs_latest

    # Core utilities
    btop
    bitwarden-desktop
    cacert
    coreutils
    fastlane
    ffmpeg
    gallery-dl
    gettext
    gmp
    gnutls
    htop
    jansson
    libidn2
    nettle
    openssl
    p11-kit
    syncthing
    terraform-ls
    terraform
    tmux
    tree-sitter
    unbound
    yt-dlp
    
    # GUI applications that have Nix equivalents
    android-studio
    discord
    firefox
    ghostty
    google-chrome
    obsidian
    protonvpn-gui
    spotify
    steam
    transmission_4
    whatsapp-for-linux
  ];
  environment.variables.EDITOR = "nano";

  # # For packages that need special configuration
  # services.syncthing = {
  #   enable = true;
  #   user = "yourusername";
  #   dataDir = "/path/to/sync/directory";
  #   configDir = "/path/to/config/directory";
  # };

  # For terminal multiplexer
  programs.tmux = {
    enable = true;
    shortcut = "a";
    terminal = "screen-256color";
  };
}
