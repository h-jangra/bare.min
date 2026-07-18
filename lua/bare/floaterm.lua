-- Usage:
--   :Floaterm
--   :Floaterm <cmd>
--   <leader>t to toggle

local M = {}

M.config = {
  width = 0.9,
  height = 0.9,
  border = "rounded",
}

M.state = {
  win = nil,
  buf = nil,
  cmd = nil,
}

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

local ui = require("bare.ui")

local function create_window()
  local buf, win = ui.float({
    width = math.floor(vim.o.columns * M.config.width),
    height = math.floor(vim.o.lines * M.config.height),
    border = M.config.border,
  })

  -- If we already have a buffer, switch the window to it
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.api.nvim_win_set_buf(win, M.state.buf)
    -- Clean up the temporary buffer created by ui.float
    vim.api.nvim_buf_delete(buf, { force = true })
  else
    M.state.buf = buf
  end

  vim.cmd.startinsert()
  vim.api.nvim_buf_set_keymap(M.state.buf, "t", "<Esc>", "<C-\\><C-n>:Floaterm<CR>", {
    noremap = true,
    silent = true,
  })

  M.state.win = win
end

function M.open(cmd)
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
    M.state.win = nil
    return
  end

  if cmd and cmd ~= "" then
    M.state.buf = vim.api.nvim_create_buf(false, true)
    create_window()
    M.state.cmd = cmd
    vim.fn.termopen(cmd)
    return
  end

  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    create_window()
    return
  end

  M.state.buf = vim.api.nvim_create_buf(false, true)
  create_window()
  M.state.cmd = vim.o.shell
  vim.fn.termopen(M.state.cmd)
end

vim.api.nvim_create_user_command("Floaterm", function(opts)
  if opts.args then
    M.open(opts.args)
  else
    M.open("")
  end
end, { nargs = "?", desc = "Open floating terminal" })

vim.keymap.set("n", "<leader>t", M.open, { desc = "Toggle floating terminal" })

return M
