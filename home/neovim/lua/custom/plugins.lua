local plugins = {
  {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("harpoon").setup() end,
  },
  {
    "mbbill/undotree"
  },
  {
    "tpope/vim-fugitive"
  },
  {
    "tpope/vim-surround"
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    config = function()
      require("treesitter-context").setup({})
    end,
  },
}

return plugins
