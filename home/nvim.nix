{...}: {
   # Enable Neovim with nix4nvchad
  programs.neovim = {
    enable = true;
    package = inputs.nvchad4nix.packages.${inputs.system}.default;
    # Add custom Neovim configuration
    extraConfig = ''
      set expandtab # Use spaces instead of tabs
      set tabstop=2 # Number of spaces to use for each tab
      set shiftwidth=2 # Number of spaces to use for autoindent
    '';
    extraPackages = with pkgs; [
      nodePackages.bash-language-server
      docker-compose-language-service
      dockerfile-language-server-nodejs
      emmet-language-server
      nixd
      (python3.withPackages(ps: with ps; [
        python-lsp-server
        flake8
      ]))
    ];
    hm-activation = true;
    backup = true;
  };
}