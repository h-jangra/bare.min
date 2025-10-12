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
local M = {}

function M.open(content, opts)
  opts = opts or {}

  local buf = type(content) == "number" and content or vim.api.nvim_create_buf(false, true)

  if type(content) == "table" then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.bo[buf].modifiable = false
  end

  local width = opts.width or 80
  local height = opts.height or 20

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = opts.border or "solid"
  })

  vim.keymap.set("n", "q", function() M.close(win) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function() M.close(win) end, { buffer = buf, nowait = true })

  return buf, win
end

function M.close(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

return M
