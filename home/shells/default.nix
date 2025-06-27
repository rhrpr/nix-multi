{
  config,
  pkgs,
  ...
}:
let
  shellAliases = {
    k = "kubectl";
    l = "ls -altr --color=auto";
    ll = "ls -altr --color=auto";
    latr = "ls -altr --color=auto";
    
    # System rebuild aliases
    rebuild = "sudo nixos-rebuild switch --flake ~/.config/nix-multi#nixos-plasma";
    rebuild-darwin = "darwin-rebuild switch --flake ~/.config/nix-multi#Ryans-MacBook-Pro";
    rebuild-test = "sudo nixos-rebuild test --flake ~/.config/nix-multi#nixos-plasma";
    rebuild-vm = "nix build ~/.config/nix-multi#nixosConfigurations.nixos-vm-hyprland.config.system.build.vm";
    
    # VM management aliases
    vm-build = "~/.config/nix-multi/vm-build.sh build";
    vm-run = "~/.config/nix-multi/vm-build.sh run"; 
    vm-clean = "~/.config/nix-multi/vm-build.sh clean";
    vm-manager = "~/.config/nix-multi/vm-manager.sh";
    
    # Nix utilities
    nix-gc = "sudo nix-collect-garbage -d";
    nix-search = "nix search nixpkgs";
    nix-shell-p = "nix-shell -p";
    
    # Git shortcuts
    g = "git";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
    gs = "git status";
    gd = "git diff";
    
    # Directory navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    
    # Modern unix tools
    cat = "bat";
    find = "fd";
    grep = "rg";
    ls = "eza";
    top = "btop";
  };
in {
  # only works in bash/zsh

  home.shellAliases = shellAliases;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };
    
    initContent = ''
      # Custom functions
      gr() {
        rg -rnIi --colour "$1" ./
      }
      
      # Quick directory jumps
      cdnix() {
        cd ~/.config/nix-multi
      }
      
      # Nix development shell
      devshell() {
        nix develop ~/.config/nix-multi
      }
      
      # Quick edit nix config
      editnix() {
        $EDITOR ~/.config/nix-multi
      }
    '';
    
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "kubectl" ];
      theme = "robbyrussell";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = shellAliases;
  };

  programs.nushell = {
    enable = true;
    package = pkgs.nushell;
    shellAliases = shellAliases;
  };

  home.packages = [pkgs.kubectl];
}
