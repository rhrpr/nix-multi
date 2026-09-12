{ pkgs, lib, ... }:
let
  sockseek = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "sockseek";
    version = "3.0.5";
    src = pkgs.fetchurl {
      url = "https://github.com/fiso64/sockseek/releases/download/v${version}/sockseek_${version}_linux-x64.tar.gz";
      sha256 = "0rhvjnn30a7jr1vh8g7vmmw5m54470hdgzbv947ami3v544yk8fh";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
      pkgs.icu
    ];
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/bin
      install -m755 sockseek $out/bin/sockseek
    '';
  };
  stemdeck = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "stemdeck";
    version = "0.15.2";
    src = pkgs.fetchurl {
      url = "https://github.com/stemdeckapp/stemdeck/releases/download/v${version}/StemDeck-Linux-x64.tar.gz";
      sha256 = "0gqjz93y5n3l5hh5q5hk4cx1dgln06vs1dra0b02ylf960dfg2fp";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.gtk3
      pkgs.glib
      pkgs.webkitgtk_4_1
      pkgs.openssl
    ];
    installPhase = ''
      mkdir -p $out/bin $out/lib
      install -m755 StemDeck $out/bin/stemdeck
      if [ -d lib ]; then cp -r lib/* $out/lib/; fi
    '';
  };
in
{

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
    gnumake
    gnutls
    htop
    pciutils
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
    code-cursor
    discord
    chromium
    ghostty
    gparted
    obsidian
    postman
    protonvpn-gui
    spotify
    transmission_4
    karere # Maintained WhatsApp desktop client
    yubioath-flutter
    sockseek
    stemdeck
  ];
  # Desktop profiles such as Omarchy provide their own editor launcher.
  environment.variables.EDITOR = lib.mkDefault "nano";

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

  # PC/SC Smart Card daemon for smart card support
  services.pcscd.enable = true;
}
