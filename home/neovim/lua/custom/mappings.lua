local M = {}

M.general = {
  n = {
    ["<C-d>"] = { "<C-d>zz", "Scroll down and center" },
    ["<C-u>"] = { "<C-u>zz", "Scroll up and center" },
    ["n"] = { "nzzzv", "Center next search" },
    ["N"] = { "Nzzzv", "Center prev search" },
    ["<leader>u"] = { "<cmd>UndotreeToggle<CR>", "Toggle Undotree" },
    ["<leader>gs"] = { "<cmd>Git<CR>", "Git status" },
    ["<leader>ha"] = {
      function() require("harpoon.mark").add_file() end, "Harpoon add file"
    },
    ["<leader>hh"] = {
      function() require("harpoon.ui").toggle_quick_menu() end, "Harpoon UI"
    },
    ["<leader>hn"] = {
      function() require("harpoon.ui").nav_next() end, "Harpoon next"
    },
    ["<leader>hp"] = {
      function() require("harpoon.ui").nav_prev() end, "Harpoon prev"
    },
  }
}

return M
