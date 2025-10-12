local M = {}
--[[
Usage:
-- Simple text float
local lines = { "Hello", "Press q to close" }
require("bare.float").open(lines)

-- Custom size and border
require("bare.float").open(lines, { width = 50, height = 10, border = "double" })

-- With buffer (for terminals)
local buf = vim.api.nvim_create_buf(false, true)
require("bare.float").open(buf, { width = 100, height = 30 })

]]
function M.open(content, opts)
  opts = opts or {}

  local buf
  local is_existing_buf = type(content) == "number"

  if is_existing_buf then
    buf = content
  else
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    if not opts.modifiable then
      vim.bo[buf].modifiable = false
    end
  end

  -- Calculate dimensions
  local width = opts.width
  local height = opts.height

  if not width or not height then
    if not is_existing_buf then
      width = width or math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, content))) + 4
      height = height or #content + 2
    else
      width = width or math.floor(vim.o.columns * 0.9)
      height = height or math.floor(vim.o.lines * 0.9)
    end
  end

  local row = opts.row or math.floor((vim.o.lines - height) / 2)
  local col = opts.col or math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "rounded",
  })

  -- Setup close function
  local function close_float()
    M.close(win)
    if opts.on_close then
      opts.on_close()
    end
  end

  -- Default close keymaps
  vim.keymap.set("n", "q", close_float, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", close_float, { buffer = buf, nowait = true, silent = true })

  return buf, win
end

-- Safely close window
function M.close(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

return M
