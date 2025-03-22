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
    l = "ls -altr";
    ll = "ls -altr";
    ls = "ls --color=auto";
    latr = "ls -altr";
    darwinup = "/Users/hrpr/.config/darwin/darwin-rebuild.sh";
  };
}
