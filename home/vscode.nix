{ config, pkgs, ... }:

let
  # Install Shades of Purple theme from VSCode marketplace
  shades-of-purple = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "shades-of-purple";
      publisher = "ahmadawais";
      version = "7.4.0";
      sha256 = "sha256-VrM6Lr9g+NTOz4nKC7p6Y9PQoWQRNADmdoqX5gDzGYs=";
    };
  };
in
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
        # continue.continue # Local LLM Copilot
        mechatroner.rainbow-csv
        dbaeumer.vscode-eslint
      ] ++ [
        # Custom extensions from marketplace
        shades-of-purple
      ];

      userSettings = {
        "editor.fontSize" = 14;
        "editor.fontFamily" = "FiraCode Nerd Font, Menlo, Monaco, 'Courier New', monospace";
        "editor.tabSize" = 2;
        "workbench.colorTheme" = "Shades of Purple";
        "files.autoSave" = "afterDelay";
        "editor.fontLigatures" = true;
        "editor.cursorBlinking" = "smooth";
        "workbench.iconTheme" = "shades-of-purple-icons";
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
