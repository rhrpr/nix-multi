##############################################################################
#
#  AI Control Room — one screen, many agents, voice-driven, reboot-proof.
#
#  Layers (each owned by exactly one tool):
#    Herdr        terminal runtime: workspaces, panes, agent state, restore
#    control-room glue CLI: declarative projects → Herdr panes, voice router,
#                 HQ dashboard, desk layouts, login bring-up
#    AeroSpace    desktop tiling; workspace 1AI holds the control room window
#    Hammerspoon  global hotkeys + push-to-talk (sox → whisper.cpp, on-device)
#    launchd      runs `control-room boot` at login so everything comes back
#
#  Values for this machine live in ./config.nix. See docs/CONTROL-ROOM.md.
#
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.controlRoom;
  inherit (lib) mkOption mkEnableOption types;

  home = config.home.homeDirectory;
  user = config.home.username;

  # Where nix-darwin, Home Manager and Homebrew put binaries. launchd and
  # Hammerspoon start with a minimal PATH, so spell it out.
  systemPath = lib.concatStringsSep ":" [
    "${home}/.nix-profile/bin"
    "/etc/profiles/per-user/${user}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  voiceDeps = lib.optionals cfg.voice.enable [
    pkgs.sox
    pkgs.whisper-cpp
  ];

  controlRoom = pkgs.runCommand "control-room" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    install -Dm755 ${./control_room.py} $out/libexec/control-room
    substituteInPlace $out/libexec/control-room \
      --replace-fail "#!/usr/bin/env python3" "#!${pkgs.python3}/bin/python3"
    makeWrapper $out/libexec/control-room $out/bin/control-room \
      --prefix PATH : "${lib.makeBinPath voiceDeps}:${systemPath}"
  '';

  crGemini = pkgs.writeShellScriptBin "cr-gemini" (builtins.readFile ./cr-gemini.sh);

  # Runs inside the dedicated Ghostty window. Kept as a parent process (not
  # exec) so `control-room boot` can detect an existing control-room window.
  attach = pkgs.writeShellScriptBin "control-room-attach" ''
    export PATH="${systemPath}:$PATH"
    while true; do
      herdr ${lib.optionalString (cfg.herdrSession != null) "--session ${cfg.herdrSession}"}
      printf '\n\033[2mDetached from Herdr. Enter = reattach · Ctrl-C = close window\033[0m\n'
      read -r _ || exit 0
    done
  '';

  paneType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Pane name; the Herdr label/agent name is <project>-<name>.";
      };
      kind = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "claude";
        description = "Herdr agent kind (claude, codex, gemini, copilot, hermes, agy, opencode…). null = plain pane.";
      };
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "npm run dev";
        description = "Command to run instead of a native agent (dev servers, wrappers, monitors).";
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra arguments for the agent executable.";
      };
      aliases = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra spoken names for this pane (helps with mis-transcriptions).";
      };
      resumeFlag = mkOption {
        type = types.bool;
        default = false;
        description = "Append --resume to `command` when reviving after a restart.";
      };
    };
  };

  projectType = types.submodule {
    options = {
      path = mkOption {
        type = types.str;
        description = "Project directory (~ allowed). Missing directories are skipped.";
      };
      aliases = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Spoken names for the project.";
      };
      panes = mkOption {
        type = types.listOf paneType;
        default = cfg.defaultPanes;
        description = "Panes laid out as an even grid in the project's first tab.";
      };
    };
  };

  appType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Application name as macOS / AeroSpace reports it.";
      };
      bundleId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bundle id for the AeroSpace on-window-detected rule.";
      };
      space = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Home AeroSpace workspace for this app.";
      };
      floating = mkOption {
        type = types.bool;
        default = false;
      };
      titleRegex = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Only match windows whose title contains this regex.";
      };
      aliases = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };

  hotkeyType = types.submodule {
    options = {
      mods = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      key = mkOption { type = types.str; };
    };
  };

  hk = mods: key: { inherit mods key; };

  spaceType = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      aliases = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };

  deskType = types.submodule {
    options = {
      pull = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Keys of `apps` to move into the control-room workspace.";
      };
      layout = mkOption {
        type = types.nullOr types.str;
        default = "tiles horizontal";
      };
    };
  };

  # Keep the generated JSON free of Nix-only fields.
  projectsJson = lib.mapAttrsToList (name: p: {
    inherit name;
    inherit (p) path aliases;
    panes = map (pane: {
      inherit (pane)
        name
        kind
        command
        args
        aliases
        resumeFlag
        ;
    }) p.panes;
  }) cfg.projects;

  configJson = {
    herdr = "herdr";
    aerospace = "aerospace";
    aiSpace = cfg.aiSpace;
    terminal = {
      app = cfg.terminal.app;
      title = cfg.terminal.title;
      attach = "${attach}/bin/control-room-attach";
      extraArgs = cfg.terminal.extraArgs;
    };
    hq.enable = cfg.hq;
    projects = projectsJson;
    apps = cfg.apps;
    spaces = cfg.spaces;
    desks = cfg.desks;
    boot = {
      inherit (cfg.boot)
        revive
        settleSeconds
        initialDelay
        apps
        daemons
        ;
    };
    hotkeys = cfg.hotkeys;
    bin = {
      controlRoom = "${controlRoom}/bin/control-room";
      path = systemPath;
    };
    voice = {
      inherit (cfg.voice)
        enable
        speak
        model
        language
        dictateSubmit
        ;
      modelPath = "${home}/.local/share/control-room/models/ggml-${cfg.voice.model}.bin";
      whisper = "${pkgs.whisper-cpp}/bin/whisper-cli";
      downloader = "${pkgs.whisper-cpp}/bin/whisper-cpp-download-ggml-model";
      sox = "${pkgs.sox}/bin/sox";
      commandHotkeyLabel = lib.concatStringsSep "+" (
        cfg.hotkeys.voiceCommand.mods ++ [ cfg.hotkeys.voiceCommand.key ]
      );
      llm = cfg.voice.llm;
    };
  };

  tomlString = s: "'" + s + "'";
  windowRules = lib.concatStrings (
    lib.mapAttrsToList (
      _: app:
      lib.optionalString (app.bundleId != null && app.space != null) ''

        [[on-window-detected]]
        if.app-id = ${tomlString app.bundleId}
        ${lib.optionalString (
          app.titleRegex != null
        ) "if.window-title-regex-substring = ${tomlString app.titleRegex}\n"}run = [${
          lib.optionalString app.floating "'layout floating', "
        }'move-node-to-workspace ${app.space}']
      ''
    ) cfg.apps
  );
