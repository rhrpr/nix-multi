{
  lib,
  pkgs,
  username,
  ...
}:
let
  # Shared across nix-darwin and the NixOS Linuxbrew bootstrap — see
  # modules/shared/homebrew-apps.nix for field docs and the Linux dedup logic.
  homebrewApps = (import ../shared/homebrew-apps.nix).entries;
  forDarwin =
    type: builtins.filter (e: e.type == type && builtins.elem "darwin" e.platforms) homebrewApps;

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
    supabase-cli
    google-cloud-sdk # gcloud CLI
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

    # Put `/opt/homebrew/{bin,sbin}` on PATH in interactive shells.
    # nix-darwin added these options defaulting to `false`; without them
    # `brew` (and brew-installed tools like tfenv) are not found in the terminal.
    enableZshIntegration = true;
    enableBashIntegration = true;

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
    # Generated from modules/shared/homebrew-apps.nix (type == "mas").
    # Disabled/experimental mas apps (Amphetamine, Ferromagnetic, Magnet,
    # Testflight) were dropped rather than carried over commented-out —
    # re-add them to the shared list if they come back into rotation.
    masApps = builtins.listToAttrs (
      map (e: {
        name = e.name;
        value = e.id;
      }) (forDarwin "mas")
    );

    taps = [
      "hashicorp/tap"
      "nikitabobko/tap" # aerospace - an i3-like tiling window manager for macOS
      "FelixKratz/formulae" # janky borders - highlight active window borders
      "trycua/lume"
      "stategraph/stategraph"
    ];

    # Generated from modules/shared/homebrew-apps.nix (type == "brew").
    # Disabled/experimental entries (azure-cli, gemini-cli, openspec — the
    # latter two moved to modules/darwin/ai-tools.nix) were dropped rather
    # than carried over commented-out.
    brews = map (e: e.name) (forDarwin "brew");

    # Generated from modules/shared/homebrew-apps.nix (type == "cask").
    # Disabled/experimental casks from the old literal list (knockknock,
    # logitech-g-hub, logitech-options, libreoffice, little-snitch, lulu,
    # mixxx, mixed-in-key, moonlight, musicbrainz-picard, oversight,
    # philips-hue-sync, stats, steam, microsoft-teams, rancher, reamp,
    # telegram, utm, vagrant, vagrant-vmware-utility, vanilla, xbar,
    # github-copilot-for-xcode, ibkr) were dropped rather than carried over
    # commented-out — re-add them to the shared list if they come back into
    # rotation.
    casks = map (e: e.name) (forDarwin "cask");
  };
}
