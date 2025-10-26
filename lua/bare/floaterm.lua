local M = {}

M.config = {
  width = 0.4,
  height = 0.4,
  border = "single",
}

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

function M.open(cmd)
  local width = math.floor(vim.o.columns * M.config.width)
  local height = math.floor(vim.o.lines * M.config.height)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = M.config.border,
  })

  if cmd and cmd ~= "" then
    vim.fn.jobstart(cmd, { term = true })
  else
    vim.fn.jobstart(vim.o.shell, { term = true })
  end

  vim.cmd("startinsert")

  vim.api.nvim_buf_set_keymap(buf, "t", "<Esc>", "<C-\\><C-n>:close<CR>", { noremap = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true })

  M.terminal_win = win
  M.terminal_buf = buf

  return { buf = buf, win = win }
end

function M.toggle()
  if M.terminal_win and vim.api.nvim_win_is_valid(M.terminal_win) then
    vim.api.nvim_win_close(M.terminal_win, true)
    M.terminal_win = nil
    M.terminal_buf = nil
  else
    M.open()
  end
end

function M.run_command(cmd)
  if M.terminal_win and vim.api.nvim_win_is_valid(M.terminal_win) then
    vim.api.nvim_win_close(M.terminal_win, true)
  end

  M.open(cmd)
end

vim.api.nvim_create_user_command("FloatingTerm", function(opts)
  M.open(opts.args)
end, { nargs = '?', desc = "Open floaterm with optional command" })

vim.api.nvim_create_user_command("FloatingTermToggle", M.toggle, { desc = "Toggle floating terminal" })

vim.api.nvim_create_user_command("Floaterm", function(opts)
  M.run_command(opts.args)
end, { nargs = '+', desc = "Run command in floating terminal" })

return M
