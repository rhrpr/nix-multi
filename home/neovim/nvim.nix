{ config, pkgs, inputs, ... }: {
  # 👉 1. Regular Neovim with Primeagen config
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

  ###############################
  # 🧠 Primeagen Config (Shared)
  ###############################

  home.file.".config/nvim/lua/primeagen".source =
    "${inputs.primeagenInit}/lua/theprimeagen";

  home.file.".config/nvim/lua/custom".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/darwin/home/neovim/lua/custom";

  ###############################
  # 🎨 NvChad via `nv4chad` binary
  ###############################

  home.packages = [
    # 🚀 Create a real nv4chad binary with separate config
    (pkgs.writeShellScriptBin "nv4chad" ''
      export NVIM_APPNAME=nv4chad
      exec ${inputs.nvchad4nix.packages.${pkgs.system}.default}/bin/nvim "$@"
    '')
  ];

  # Primeagen config for NvChad environment
  home.file.".config/nv4chad/lua/primeagen".source =
    "${inputs.primeagenInit}/lua/theprimeagen";

  home.file.".config/nv4chad/lua/custom".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/darwin/home/neovim/lua/custom";
}
