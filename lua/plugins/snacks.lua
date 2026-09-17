local lazygit_config = vim.fn.expand("~/.config/lazygit/config.yml")
local custom_config_path = vim.fn.stdpath("cache") .. "/lazygit-custom.yml"

local custom_config_content = [=[
customCommands:
  - key: "e"
    context: "files"
    description: "Edit file in Neovim"
    command: 'nvim --server "$NVIM" --remote-send "<cmd>lua _G.lazygit_edit([[{{.SelectedFile.Name}}]])<CR>"'
    subprocess: false
  - key: "e"
    context: "commitFiles"
    description: "Edit commit file in Neovim"
    command: 'nvim --server "$NVIM" --remote-send "<cmd>lua _G.lazygit_edit([[{{.SelectedCommitFile.Name}}]])<CR>"'
    subprocess: false
]=]

local f = io.open(custom_config_path, "w")
if f then
  f:write(custom_config_content)
  f:close()
end

-- Append default and custom config to LG_CONFIG_FILE
local files = {}
if vim.loop.fs_stat(lazygit_config) then
  table.insert(files, lazygit_config)
end
table.insert(files, custom_config_path)

vim.env.LG_CONFIG_FILE = table.concat(files, ",")

_G.lazygit_edit = function(filename, line)
  local main_win = nil
  local prev_win = vim.fn.win_getid(vim.fn.winnr([[#]]))
  if prev_win and prev_win ~= 0 and vim.api.nvim_win_is_valid(prev_win) then
    local config = vim.api.nvim_win_get_config(prev_win)
    if config.relative == "" then
      main_win = prev_win
    end
  end

  if not main_win then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative == "" then
        main_win = win
        break
      end
    end
  end

  if main_win then
    vim.api.nvim_set_current_win(main_win)
    vim.cmd("edit " .. vim.fn.fnameescape(filename))
    if line and line ~= "" then
      local line_num = tonumber(line)
      if line_num then
        pcall(vim.api.nvim_win_set_cursor, main_win, { line_num, 0 })
      end
    end
  end

  for _, t in ipairs(require("snacks").terminal.list()) do
    if t:valid() then
      t:hide()
    end
  end
end

return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    -- 1. Opencode Picker Integration
    opts.input = opts.input or {}
    opts.picker = opts.picker or {}
    opts.picker.actions = opts.picker.actions or {}
    opts.picker.actions.opencode_send = function(...)
      return require("opencode").snacks_picker_send(...)
    end

    opts.picker.win = opts.picker.win or {}
    opts.picker.win.input = opts.picker.win.input or {}
    opts.picker.win.input.keys = opts.picker.win.input.keys or {}
    opts.picker.win.input.keys["<a-a>"] = { "opencode_send", mode = { "n", "i" } }

    -- 2. Lazygit Integration
    opts.lazygit = opts.lazygit or {}
    opts.lazygit.config = opts.lazygit.config or {}
    opts.lazygit.config.os = {
      editPreset = "", -- Disable default preset
      edit = "", -- Custom command handles editing via the e key override
    }

    -- 3. Show files in Find files
    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.files = {
      hidden = true,
      ignored = true,
      exclude = {
        "node_modules",
        "dist",
      },
    }

    return opts
  end,
}
