{...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      gr() {
        rg -rnIi --colour "$1" ./
      }
    '';
  };
  
  home.shellAliases = {
    k = "kubectl";
    l = "ls -al";
    latr = "ls -altr";
  };
}
