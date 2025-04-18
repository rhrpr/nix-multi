{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      # Extensions
      # To get your current extensions, run: code --list-extensions
      extensions = with pkgs.vscode-extensions; [
        # Common extensions - uncomment or add your own
        bbenoist.nix
        davidanson.vscode-markdownlint
        github.copilot
        github.copilot-chat
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        mechatroner.rainbow-csv
      ] 
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # For extensions not in nixpkgs:
        # {
        #   name = "extension-name";
        #   publisher = "publisher";
        #   version = "version";
        #   sha256 = "sha256-hash"; # Generate with nix-prefetch-url
        # }
      ];

      # Your settings
      # Copy from: ~/Library/Application Support/Code/User/settings.json
      userSettings = {
        "editor.fontSize" = 14;
        "editor.fontFamily" = "Menlo, Monaco, 'Courier New', monospace";
        "editor.tabSize" = 2;
        "workbench.colorTheme" = "Kimbie Dark";
        "files.autoSave" = "afterDelay";
        # Add your other settings here
      };

      # Your keybindings
      # Copy from: ~/Library/Application Support/Code/User/keybindings.json
      keybindings = [
        # Example:
        # {
        #   key = "cmd+k cmd+i";
        #   command = "editor.action.showHover";
        #   when = "editorTextFocus";
        # }
      ];
    };
  };
}