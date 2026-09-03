vim.g.lazyvim_ts_lsp = "tsgo"
vim.opt.relativenumber = false
vim.g.maplocalleader = ","
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.autoread = true
vim.lsp.document_color.enable(false)

vim.filetype.add({
  filename = {
    ["Jenkinsfile"] = "groovy",
  },
  pattern = {
    [".*Jenkinsfile.*"] = "groovy",
  },
})

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  {
    "rcarriga/nvim-notify",
    enabled = false,
  },
  {
    "folke/noice.nvim",
    enabled = false,
  },
}
