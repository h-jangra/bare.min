local M = {}

function M.float(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.6)
  
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = opts.border or "rounded",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 3),
    col = math.floor((vim.o.columns - width) / 2),
  })
  
  return buf, win
end

return M
