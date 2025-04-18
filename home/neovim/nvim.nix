{ config, pkgs, inputs, ... }: {
  # 👉 Regular Neovim (nvim)
  programs.neovim = {
    enable = true;
    package = pkgs.neovim;

    extraPackages = with pkgs; [
      nodePackages.bash-language-server
      docker-compose-language-service
      dockerfile-language-server-nodejs
      emmet-language-server
      nixd
      terraform-ls
      nodejs
      (python3.withPackages(ps: with ps; [
        python-lsp-server
        flake8
      ]))
    ];

    extraConfig = ''
      set expandtab
      set tabstop=2
      set shiftwidth=2
    '';

    extraLuaConfig = ''
      require("primeagen.lsp")
    '';

    hm-activation = true;
    backup = true;
  };

  # 🔗 Primeagen repo used for both setups
  home.file.".config/nvim/lua/primeagen".source =
    "${inputs.primeagenInit}/lua/theprimeagen";

  # Your custom Prime-style config (shared)
  home.file.".config/nvim/lua/custom".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/darwin/home/neovim/lua/custom";

  # 🌀 Add NvChad (as separate binary)
  home.packages = [
    (inputs.nvchad4nix.packages.${pkgs.system}.default.override {
      pname = "nv4chad";
    })
  ];

  # 🌀 Set up NVIM_APPNAME for nv4chad
  programs.zsh.initExtra = ''
    alias nv4chad="NVIM_APPNAME=nv4chad nvim"
  '';

  # 🔗 Prime config for NvChad
  home.file.".config/nv4chad/lua/primeagen".source =
    "${inputs.primeagenInit}/lua/theprimeagen";

  home.file.".config/nv4chad/lua/custom".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/darwin/home/neovim/lua/custom";
}
