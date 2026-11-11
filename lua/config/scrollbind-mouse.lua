-- O scrollbind nativo só propaga o scroll feito na janela atual. Rolar com o
-- mouse sobre outra janela vinculada (ex.: Ours com o cursor em Theirs) move
-- só ela. Aqui o scroll do mouse passa a valer para o grupo todo.
local M = {}

local motions = {
  ["<ScrollWheelUp>"] = { key = "<C-y>", axis = "ver" },
  ["<ScrollWheelDown>"] = { key = "<C-e>", axis = "ver" },
  ["<ScrollWheelLeft>"] = { key = "zh", axis = "hor" },
  ["<ScrollWheelRight>"] = { key = "zl", axis = "hor" },
}

local function step(axis)
  for _, part in ipairs(vim.opt.mousescroll:get()) do
    local name, count = part:match("^(%a+):(%d+)$")
    if name == axis then
      return tonumber(count)
    end
  end
  return axis == "ver" and 3 or 6
end

function M.apply(wheel, target)
  local motion = motions[wheel]
  local count = step(motion.axis)
  if count == 0 then
    return
  end
  -- Com a janela atual no grupo, rola a atual; senão, rola a que está sob o
  -- mouse. Nos dois casos o scrollbind nativo sincroniza as demais.
  local win = vim.wo.scrollbind and vim.api.nvim_get_current_win() or target
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_win_call(win, function()
    vim.cmd("normal! " .. count .. vim.api.nvim_replace_termcodes(motion.key, true, false, true))
  end)
end

function M.setup()
  for wheel in pairs(motions) do
    vim.keymap.set("n", wheel, function()
      local target = vim.fn.getmousepos().winid
      if target == 0 or target == vim.api.nvim_get_current_win() or not vim.wo[target].scrollbind then
        return wheel
      end
      return ("<Cmd>lua require('config.scrollbind-mouse').apply('%s', %d)<CR>"):format(wheel:gsub("<", "<lt>"), target)
    end, { expr = true, desc = "Scroll sincronizado em janelas com scrollbind" })
  end
end

return M
