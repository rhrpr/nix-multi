{
  config,
  pkgs,
  ...
}:
let
  shellAliases = {
    k = "kubectl";
  };
in
{
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
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };
    initExtra = ''
      gr() {
        ripgrep -rnIi "$1" ./
      };
    '';
  };

  environment.systemPackages = [pkgs.kubectl];
}
