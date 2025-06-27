{ config, pkgs, lib, ... }:

let
  # Install Shades of Purple theme from VSCode marketplace
  shades-of-purple = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "shades-of-purple";
      publisher = "ahmadawais";
      version = "7.3.2";
      sha256 = "sha256-m3S54YzkgAFgeKuhz+39FvkdejpLwMPaxsLCd17iBYM=";
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
        mechatroner.rainbow-csv
        dbaeumer.vscode-eslint
        github.vscode-github-actions
        ms-azuretools.vscode-docker
      ] ++ [
        # Custom extensions from marketplace
        shades-of-purple
      ];

      userSettings = {
        "editor.fontSize" = 14;
        "editor.fontFamily" = "FiraCode Nerd Font, Menlo, Monaco, 'Courier New', monospace";
        "editor.tabSize" = 2;
        "workbench.colorTheme" = "Shades of Purple (Super Dark)";
        "workbench.iconTheme" = "shades-of-purple-icons";
        "files.autoSave" = "afterDelay";
        "editor.fontLigatures" = true;
        "editor.cursorBlinking" = "smooth";
      };
    };
  };
}
