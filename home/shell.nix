{...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      gr() {
        ripgrep -rnIi --colour "$1" ./
      }
    '';
  };
  
  home.shellAliases = {
    k = "kubectl";
  };
}
