{...}: {
   # Enable Neovim with nix4nvchad
  programs.neovim = {
    enable = true;
    package = inputs.nvchad4nix.packages.${inputs.system}.default;
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