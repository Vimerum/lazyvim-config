return {
  "coder/claudecode.nvim",
  opts = {
    -- The command used to launch Claude Code (default: nil -> "claude").
    -- You can set this to a binary path, wrapper script, or command with flags.
    -- Examples:
    --   terminal_cmd = "/home/vimerum/.local/bin/claude",
    --   terminal_cmd = "claude --dangerously-skip-permissions",
    terminal_cmd = "claude",
  },
}
