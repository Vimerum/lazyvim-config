vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("v", "p", [["_dP]])

vim.keymap.set("n", "<C-p>", LazyVim.pick("files", { hidden = true, no_ignore = true }))
vim.keymap.set("n", "<C-f>", LazyVim.pick("live_grep"))

-- Toggle comment with CTRL+/
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("i", "<C-/>", "<Esc>gcc", { remap = true, desc = "Toggle comment" })
-- Fallback para terminais que enviam <C-_> ao invés de <C-/>
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("i", "<C-_>", "<Esc>gcc", { remap = true, desc = "Toggle comment" })
--
-- Primeiro, removemos os atalhos originais do LazyVim (opcional, mas recomndado para liberar o <S-h> e <S-l>)
pcall(vim.keymap.del, "n", "<S-h>")
pcall(vim.keymap.del, "n", "<S-l>")

-- Mapeia C-Tab para ir para o próximo buffer
vim.keymap.set("n", "<C-Tab>", function()
  if vim.fn.exists(":BufferLineCycleNext") > 0 then
    vim.cmd("BufferLineCycleNext")
  else
    vim.cmd("bnext")
  end
end, { desc = "Next buffer (C-Tab)" })

-- Mapeia C-S-Tab para ir para o buffer anterior
vim.keymap.set("n", "<C-S-Tab>", function()
  if vim.fn.exists(":BufferLineCyclePrev") > 0 then
    vim.cmd("BufferLineCyclePrev")
  else
    vim.cmd("bprevious")
  end
end, { desc = "Prev buffer (C-S-Tab)" })

-- Buscar apenas pr funções, métodos e construtores
vim.keymap.set("n", "<leader>sf", function()
  Snacks.picker.lsp_symbols({
    filter = { default = { "Function", "Method", "Constructor" } },
  })
end, { desc = "Buscar Funções/Métodos (Snacks)" })

-- ============================================================================
-- Fechar buffers inteligentemente com :q preservando o Neo-tree
-- ============================================================================
local function smart_quit(force)
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)
  local buftype = vim.bo[current_buf].buftype
  local filetype = vim.bo[current_buf].filetype
  local is_floating = vim.api.nvim_win_get_config(current_win).relative ~= ""

  -- Se for janela flutuante, buftype especial (help, quickfix, terminal) ou o próprio neo-tree:
  -- fecha a janela normalmente com quit
  if is_floating or buftype ~= "" or filetype == "neo-tree" then
    vim.cmd(force and "quit!" or "quit")
    return
  end

  -- Conta quantas janelas normais de edição existem na aba atual
  local normal_wins = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "neo-tree" and vim.bo[buf].buftype == "" then
        normal_wins = normal_wins + 1
      end
    end
  end

  -- Se houver múltiplos splits de edição abertos, fecha apenas o split atual
  if normal_wins > 1 then
    vim.cmd(force and "quit!" or "quit")
    return
  end

  -- Verifica buffers listados válidos (além do atual)
  local other_bufs = vim.tbl_filter(function(b)
    return vim.api.nvim_buf_is_valid(b)
      and vim.bo[b].buflisted
      and b ~= current_buf
      and vim.bo[b].filetype ~= "neo-tree"
      and vim.bo[b].buftype == ""
  end, vim.api.nvim_list_bufs())

  -- Verifica se o buffer atual já é um buffer vazio inicial (sem nome, sem alterações, vazio)
  local is_empty = vim.api.nvim_buf_get_name(current_buf) == ""
    and not vim.bo[current_buf].modified
    and vim.api.nvim_buf_line_count(current_buf) <= 1
    and (vim.api.nvim_buf_get_lines(current_buf, 0, 1, false)[1] or "") == ""

  -- Se não há mais buffers abertos e o atual já está vazio, não faz nada
  if #other_bufs == 0 and is_empty then
    return
  end

  -- Fecha o buffer usando Snacks.bufdelete (o mesmo usado pelo clique da aba):
  -- Preserva a janela e a largura do Neo-tree,
  -- vai para o último arquivo acessado ou cria um buffer vazio se for o último
  Snacks.bufdelete({ buf = current_buf, force = force })
end

vim.api.nvim_create_user_command("SmartQuit", function(opts)
  smart_quit(opts.bang)
end, { bang = true, desc = "Fechar buffer inteligentemente preservando layout do Neo-tree" })

-- Intercepta :q, :q!, :wq, :bd, etc. na linha de comando
vim.keymap.set("c", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<CR>"
  end
  if vim.fn.getcmdtype() == ":" then
    local cmd = vim.trim(vim.fn.getcmdline())
    if cmd == "q" or cmd == "quit" then
      return "<C-u>SmartQuit<CR>"
    elseif cmd == "q!" or cmd == "quit!" then
      return "<C-u>SmartQuit!<CR>"
    elseif cmd == "wq" then
      return "<C-u>w | SmartQuit<CR>"
    elseif cmd == "x" then
      return "<C-u>x | SmartQuit<CR>"
    elseif cmd == "bd" or cmd == "bdelete" then
      return "<C-u>SmartQuit<CR>"
    elseif cmd == "bd!" or cmd == "bdelete!" then
      return "<C-u>SmartQuit!<CR>"
    end
  end
  return "<CR>"
end, { expr = true, desc = "Smart quit on :q" })

-- Exit terminal mode with double Esc
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.keymap.set("n", "<leader>gF", "<cmd>!git fetch origin<cr>", { desc = "Git Fetch origin" })
