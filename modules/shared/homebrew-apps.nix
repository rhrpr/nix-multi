# Single source of truth for Homebrew-managed apps across both nix-darwin
# (macOS, native Homebrew) and the Linuxbrew bootstrap on NixOS.
#
# modules/darwin/apps.nix derives its homebrew.brews/casks/masApps from this
# list. modules/nixos/homebrew.nix derives its generated Brewfile from it,
# limited to formulae that both (a) actually run on Linux and (b) aren't
# already provided by nixpkgs in modules/nixos/apps.nix — so an app is never
# installed twice by two different package managers.
#
# Fields per entry:
#   name         Homebrew formula/cask name (tap-prefixed where needed, e.g.
#                "nikitabobko/tap/aerospace")
#   type         "brew" (CLI formula) | "cask" (GUI app) | "mas" (Mac App
#                Store, via `mas`)
#   platforms    OSes Homebrew can actually install this on. Every "cask" and
#                "mas" entry is darwin-only as a hard platform fact: Homebrew
#                Cask has no Linux support at all, and the Mac App Store only
#                exists on macOS — these aren't judgment calls.
#   linuxNixPkg  nixpkgs attribute name that already provides equivalent
#                functionality on Linux (see modules/nixos/apps.nix), or null.
#                Set regardless of whether this entry's `platforms` includes
#                "linux" — for a cask with no Linux brew support at all, this
#                is how Linux parity is actually achieved (via nixpkgs
#                instead of brew). When null and platforms excludes "linux",
#                `note` explains why there's no Linux path (confirmed as
#                unavailable from direct knowledge, not guessed).
#   id           Numeric App Store id, only for type == "mas"
#   desc         Short human description
#   note         Extra context (tap caveats, "verify before enabling", etc.)
{
  entries = [
    # ---------------------------------------------------------------------
    # brews (CLI formulae)
    # ---------------------------------------------------------------------
    {
      name = "awk";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Pattern-directed scanning and processing language";
    }
    {
      name = "age";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Age (Agenix)";
    }
    {
      name = "btop";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "btop";
      desc = "Resource monitor showing CPU, memory, disks, network";
    }
    {
      name = "bitwarden-cli";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Bitwarden CLI manager";
    }
    {
      name = "ca-certificates";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "cacert";
      desc = "Bundle of CA root certificates";
    }
    {
      name = "cask";
      type = "brew";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Extension mechanism for Homebrew";
      note = "Enables `brew cask`; meaningless on Linux since Homebrew Cask itself has no Linux support.";
    }
    {
      name = "coreutils";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "coreutils";
      desc = "GNU core utilities (ls, cat, etc)";
    }
    {
      name = "fastlane";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "fastlane";
      desc = "Automate beta deployment and releases for your iOS and Android apps";
    }
    {
      name = "ffmpeg";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "ffmpeg";
      desc = "Audio and video converter/processor";
    }
    {
      name = "jq";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Command-line JSON processor";
    }
    {
      name = "gallery-dl";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "gallery-dl";
      desc = "Command-line downloader for image galleries";
    }
    {
      name = "gettext";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "gettext";
      desc = "GNU internationalization (i18n) library";
    }
    {
      name = "gnutls";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "gnutls";
      desc = "GNU Transport Layer Security Library";
    }
    {
      name = "htop";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "htop";
      desc = "Interactive process viewer";
    }
    {
      name = "jansson";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "jansson";
      desc = "C library for encoding/decoding JSON";
    }
    {
      name = "libidn2";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "libidn2";
      desc = "International domain name library";
    }
    {
      name = "lume";
      type = "brew";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Command-line tool for virtual machines";
      note = "trycua/lume wraps Apple's Virtualization.framework — macOS only by design.";
    }
    {
      name = "mas";
      type = "brew";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Mac App Store command line interface";
      note = "The Mac App Store doesn't exist on Linux.";
    }
    {
      name = "nettle";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "nettle";
      desc = "Low-level cryptographic library";
    }
    {
      name = "openssl@3";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "openssl";
      desc = "Cryptography and SSL/TLS toolkit";
    }
    {
      name = "p11-kit";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "p11-kit";
      desc = "Library to load and share PKCS#11 modules";
    }
    {
      name = "regclient";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Docker registry synchronization utility";
    }
    {
      name = "taglib";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "TagLib library";
    }
    {
      name = "stategraph";
      type = "brew";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Stategraph CLI";
      note = "Custom tap (stategraph/stategraph) — Linux build availability unverified; confirm upstream before enabling.";
    }
    {
      name = "syncthing";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "syncthing";
      desc = "Open source continuous file synchronization tool";
    }
    {
      name = "terraform-ls";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "terraform-ls";
      desc = "Language server for Terraform";
    }
    {
      name = "tfenv";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Terraform version manager";
    }
    {
      name = "tmux";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "tmux";
      desc = "Terminal multiplexer";
    }
    {
      name = "tree-sitter";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "tree-sitter";
      desc = "Parser generator tool and library";
    }
    {
      name = "unbound";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "unbound";
      desc = "Validating, recursive, and caching DNS resolver";
    }
    {
      name = "yt-dlp";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = "yt-dlp";
      desc = "YouTube video downloader";
    }
    {
      name = "wget";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Command-line utility for downloading files from the web";
    }
    {
      name = "xcodegen";
      type = "brew";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Command line tool to generate Xcode project files";
      note = "Generates Xcode projects; Xcode itself only exists on macOS.";
    }

    # ---------------------------------------------------------------------
    # casks (GUI apps) — always darwin-only: Homebrew Cask has no Linux
    # support, full stop. linuxNixPkg below is how parity is actually reached
    # on Linux, via nixpkgs instead of brew.
    # ---------------------------------------------------------------------
    {
      name = "ableton-live-standard";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Digital audio workstation for music production";
      note = "No Linux build; Ableton doesn't ship for Linux.";
    }
    {
      name = "android-studio";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "android-studio";
      desc = "Android development environment";
    }
    {
      name = "antigravity";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Google Antigravity multi-agent command centre";
      note = "CLI equivalent (ai.antigravity-cli) already installed on both OSes via modules/*/ai-tools.nix.";
    }
    {
      name = "aural";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "audio player";
      note = "macOS-only audio player; no official Linux build.";
    }
    {
      name = "artcraft";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "OSS Adobe";
      note = "Unverified Linux equivalent — identify an OSS alternative if Linux parity is wanted here.";
    }
    {
      name = "arturia-software-center";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Arturia software management tool";
      note = "Arturia hardware/software ecosystem doesn't support Linux.";
    }
    {
      name = "battery";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Battery management tool";
      note = "macOS-only; Linux battery management is handled by the desktop environment / TLP.";
    }
    {
      name = "balenaetcher";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "ISO to USB";
      note = "balenaEtcher ships as an AppImage on Linux, not a nixpkgs package; verify a current nixpkgs attr before relying on one.";
    }
    {
      name = "betterdisplay";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Display scaling (hidpi)";
      note = "Built on macOS-private display APIs; Linux HiDPI scaling is handled natively by the compositor.";
    }
    {
      name = "brave-browser";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "brave";
      desc = "Privacy focused browser";
    }
    {
      name = "blender";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "blender";
      desc = "Blender app for video editing";
    }
    {
      name = "caffeine";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Keepalive app for macos";
      note = "Linux equivalent is `systemd-inhibit` or the desktop environment's own caffeine-style applet, not a standalone package.";
    }
    {
      name = "chatgpt";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "ChatGPT Desktop App";
      note = "No official Linux desktop client.";
    }
    {
      name = "codex";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "ChatGPT Codex";
      note = "CLI equivalent (ai.codex) already installed on both OSes via modules/*/ai-tools.nix.";
    }
    {
      name = "cursor";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "code-cursor";
      desc = "Cursor AI code editor";
    }
    {
      name = "claude";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Claude AI desktop app (.app bundle via homebrew)";
      note = "CLI equivalent (ai.claude-code) already installed on both OSes via modules/*/ai-tools.nix.";
    }
    {
      name = "cyberduck";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "FTP, SFTP, WebDAV, S3 file transfer client";
      note = "No direct Linux equivalent identified yet (e.g. FileZilla would need adding deliberately).";
    }
    {
      name = "discord";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "discord";
      desc = "Voice, video, and text chat app";
    }
    {
      name = "docker-desktop";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "docker";
      desc = "Docker Desktop App";
      note = "Linux parity comes from the native Docker Engine (docker + docker-compose), not a \"Desktop\" GUI shell.";
    }
    {
      name = "microsoft-edge";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "microsoft-edge";
      desc = "Microsoft Edge browser";
    }
    {
      name = "firefox";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "firefox";
      desc = "Web browser";
    }
    {
      name = "ghostty";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "ghostty";
      desc = "terminal emulator";
    }
    {
      name = "google-chrome";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "google-chrome";
      desc = "Web browser";
    }
    {
      name = "gimp";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "gimp";
      desc = "GNU Image Manipulation Program";
    }
    {
      name = "github-copilot-app";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Github co-pilot app";
      note = "CLI equivalent (ai.copilot-cli) already installed on both OSes via modules/*/ai-tools.nix.";
    }
    {
      name = "iterm2";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "ghostty";
      desc = "MacOS Terminal emulator";
      note = "ghostty is the terminal of record on both OSes; no separate iTerm2-equivalent is needed on Linux.";
    }
    {
      name = "intellij-idea-ce";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "jetbrains.idea-community";
      desc = "IntelliJ Idea Community Edition";
    }
    {
      name = "jetbrains-air";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Intellij Agentic AI Manager";
      note = "No standalone Linux build identified yet; verify current JetBrains AI Manager availability.";
    }
    {
      name = "ladybird";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "ladybird";
      desc = "Truly independent browser";
    }
    {
      name = "lm-studio";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Local AI model runner and chat interface";
      note = "LM Studio ships as an AppImage on Linux; no nixpkgs package as of writing — install the official AppImage manually.";
    }
    {
      name = "obsidian";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "obsidian";
      desc = "Markdown knowledge base and note-taking app";
    }
    {
      name = "obs";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "obs-studio";
      desc = "Open Source Streaming Software";
    }
    {
      name = "proton-mail-bridge";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "protonmail-bridge";
      desc = "Proton email bridge";
    }
    {
      name = "protonvpn";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "protonvpn-gui";
      desc = "VPN client";
    }
    {
      name = "postman";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "postman";
      desc = "API Client";
    }
    {
      name = "rekordbox";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "DJ software";
      note = "Pioneer DJ doesn't ship a Linux build of rekordbox.";
    }
    {
      name = "spotify";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "spotify";
      desc = "Music streaming service";
    }
    {
      name = "rectangle";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "OSS Window snapping for MacOS";
      note = "Window snapping/tiling is handled natively by the Linux desktop (Hyprland/KDE); no separate tool needed.";
    }
    {
      name = "transmission";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "transmission_4";
      desc = "BitTorrent client";
    }
    {
      name = "yubico-authenticator";
      type = "cask";
      platforms = [ "darwin" ];
      linuxNixPkg = "yubioath-flutter";
      desc = "Authentication tool for YubiKey devices";
    }

    # ---------------------------------------------------------------------
    # mas (Mac App Store apps) — always darwin-only: the Mac App Store
    # doesn't exist on Linux.
    # ---------------------------------------------------------------------
    {
      name = "Bitwarden";
      type = "mas";
      id = 1352778147;
      platforms = [ "darwin" ];
      linuxNixPkg = "bitwarden-desktop";
      desc = "Password manager application";
    }
    {
      name = "iMovie";
      type = "mas";
      id = 408981434;
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Apple's video editing software";
      note = "No Linux equivalent; consider Blender's VSE/Kdenlive deliberately if needed.";
    }
    {
      name = "Xcode";
      type = "mas";
      id = 497799835;
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Apple xCode";
      note = "Xcode is macOS-only by Apple's own licensing.";
    }
    {
      name = "Pages";
      type = "mas";
      id = 361309726;
      platforms = [ "darwin" ];
      linuxNixPkg = "libreoffice";
      desc = "Apple's word processor";
    }
    {
      name = "Keynote";
      type = "mas";
      id = 361285480;
      platforms = [ "darwin" ];
      linuxNixPkg = "libreoffice";
      desc = "Apple's presentation software";
    }
    {
      name = "Numbers";
      type = "mas";
      id = 361304891;
      platforms = [ "darwin" ];
      linuxNixPkg = "libreoffice";
      desc = "Apple's spreadsheet software";
    }
    {
      name = "Apple Developer";
      type = "mas";
      id = 640199958;
      platforms = [ "darwin" ];
      linuxNixPkg = null;
      desc = "Apple Developer";
      note = "Apple's own developer-account app; no Linux equivalent.";
    }
  ];
}
