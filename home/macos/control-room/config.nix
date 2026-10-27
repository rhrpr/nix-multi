# Control-room settings for this Mac. Options are defined in ./default.nix.
#
# Add a project:   projects.<short-name> = { path = "~/projects/x"; };
# Then rebuild and run `control-room up` (or just log in again).
_:

{
  programs.controlRoom = {
    enable = true;

    # ------------------------------------------------------------------------
    # Herdr workspaces. Each gets one tab with an even grid of panes.
    # Default panes: claude | codex / gemini | shell. Missing paths are skipped.
    # ------------------------------------------------------------------------
    projects = {
      nix = {
        path = "~/.config/nix-multi";
        aliases = [
          "nix multi"
          "nicks"
          "dotfiles"
        ];
      };
      terrashift = {
        path = "~/projects/terrashift";
        aliases = [
          "terra"
          "terra shift"
        ];
      };
      meridian = {
        path = "~/projects/meridian";
        aliases = [ "meridian" ];
        panes = [
          {
            name = "claude";
            kind = "claude";
            aliases = [
              "claud"
              "cloud"
            ];
          }
          {
            name = "codex";
            kind = "codex";
            aliases = [ "codecs" ];
          }
          {
            name = "hermes";
            kind = "hermes";
            aliases = [ "hermes" ];
          }
          { name = "shell"; }
        ];
      };
    };

    # ------------------------------------------------------------------------
    # Desktop apps: AeroSpace home workspace + spoken names.
    # `aerospace list-apps` prints bundle ids of running apps.
    # ------------------------------------------------------------------------
    apps = {
      ghostty = {
        name = "Ghostty";
        bundleId = "com.mitchellh.ghostty";
        space = "1AI";
        aliases = [
          "terminal"
          "ghost tea"
        ];
      };
      code = {
        name = "Code";
        bundleId = "com.microsoft.VSCode";
        space = "2Code";
        aliases = [
          "vs code"
          "vscode"
          "visual studio code"
        ];
      };
      cursor = {
        name = "Cursor";
        bundleId = "com.todesktop.230313mzl4w4u92";
        space = "2Code";
      };
      xcode = {
        name = "Xcode";
        bundleId = "com.apple.dt.Xcode";
        space = "2Code";
      };
      obsidian = {
        name = "Obsidian";
        bundleId = "md.obsidian";
        space = "3Work";
        aliases = [ "notes" ];
      };
      firefox = {
        name = "Firefox";
        bundleId = "org.mozilla.firefox";
        space = "4Firefox";
      };
      chrome = {
        name = "Google Chrome";
        bundleId = "com.google.Chrome";
        space = "5Chrome";
        aliases = [
          "browser"
          "google chrome"
        ];
      };
      brave = {
        name = "Brave Browser";
        bundleId = "com.brave.Browser";
        space = "5Chrome";
        aliases = [ "brave" ];
      };
      claude = {
        name = "Claude";
        bundleId = "com.anthropic.claudefordesktop";
        space = "6Chat";
        aliases = [ "claude app" ];
      };
      chatgpt = {
        name = "ChatGPT";
        bundleId = "com.openai.chat";
        space = "6Chat";
        aliases = [ "chat gpt" ];
      };
      discord = {
        name = "Discord";
        bundleId = "com.hnc.Discord";
        space = "6Chat";
      };
      whatsapp = {
        name = "WhatsApp";
        bundleId = "net.whatsapp.WhatsApp";
        space = "6Chat";
        aliases = [ "whats app" ];
      };
      spotify = {
        name = "Spotify";
        bundleId = "com.spotify.client";
        space = "7Music";
        aliases = [ "music" ];
      };
      mail = {
        name = "Mail";
        bundleId = "com.apple.mail";
        space = "8Mail";
        aliases = [ "email" ];
      };
      calendar = {
        name = "Calendar";
        bundleId = "com.apple.iCal";
        space = "8Mail";
      };
      finder = {
        name = "Finder";
        bundleId = "com.apple.finder";
        space = "9File";
        floating = true;
        aliases = [ "files" ];
      };
      preview = {
        name = "Preview";
        bundleId = "com.apple.Preview";
        space = "9File";
        floating = true;
      };
      lmstudio = {
        name = "LM Studio";
        bundleId = "ai.elementlabs.lmstudio";
        space = "0Other";
        aliases = [ "lm studio" ];
      };
    };

    # Spoken names for AeroSpace workspaces ("go to mail", "switch to code").
    spaces = {
      ai = {
        name = "1AI";
        aliases = [
          "agents"
          "terminal"
        ];
      };
      code = {
        name = "2Code";
        aliases = [ "editor" ];
      };
      work = {
        name = "3Work";
        aliases = [ "notes" ];
      };
      firefox.name = "4Firefox";
      web = {
        name = "5Chrome";
        aliases = [ "browser" ];
      };
      chat.name = "6Chat";
      music.name = "7Music";
      mail = {
        name = "8Mail";
        aliases = [
          "email"
          "calendar"
        ];
      };
      files.name = "9File";
      other.name = "0Other";
    };

    # Desks: pull apps beside the control room ("review desk", ctrl+alt+r).
    desks = {
      review.pull = [ "chrome" ];
      research.pull = [
        "chrome"
        "obsidian"
      ];
      editor.pull = [ "code" ];
    };

    hotkeys.desks = {
      review = {
        mods = [
          "ctrl"
          "alt"
        ];
        key = "r";
      };
      research = {
        mods = [
          "ctrl"
          "alt"
        ];
        key = "e";
      };
    };

    boot.apps = [ ];

    # Rephrase unmatched voice commands with the LM Studio model Hermes uses.
    voice.llm = {
      enable = true;
      model = "qwen/qwen3.5-9b";
    };
  };
}
