{ config, pkgs, inputs, ... }: {
  # Regular Neovim setup (uses ~/.config/nvim)
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

    # Load Primeagen's shared LSP setup
    extraLuaConfig = ''
      require("primeagen.lsp")
    '';

    hm-activation = true;
    backup = true;
  };

  #############################
  ### File system linking
  #############################

  # Mount Primeagen repo contents into ~/.config/nvim/lua/primeagen
  home.file.".config/nvim/lua/primeagen".source =
    "${inputs.primeagenInit}/lua/theprimeagen";

  # Your personal custom Primeagen-style enhancements
  home.file.".config/nvim/lua/custom".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/darwin/home/neovim/lua/custom";

  #############################
  ### NvChad alternative binary
  #############################

  home.packages = [
    # Provide NvChad as a second binary (nv4chad)
    (inputs.nvchad4nix.packages.${pkgs.system}.default.override {
      pname = "nv4chad";
    })
  ];

  #############################
  ### ZSH alias for separate config
  #############################

  programs.zsh.initExtra = ''
    alias nv4chad="NVIM_APPNAME=nv4chad nvim"
  '';

  #############################
  ### Primeagen code for NvChad too
  #############################

  # Make sure Primeagen’s config is available to NvChad as well
  home.file.".config/nv4chad/lua/primeagen".source =
    "${inputs.primeagenInit}/lua/theprimeagen";

  home.file.".config/nv4chad/lua/custom".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/darwin/home/neovim/lua/custom";
}
