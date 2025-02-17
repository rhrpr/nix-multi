{
  config,
  pkgs,
  ...
}: let
  shellAliases = {
      k = "kubectl";
  };
in {
  # only works in bash/zsh, not nushell

  home.shellAliases = shellAliases;

  programs.nushell = {
    enable = true;
    package = pkgs.nushell;
    configFile.source = ./config.nu;
    inherit shellAliases;
  };

  programs.zsh = {
      enable = true;
      enableCompletion = true;
      initExtra = ''
      gr() {
          ripgrep -rnIi --colour "$1" ./
      }
      '';
  };
}