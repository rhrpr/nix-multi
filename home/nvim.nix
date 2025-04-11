{...}: {
   # Enable Neovim with nix4nvchad
  programs.neovim = {
    enable = true;
    package = inputs.nvchad4nix.packages.${inputs.system}.default;
    # Add custom Neovim configuration
    extraConfig = ''
      set expandtab # Use spaces instead of tabs
      set tabstop=2 # Number of spaces to use for each tab
      set shiftwidth=2 # Number of spaces to use for autoindent\
            local lspconfig = require("lspconfig")
      lspconfig.terraformls.setup {
        cmd = { "/custom/path/to/terraform-ls", "serve" },
        filetypes = { "terraform", "terraform-vars" },
        root_dir = lspconfig.util.root_pattern(".terraform", ".git")
      }
    '';
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
    
    plugins = with pkgs.vimPlugins; [
      coc-nvim
    ];
    
    extraLuaConfig = ''
      -- Configure coc.nvim
      vim.g.coc_global_extensions = {
      'coc-json',
      'coc-tsserver',
      'coc-terraform'
      }
    '';
    hm-activation = true;
    backup = true;
  };
}