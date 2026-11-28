# Single source of truth for every app managed by Homebrew (macOS) or its
# nixpkgs equivalent (NixOS) — the one place that decides, per app, which
# package manager owns it on which OS. Nothing else in the repo should
# hand-list a cross-platform GUI app or a brew-vs-nix choice; add/change an
# entry here and every consumer below follows automatically.
#
# ---------------------------------------------------------------------------
# Consumers — each reads this same `entries` list and filters it down to its
# own slice. These are the actual predicates (kept in sync with the code —
# if a predicate here stops matching its module, the comment is stale, not
# the code):
#
#   modules/darwin/apps.nix (forDarwin)
#     entries where: elem "darwin" platforms && (darwinNixPkg or null) == null
#     -> homebrew.brews / homebrew.casks / homebrew.masApps (by `type`)
#     i.e. "Homebrew can install this on darwin, and darwin isn't opted out
#     via darwinNixPkg" — the common case, true for nearly every entry.
#
#   modules/nixos/homebrew.nix (linuxBrews)
#     entries where: type == "brew" && elem "linux" platforms && linuxNixPkg == null
#     -> generated /etc/Brewfile.linux, applied by `make brew-linux-setup`
#     i.e. "a real brew formula exists for Linux, and nixpkgs isn't already
#     providing it" — CLI tools only; casks/mas can never match (they never
#     have "linux" in `platforms`, a hard Homebrew capability fact, not a
#     judgment call).
#
#   modules/nixos/apps.nix (linuxGuiPkgs)
#     entries where: (type == "cask" || type == "mas") && linuxNixPkg != null
#     -> pkgs.<linuxNixPkg> (dotted names like "jetbrains.idea" resolve
#        through nested attrsets), folded into environment.systemPackages
#     i.e. "this is a GUI app that only Homebrew Cask/mas can install, and
#     only on darwin — so linuxNixPkg is how it reaches Linux at all."
#
# A brew-type entry's Linux story works the other way round from a
# cask/mas's: brews CAN run on Linux via Homebrew itself (platforms includes
# "linux"), so linuxNixPkg on a brew entry just means "skip brew, nixpkgs
# already has this" (see modules/nixos/apps.nix's manually-curated "Core
# utilities" list for those). Casks and mas apps have no such option —
# Homebrew Cask and the Mac App Store are darwin-only, full stop — so for
# them linuxNixPkg isn't a dedup choice, it's the *only* route to Linux.
#
# Worked examples:
#   - {name="cursor"; type="cask"; linuxNixPkg="code-cursor";}
#     -> darwin: `brew install --cask cursor`. linux: pkgs.code-cursor,
#        generated into modules/nixos/apps.nix's systemPackages.
#   - {name="hermes-agent"; type="brew"; linuxNixPkg=null;
#      darwinNixPkg="hermes-agent (NousResearch flake...)";}
#     -> darwin: skipped by forDarwin (darwinNixPkg != null) — stays on the
#        NousResearch flake input in modules/darwin/ai-tools.nix instead,
#        because that HM module needs it version-matched to hermes-desktop.
#        linux: no such coupling exists, so `brew install hermes-agent` wins
#        (linuxNixPkg == null means "don't skip brew here").
#   - {name="chatgpt"; type="cask"; linuxNixPkg=null;
#      note="No official Linux desktop client.";}
#     -> darwin only; `note` records that this was confirmed unavailable on
#        Linux, not just never looked into.
# ---------------------------------------------------------------------------
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
#   darwinNixPkg Symmetric counterpart to linuxNixPkg: non-null when macOS
#                already gets this via nix instead of brew (e.g. the llm-
#                agents.nix overlay in modules/darwin/ai-tools.nix), even
#                though `platforms` includes "darwin" because Homebrew can
#                install it there too. modules/darwin/apps.nix's forDarwin
#                filter skips any entry with darwinNixPkg != null, the same
#                way modules/nixos/homebrew.nix skips linuxNixPkg != null,
#                so nothing is ever double-installed on either OS. null
#                (the common case) means brew is the install path on darwin.
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
    # AI CLI tools — real Homebrew formulae exist for all of these, so brew
    # is the install path on BOTH darwin and linux (platforms = both),
    # replacing modules/*/ai-tools.nix's llm-agents.nix overlay for them
    # (whose Linux builds have been flaky — claude-code-router/
    # oh-my-claudecode fail there outright). The one exception is
    # hermes-agent: its darwinNixPkg below keeps macOS on nix because the HM
    # module (home/macos/hermes.nix) needs it version-matched to
    # hermes-desktop via the NousResearch flake input — a coupling that
    # doesn't exist on NixOS, so Linux still gets it via brew.
    # ---------------------------------------------------------------------
    {
      name = "gemini-cli";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Interact with Google Gemini AI models from the command-line";
    }
    {
      name = "opencode";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "AI coding agent, built for the terminal (opencode.ai)";
    }
    {
      name = "herdr";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Agent multiplexer that lives in your terminal";
    }
    {
      name = "backlog-md";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Markdown-native task manager & kanban visualizer for any git repo";
    }
    {
      name = "beads";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Memory upgrade for your coding agent (gastownhall/beads)";
    }
    {
      name = "openspec";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Spec-driven development (SDD) for AI coding assistants (openspec.dev)";
    }
    {
      name = "claude-code-router";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      desc = "Routes Claude Code requests to different models and customizes requests";
      note = "Disabled under llm-agents.nix on both OSes (npm dep fetch fails over HTTP/2) — brew gives both OSes a working install path.";
    }
    {
      name = "hermes-agent";
      type = "brew";
      platforms = [
        "darwin"
        "linux"
      ];
      linuxNixPkg = null;
      darwinNixPkg = "hermes-agent (NousResearch flake input, see modules/darwin/ai-tools.nix)";
      desc = "Self-improving AI agent that creates skills from experience (NousResearch hermes-agent CLI)";
      note = "On macOS the HM module (home/macos/hermes.nix) needs this version-matched to hermes-desktop via the NousResearch flake input, so darwin stays nix-managed; no such coupling exists on NixOS, so brew installs it there.";
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
      linuxNixPkg = "jetbrains.idea";
      desc = "IntelliJ Idea Community Edition";
      note = "jetbrains.idea-community was discontinued/removed from nixpkgs upstream (2025-07); its suggested free-edition successor idea-oss is itself unmaintained and marked insecure (NIXPKGS-2026-2269), so this points at jetbrains.idea (the actively-maintained unified distribution) instead — unfree but not insecure.";
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
      linuxNixPkg = "proton-vpn";
      desc = "VPN client";
      note = "nixpkgs renamed protonvpn-gui to proton-vpn.";
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
