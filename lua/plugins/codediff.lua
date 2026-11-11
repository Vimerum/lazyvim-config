return {
  "esmuellert/codediff.nvim",
  lazy = true,
  cmd = "CodeDiff",
  init = function()
    -- O CodeDiff ativa scrollbind nos dois painéis; sincronize ambos os eixos.
    vim.opt.scrollopt:append({ "ver", "hor", "jump" })
    require("config.git-diff").setup()
    require("config.scrollbind-mouse").setup()
  end,
  opts = {
    diff = {
      layout = "side-by-side",
      -- Barra na coluna de sinais em todas as linhas de um hunk, na cor da linha.
      gutter_signs = {
        insert_text = " ",
        delete_text = " ",
        highlight_numbers = false,
      },
    },
    keymaps = {
      view = {
        next_hunk = { "]c", "<leader>hh" },
        prev_hunk = { "[c", "<leader>hp" },
      },
    },
    explorer = {
      view_mode = "tree",
      flatten_dirs = true,
      auto_refresh = true,
    },
  },
}
