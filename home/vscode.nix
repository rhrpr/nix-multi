{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        davidanson.vscode-markdownlint
        github.copilot
        github.copilot-chat
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        continue.continue
        mechatroner.rainbow-csv
        dbaeumer.vscode-eslint
        ahmadawais.shades-of-purple
      ];

      userSettings = {
        "editor.fontSize" = 14;
        "editor.fontFamily" = "Menlo, Monaco, 'Courier New', monospace";
        "editor.tabSize" = 2;
        "workbench.colorTheme" = "Shades of Purple (Super Dark)";
        "files.autoSave" = "afterDelay";
      };

      keybindings = [
        {
          key = "cmd+k cmd+i";
          command = "editor.action.showHover";
          when = "editorTextFocus";
        }
      ];
    };
  };
}
