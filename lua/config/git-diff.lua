local M = {}
local pending

function M.open()
  if pending then
    return
  end

  local root = vim.t.git_diff_root
  if not root then
    local file = vim.api.nvim_buf_get_name(0)
    local cwd = vim.bo.buftype == "" and file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
    local result = vim.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { text = true }):wait()
    if result.code ~= 0 then
      vim.notify("O arquivo ou diretório atual não pertence a um repositório Git.", vim.log.levels.WARN)
      return
    end
    root = vim.trim(result.stdout)
  end

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if vim.t[tab].git_diff_root == root then
      vim.api.nvim_set_current_tabpage(tab)
      return
    end
  end

  -- CodeDiff abre a aba de forma assíncrona. O evento identifica a aba criada.
  local request = { root = root }
  pending = request
  local ok, err = pcall(vim.cmd, "CodeDiff --repo " .. vim.fn.fnameescape(root))
  if not ok then
    pending = nil
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
  -- Repositórios limpos e erros não emitem CodeDiffOpen.
  vim.defer_fn(function()
    if pending == request then
      pending = nil
    end
  end, 5000)
end

function M.setup()
  vim.api.nvim_create_user_command("GitDiff", M.open, { desc = "Abrir diff Git" })
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("FixedGitDiff", { clear = true }),
    pattern = { "CodeDiffOpen", "CodeDiffClose" },
    callback = function(event)
      local tab = event.data and event.data.tabpage
      if not tab or not vim.api.nvim_tabpage_is_valid(tab) then
        return
      end
      if event.match == "CodeDiffOpen" and pending and event.data.mode == "explorer" then
        vim.t[tab].git_diff_root = pending.root
        pending = nil
      elseif event.match == "CodeDiffClose" then
        vim.t[tab].git_diff_root = nil
      end
    end,
  })
end

return M
