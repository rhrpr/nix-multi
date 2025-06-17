{ config, pkgs, inputs, ... }: {
  programs.neovim = {
    enable = true;
    package = inputs.nvchad4nix.packages.${pkgs.system}.default;

    extraConfig = ''
      set expandtab
      set tabstop=2
      set shiftwidth=2
    '';

    # Dynamically load Primeagen's LSP config from GitHub
    extraLuaConfig = ''
      require("theprimeagen.lsp")
    '';

    extraPackages = with pkgs; [
      nodePackages.bash-language-server
      docker-compose-language-service
      dockerfile-language-server-nodejs
      emmet-language-server
      nixd
      terraform-ls
      nodejs
      (python3.withPackages (
        ps: with ps; [
          python-lsp-server
          flake8
        ]
      ))
    ];

    hm-activation = true;
    backup = true;
  };

  # Fetch Primeagen's Lua config and mount it inside ~/.config/nvim/lua/theprimeagen
  home.file.".config/nvim/lua/theprimeagen".source = "${inputs.primeagenInit}/lua/theprimeagen";

  # Your NvChad custom config (mapped from your repo)
  home.file.".config/nvim/lua/custom".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-multi/home/neovim/lua/custom";
}
