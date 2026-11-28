{ pkgs, lib, ... }:
let
  # GUI apps declared once in modules/shared/homebrew-nix-apps.nix as a
  # Homebrew cask/mas app (darwin) with a nixpkgs equivalent (`linuxNixPkg`)
  # for Linux parity. Resolving those attribute names here means adding or
  # retiring a cross-platform GUI app only ever touches that one shared
  # file — this list, and modules/darwin/apps.nix's cask/mas lists, follow
  # automatically. Dotted names (e.g. "jetbrains.idea-community") resolve
  # through nested attrsets via attrByPath.
  guiAppEntries = builtins.filter (
    e: (e.type == "cask" || e.type == "mas") && e.linuxNixPkg != null
  ) (import ../shared/homebrew-nix-apps.nix).entries;
  linuxGuiPkgNames = lib.unique (map (e: e.linuxNixPkg) guiAppEntries);
  linuxGuiPkgs = map (
    name:
    lib.attrByPath (lib.splitString "." name) (
      throw "modules/nixos/apps.nix: nixpkgs has no attribute `${name}` (declared as linuxNixPkg in modules/shared/homebrew-nix-apps.nix)"
    ) pkgs
  ) linuxGuiPkgNames;

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
  ]
  # GUI applications that have Nix equivalents — generated from every
  # cask/mas entry's linuxNixPkg in modules/shared/homebrew-nix-apps.nix.
  ++ linuxGuiPkgs
  ++ (with pkgs; [
    # GUI apps with no Homebrew-cask counterpart in homebrew-nix-apps.nix —
    # curated here directly instead.
    chromium # FOSS build; kept alongside the google-chrome cask's Linux pick above rather than replacing it
    gparted
    karere # Maintained WhatsApp desktop client
    sockseek
    stemdeck
  ]);
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
