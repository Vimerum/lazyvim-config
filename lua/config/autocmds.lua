-- Disable spell checking by default, including filetypes where LazyVim enables it locally.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("disable_spell_by_default", { clear = true }),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Previne que o Neo-tree expanda para a tela inteira se a última janela de edição for fechada
vim.api.nvim_create_autocmd("WinClosed", {
  group = vim.api.nvim_create_augroup("neotree_prevent_fullscreen", { clear = true }),
  desc = "Evita que o Neo-tree ocupe a tela inteira ao fechar janela de edição",
  callback = function()
    -- Se o Neovim estiver finalizando (ex: :qa), não faz nada
    if vim.v.exiting ~= vim.NIL or vim.v.dying > 0 then
      return
    end

    vim.schedule(function()
      if vim.v.exiting ~= vim.NIL or vim.v.dying > 0 then
        return
      end

      local wins = vim.tbl_filter(function(w)
        return vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).relative == ""
      end, vim.api.nvim_tabpage_list_wins(0))

      -- Se restar apenas 1 janela e for o Neo-tree:
      if #wins == 1 and vim.bo[vim.api.nvim_win_get_buf(wins[1])].filetype == "neo-tree" then
        local tree_win = wins[1]
        vim.cmd("rightbelow vertical split")
        vim.api.nvim_win_set_width(tree_win, 40)

        -- Encontra o buffer listado acessado mais recentemente (MRU)
        local info = vim.fn.getbufinfo({ buflisted = 1 })
        table.sort(info, function(a, b)
          return a.lastused > b.lastused
        end)

        local target_buf = nil
        for _, item in ipairs(info) do
          if vim.bo[item.bufnr].filetype ~= "neo-tree" and vim.bo[item.bufnr].buftype == "" then
            target_buf = item.bufnr
            break
          end
        end

        if not target_buf or not vim.api.nvim_buf_is_valid(target_buf) then
          target_buf = vim.api.nvim_create_buf(true, false)
        end

        vim.api.nvim_win_set_buf(0, target_buf)
      end
    end)
  end,
})

