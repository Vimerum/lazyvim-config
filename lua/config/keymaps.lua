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
