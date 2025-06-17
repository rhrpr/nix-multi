{...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initContent = ''
      # Ensure no alias for gr exists before defining the function
      unalias gr 2>/dev/null || true
      greppy() {
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
    darwinup = "/Users/hrpr/.config/nix-multi/darwin-rebuild.sh";
    rebuild = "/Users/hrpr/.config/nix-multi/darwin-rebuild.sh";
    gr = greppy;
  };
}
