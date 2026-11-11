-- Ajustes de janela aplicados só aos painéis de diff do CodeDiff.
local M = {}

-- Sem virtualedit, o scroll horizontal de cada painel para no fim da linha do
-- cursor, e os painéis deixam de acompanhar uns aos outros em linhas curtas.
local function apply(tab)
  if not vim.api.nvim_tabpage_is_valid(tab) or not vim.t[tab].codediff_panes then
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.wo[win].scrollbind and vim.wo[win].virtualedit ~= "all" then
      vim.api.nvim_set_option_value("virtualedit", "all", { win = win, scope = "local" })
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("CodeDiffPanes", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = function(event)
      local tab = event.data and event.data.tabpage or vim.api.nvim_get_current_tabpage()
      if vim.api.nvim_tabpage_is_valid(tab) then
        vim.t[tab].codediff_panes = true
        apply(tab)
      end
    end,
  })
  -- O CodeDiff cria e recria painéis depois de abrir (ex.: o Result do conflito).
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinScrolled" }, {
    group = group,
    callback = function()
      local tab = vim.api.nvim_get_current_tabpage()
      if vim.t[tab].codediff_panes then
        vim.schedule(function()
          apply(tab)
        end)
      end
    end,
  })
end

return M
