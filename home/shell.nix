{ pkgs, inputs, ... }:

{
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
    rebuild = "/Users/hrpr/.config/darwin/darwin-rebuild.sh";
  };

  home.packages = [
    # 👇 this makes sure it's in the dev shell
    (pkgs.writeShellScriptBin "nv4chad" ''
      export NVIM_APPNAME=nv4chad
      exec ${inputs.nvchad4nix.packages.${pkgs.system}.default}/bin/nvim "$@"
    '')
  ];
}
