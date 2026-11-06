return {
  "McEazy2700/antigravity-cli.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
  },
  opts = {
    -- Path to the antigravity CLI binary
    command = "agy --mode plan",

    terminal = {
      -- "native" (standard split), "float" (Neovim floating window), or "snacks" (snacks.nvim terminal)
      provider = "native",

      -- Only for "native" provider
      position = "right", -- "right", "left", "top", "bottom"
      size = 80, -- width (for right/left) or height (for top/bottom)

      -- Options for "float" and "snacks" providers
      float_opts = {
        width = 0.8, -- Percentage of screen width (0.0 to 1.0)
        height = 0.8, -- Percentage of screen height (0.0 to 1.0)
        border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
      },
    },

    server = {
      -- Port for the MCP over HTTP server. If nil, a random port is selected.
      port = nil,
    },

    -- List of models available in :AntigravitySelectModel
    models = {
      "gemini-3.8-flash",
      "gemini-3.7-flash",
      "gemini-3.6-flash",
      "gemini-3.1-pro",
    },
  },
  keys = {
    { "<leader>at", nil, desc = "AI/Antigravity" },
    { "<leader>atc", "<cmd>Antigravity<cr>", desc = "Toggle Antigravity" },
    { "<leader>atr", "<cmd>AntigravityResume<cr>", desc = "Resume Antigravity" },
    { "<leader>atm", "<cmd>AntigravitySelectModel<cr>", desc = "Select Antigravity model" },
    { "<leader>ata", "<cmd>AntigravityAsk<cr>", desc = "Ask Antigravity", mode = { "n", "v" } },
    {
      "<leader>atb",
      function()
        require("antigravity-cli.integrations").add_to_context(vim.api.nvim_buf_get_name(0))
      end,
      desc = "Add current buffer to Antigravity context",
    },
    -- Diff management (when in a (proposed) buffer)
    { "<leader>aty", "<cmd>AntigravityDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>atn", "<cmd>AntigravityDiffDeny<cr>", desc = "Deny diff" },
  },
}
