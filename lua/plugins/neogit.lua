return {
  "NeogitOrg/neogit",
  lazy = true,
  dependencies = {
    "esmuellert/codediff.nvim",
    "m00qek/baleia.nvim",
    "folke/snacks.nvim",
  },
  cmd = "Neogit",
  keys = {
    { "<leader>go", "<cmd>Neogit<cr>", desc = "Git status (Neogit)" },
  },
}
