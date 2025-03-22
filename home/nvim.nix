{...}: {
   # Enable Neovim with nix4nvchad
  programs.neovim = {
    enable = true;
    package = inputs.nvchad4nix.packages.${inputs.system}.default;
  };
}