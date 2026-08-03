local M = {}

function M.float(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.6)

  local buf = opts.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
  end

  local enter = opts.enter
  if enter == nil then enter = true end

  local win_config = {
    relative = opts.relative or "editor",
    style = opts.style or "minimal",
    border = opts.border or "rounded",
    title = opts.title,
    title_pos = opts.title and (opts.title_pos or "center") or nil,
    width = width,
    height = height,
    row = opts.row or math.floor((vim.o.lines - height) / 3),
    col = opts.col or math.floor((vim.o.columns - width) / 2),
  }

  if opts.focusable ~= nil then
    win_config.focusable = opts.focusable
  end
  if opts.zindex ~= nil then
    win_config.zindex = opts.zindex
  end

  local win
  if opts.win and vim.api.nvim_win_is_valid(opts.win) then
    vim.api.nvim_win_set_config(opts.win, win_config)
    win = opts.win
  else
    win = vim.api.nvim_open_win(buf, enter, win_config)
  end

  return buf, win
end

return M
