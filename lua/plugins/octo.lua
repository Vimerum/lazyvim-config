local function patch_octo_file_panel_tree()
  local file_panel_module = require("octo.reviews.file-panel")
  local FilePanel = file_panel_module.FilePanel

  if FilePanel._kolab_tree_patch then
    return
  end

  local utils = require("octo.utils")
  local config = require("octo.config")
  local constants = require("octo.constants")
  local renderer = require("octo.reviews.renderer")
  local header_size = 1

  local function split_path(path)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
      table.insert(parts, part)
    end
    return parts
  end

  local function sorted_values(values)
    table.sort(values, function(a, b)
      return a.name < b.name
    end)
    return values
  end

  local function build_tree(files)
    local root = { dirs_by_name = {}, dirs = {}, files = {} }

    for _, file in ipairs(files) do
      local parts = split_path(file.path)
      local node = root

      for i = 1, math.max(#parts - 1, 0) do
        local part = parts[i]
        if not node.dirs_by_name[part] then
          local child = { name = part, dirs_by_name = {}, dirs = {}, files = {} }
          node.dirs_by_name[part] = child
          table.insert(node.dirs, child)
        end
        node = node.dirs_by_name[part]
      end

      file._kolab_tree_name = parts[#parts] or file.path
      table.insert(node.files, file)
    end

    return root
  end

  local function sort_tree(node)
    sorted_values(node.dirs)
    table.sort(node.files, function(a, b)
      return (a._kolab_tree_name or a.path) < (b._kolab_tree_name or b.path)
    end)

    for _, child in ipairs(node.dirs) do
      sort_tree(child)
    end
  end

  function FilePanel:get_file_at_cursor()
    if not (self:is_open() and self:buf_loaded()) then
      return
    end

    local cursor = vim.api.nvim_win_get_cursor(self.winid)
    return self._kolab_tree_file_by_line and self._kolab_tree_file_by_line[cursor[1]]
  end

  function FilePanel:highlight_file(file)
    if not (self:is_open() and self:buf_loaded()) then
      return
    end

    local line = self._kolab_tree_line_by_file and self._kolab_tree_line_by_file[file]
    if line then
      pcall(vim.api.nvim_win_set_cursor, self.winid, { line, 0 })
      vim.api.nvim_buf_clear_namespace(self.bufid, constants.OCTO_FILE_PANEL_NS, 0, -1)
      vim.api.nvim_buf_set_extmark(self.bufid, constants.OCTO_FILE_PANEL_NS, line - 1, 0, {
        end_line = line,
        hl_group = "OctoFilePanelSelectedFile",
      })
    end
  end

  function FilePanel:highlight_prev_file()
    if not (self:is_open() and self:buf_loaded()) or #self.files == 0 then
      return
    end

    local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
    for line = current_line - 1, header_size + 1, -1 do
      if self._kolab_tree_file_by_line and self._kolab_tree_file_by_line[line] then
        pcall(vim.api.nvim_win_set_cursor, self.winid, { line, 0 })
        return
      end
    end
  end

  function FilePanel:highlight_next_file()
    if not (self:is_open() and self:buf_loaded()) or #self.files == 0 then
      return
    end

    local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
    local line_count = vim.api.nvim_buf_line_count(self.bufid)
    for line = current_line + 1, line_count do
      if self._kolab_tree_file_by_line and self._kolab_tree_file_by_line[line] then
        pcall(vim.api.nvim_win_set_cursor, self.winid, { line, 0 })
        return
      end
    end
  end

  function FilePanel:render()
    local current_review = require("octo.reviews").get_current_review()
    if not current_review or not self.render_data then
      return
    end

    self.render_data:clear()
    self._kolab_tree_file_by_line = {}
    self._kolab_tree_line_by_file = {}

    local line_idx = 0
    local lines = self.render_data.lines
    local function add_hl(...)
      self.render_data:add_hl(...)
    end

    local conf = config.values
    local strlen = vim.fn.strlen
    local title = "Files changed"
    add_hl("OctoFilePanelTitle", line_idx, 0, #title)
    local change_count = string.format("%s%d%s", conf.left_bubble_delimiter, #self.files, conf.right_bubble_delimiter)
    add_hl("OctoBubbleDelimiterYellow", line_idx, strlen(title) + 1, strlen(title) + 1 + strlen(conf.left_bubble_delimiter))
    add_hl("OctoBubbleYellow", line_idx, strlen(title) + 1 + strlen(conf.left_bubble_delimiter), strlen(title) + 1 + strlen(change_count) - strlen(conf.right_bubble_delimiter))
    add_hl("OctoBubbleDelimiterYellow", line_idx, strlen(title) + 1 + strlen(change_count) - strlen(conf.right_bubble_delimiter), strlen(title) + 1 + strlen(change_count))
    table.insert(lines, title .. " " .. change_count)
    line_idx = line_idx + 1

    local tree = build_tree(self.files)
    sort_tree(tree)

    local function render_dir(node, depth)
      local indent = string.rep("  ", depth)
      local text = indent .. "  " .. node.name
      add_hl("Directory", line_idx, #indent + 4, #text)
      table.insert(lines, text)
      line_idx = line_idx + 1

      for _, child in ipairs(node.dirs) do
        render_dir(child, depth + 1)
      end

      for _, file in ipairs(node.files) do
        local offset = 0
        local file_name = file._kolab_tree_name or file.path
        local file_indent = string.rep("  ", depth + 1)
        local icon = renderer.get_file_icon(file.basename, file.extension, self.render_data, line_idx, #file_indent)
        local text = file_indent .. icon .. file_name
        offset = #text
        add_hl("OctoFilePanelFileName", line_idx, #file_indent + #icon, offset)

        add_hl(renderer.get_git_hl(file.status), line_idx, offset + 1, offset + 2)
        text = text .. " " .. file.status
        offset = #text

        if not file.viewed_state then
          file.viewed_state = "UNVIEWED"
        end
        local viewed_state = utils.viewed_state_map[file.viewed_state]
        text = text .. " " .. viewed_state.icon
        add_hl(viewed_state.hl, line_idx, offset + 1, offset + 4)
        offset = #text

        if file.stats then
          local diffstat = utils.diffstat(file.stats)
          text = text .. " " .. diffstat.total .. " "
          offset = #text
          if diffstat.additions > 0 then
            text = text .. string.rep("■", diffstat.additions)
            add_hl("OctoDiffstatAdditions", line_idx, offset, offset + (3 * diffstat.additions))
            offset = offset + (3 * diffstat.additions)
          end
          if diffstat.deletions > 0 then
            text = text .. string.rep("■", diffstat.deletions)
            add_hl("OctoDiffstatDeletions", line_idx, offset, offset + (3 * diffstat.deletions))
            offset = offset + (3 * diffstat.deletions)
          end
          if diffstat.neutral > 0 then
            text = text .. string.rep("■", diffstat.neutral)
            add_hl("OctoDiffstatNeutral", line_idx, offset, offset + (3 * diffstat.neutral))
          end
        end

        local active, resolved, outdated, pending = file_panel_module.thread_counts(file.path)
        local thread_parts = {}
        if active > 0 then
          table.insert(thread_parts, "active: " .. active)
        end
        if pending > 0 then
          table.insert(thread_parts, "pending: " .. pending)
        end
        if resolved > 0 then
          table.insert(thread_parts, "resolved: " .. resolved)
        end
        if outdated > 0 then
          table.insert(thread_parts, "outdated: " .. outdated)
        end
        if #thread_parts > 0 then
          text = text .. "  " .. table.concat(thread_parts, "  ")
        end

        table.insert(lines, text)
        self._kolab_tree_file_by_line[line_idx + 1] = file
        self._kolab_tree_line_by_file[file] = line_idx + 1
        line_idx = line_idx + 1
      end
    end

    for _, dir in ipairs(tree.dirs) do
      render_dir(dir, 0)
    end

    for _, file in ipairs(tree.files) do
      local offset = 0
      local icon = renderer.get_file_icon(file.basename, file.extension, self.render_data, line_idx, 2)
      local text = "  " .. icon .. (file._kolab_tree_name or file.path)
      offset = #text
      add_hl("OctoFilePanelFileName", line_idx, 2 + #icon, offset)

      add_hl(renderer.get_git_hl(file.status), line_idx, offset + 1, offset + 2)
      text = text .. " " .. file.status
      offset = #text

      if not file.viewed_state then
        file.viewed_state = "UNVIEWED"
      end
      local viewed_state = utils.viewed_state_map[file.viewed_state]
      text = text .. " " .. viewed_state.icon
      add_hl(viewed_state.hl, line_idx, offset + 1, offset + 4)
      offset = #text

      if file.stats then
        local diffstat = utils.diffstat(file.stats)
        text = text .. " " .. diffstat.total .. " "
        offset = #text
        if diffstat.additions > 0 then
          text = text .. string.rep("■", diffstat.additions)
          add_hl("OctoDiffstatAdditions", line_idx, offset, offset + (3 * diffstat.additions))
          offset = offset + (3 * diffstat.additions)
        end
        if diffstat.deletions > 0 then
          text = text .. string.rep("■", diffstat.deletions)
          add_hl("OctoDiffstatDeletions", line_idx, offset, offset + (3 * diffstat.deletions))
          offset = offset + (3 * diffstat.deletions)
        end
        if diffstat.neutral > 0 then
          text = text .. string.rep("■", diffstat.neutral)
          add_hl("OctoDiffstatNeutral", line_idx, offset, offset + (3 * diffstat.neutral))
        end
      end

      table.insert(lines, text)
      self._kolab_tree_file_by_line[line_idx + 1] = file
      self._kolab_tree_line_by_file[file] = line_idx + 1
      line_idx = line_idx + 1
    end

    local right = current_review.layout.right
    local left = current_review.layout.left
    table.insert(lines, "")
    line_idx = line_idx + 1

    local showing = "Showing changes for:"
    add_hl("OctoFilePanelTitle", line_idx, 0, #showing)
    table.insert(lines, showing)
    line_idx = line_idx + 1

    local range = left:abbrev() .. ".." .. right:abbrev()
    add_hl("OctoFilePanelPath", line_idx, 0, #range)
    table.insert(lines, range)
  end

  FilePanel._kolab_tree_patch = true
end

return {
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    opts = function(_, opts)
      -- or "fzf-lua" or "snacks" or "default"
      opts.picker = "telescope"
      -- bare Octo command opens picker of commands
      opts.enable_builtin = true

      return opts
    end,
    keys = {
      {
        "<leader>oi",
        "<CMD>Octo issue list<CR>",
        desc = "List GitHub Issues",
      },
      {
        "<leader>op",
        "<CMD>Octo pr list<CR>",
        desc = "List GitHub PullRequests",
      },
      {
        "<leader>og",
        "<CMD>Octo discussion list<CR>",
        desc = "List GitHub Discussions",
      },
      {
        "<leader>on",
        "<CMD>Octo notification list<CR>",
        desc = "List GitHub Notifications",
      },
      {
        "<leader>o/",
        function()
          require("octo.utils").create_base_search_command({ include_current_repo = true })
        end,
        desc = "Search GitHub",
      },
      {
        "<leader>or",
        "<CMD>Octo review start<CR>",
        desc = "Start PR Review",
      },
      {
        "<leader>oR",
        "<CMD>Octo review resume<CR>",
        desc = "Resume PR Review",
      },
      {
        "<leader>ob",
        "<CMD>Octo review browse<CR>",
        desc = "Browse PR Review",
      },
      {
        "<leader>oc",
        "<CMD>Octo review comments<CR>",
        desc = "Review Pending Comments",
      },
      {
        "<leader>oe",
        "<CMD>Neotree filesystem reveal left<CR>",
        desc = "Open PR files in Explorer",
      },
      {
        "<leader>os",
        "<CMD>Octo review submit<CR>",
        desc = "Submit PR Review",
      },
      {
        "<leader>ox",
        "<CMD>Octo review discard<CR>",
        desc = "Discard PR Review",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons", -- optional if file_panel.icons is a function
    },
  },
}