in
{
  options.programs.controlRoom = {
    enable = mkEnableOption "the AI control room (Herdr + AeroSpace + voice)";

    herdrSession = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Named Herdr session for the control room (null = default session).";
    };

    aiSpace = mkOption {
      type = types.str;
      default = "1AI";
      description = "AeroSpace workspace that holds the control-room terminal.";
    };

    hq = mkOption {
      type = types.bool;
      default = true;
      description = "Create an `hq` Herdr workspace with the live fleet dashboard.";
    };

    terminal = {
      app = mkOption {
        type = types.str;
        default = "Ghostty";
      };
      title = mkOption {
        type = types.str;
        default = "Control Room";
        description = "Fixed window title; AeroSpace uses it to pin the window to aiSpace.";
      };
      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ "--window-save-state=never" ];
      };
    };

    defaultPanes = mkOption {
      type = types.listOf paneType;
      default = [
        {
          name = "claude";
          kind = "claude";
          aliases = [
            "claud"
            "cloud"
            "clawed"
          ];
        }
        {
          name = "codex";
          kind = "codex";
          aliases = [
            "codecs"
            "codec"
          ];
        }
        {
          name = "gemini";
          kind = "gemini";
          command = "cr-gemini";
          resumeFlag = true;
          aliases = [ "jiminy" ];
        }
        { name = "shell"; }
      ];
      description = "Panes used by projects that do not list their own.";
    };

    projects = mkOption {
      type = types.attrsOf projectType;
      default = { };
      description = "Herdr workspaces to keep in the control room, keyed by short name.";
    };

    apps = mkOption {
      type = types.attrsOf appType;
      default = { };
      description = "Desktop apps: AeroSpace placement, voice names and desk membership.";
    };

    spaces = mkOption {
      type = types.attrsOf spaceType;
      default = { };
      description = "Spoken names for AeroSpace workspaces.";
    };

    desks = mkOption {
      type = types.attrsOf deskType;
      default = { };
      description = "Named layouts that pull apps beside the control room.";
    };

    boot = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Run `control-room boot` at login (launchd).";
      };
      revive = mkOption {
        type = types.bool;
        default = true;
        description = "Relaunch agents (with continue/resume flags) in panes that restored as bare shells.";
      };
      settleSeconds = mkOption {
        type = types.int;
        default = 10;
      };
      initialDelay = mkOption {
        type = types.int;
        default = 3;
      };
      apps = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Keys of `apps` (or app names) to open in the background at login.";
      };
      daemons = mkOption {
        type = types.listOf types.str;
        default = [
          "AeroSpace"
          "Hammerspoon"
        ];
      };
    };

    hotkeys = {
      voiceCommand = mkOption {
        type = hotkeyType;
        default = hk [ "ctrl" "alt" ] "space";
        description = "Hold to speak a control-room command.";
      };
      voiceDictate = mkOption {
        type = hotkeyType;
        default = hk [ "ctrl" "alt" ] "d";
        description = "Hold to dictate text into the focused window/pane.";
      };
      focusControlRoom = mkOption {
        type = hotkeyType;
        default = hk [ "ctrl" "alt" ] "a";
      };
      status = mkOption {
        type = hotkeyType;
        default = hk [ "ctrl" "alt" ] "s";
      };
      deskReset = mkOption {
        type = hotkeyType;
        default = hk [ "ctrl" "alt" ] "0";
      };
      desks = mkOption {
        type = types.attrsOf hotkeyType;
        default = { };
      };
    };

    voice = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      model = mkOption {
        type = types.str;
        default = "small.en";
        description = "whisper.cpp model (tiny.en, base.en, small.en, medium.en, large-v3-turbo…).";
      };
      language = mkOption {
        type = types.str;
        default = "en";
      };
      speak = mkOption {
        type = types.bool;
        default = true;
        description = "Speak status answers aloud.";
      };
      dictateSubmit = mkOption {
        type = types.bool;
        default = false;
        description = "Press Return after dictated text.";
      };
      llm = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Ask a local OpenAI-compatible model to rephrase commands the grammar misses.";
        };
        url = mkOption {
          type = types.str;
          default = "http://localhost:1234/v1/chat/completions";
        };
        model = mkOption {
          type = types.str;
          default = "local";
        };
        timeout = mkOption {
          type = types.int;
          default = 12;
        };
      };
    };

    # Read-only outputs for other modules (AeroSpace) to consume.
    aerospaceWindowRules = mkOption {
      type = types.lines;
      readOnly = true;
      default = windowRules;
      description = "Generated AeroSpace [[on-window-detected]] rules.";
    };
    execPath = mkOption {
      type = types.str;
      readOnly = true;
      default = systemPath;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      controlRoom
      crGemini
      attach
    ]
    ++ voiceDeps;

    xdg.configFile."control-room/config.json".text = builtins.toJSON configJson;

    home.file.".hammerspoon/init.lua".source = ./hammerspoon.lua;

    launchd.agents.control-room = lib.mkIf cfg.boot.enable {
      enable = true;
      config = {
        ProgramArguments = [
          "${controlRoom}/bin/control-room"
          "boot"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        ProcessType = "Interactive";
        LimitLoadToSessionType = "Aqua";
        EnvironmentVariables.PATH = systemPath;
        StandardOutPath = "${home}/.local/state/control-room/boot.out.log";
        StandardErrorPath = "${home}/.local/state/control-room/boot.err.log";
      };
    };

    home.activation.controlRoomState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${home}/.local/state/control-room" "${home}/.local/share/control-room/models"
    '';

    home.shellAliases = {
      cr = "control-room";
      crs = "control-room status";
      cru = "control-room up";
      crv = "control-room voice";
    };
  };
}
