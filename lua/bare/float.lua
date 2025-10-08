---@diagnostic disable: undefined-global
local M = {}
-- Creates a simple floating window with lines
-- lines: table of strings
-- opts: optional table {width, height, row, col, border}
-- keymaps: table of {key = function(buf, win) end}
--[[

local float = require("float")
local lines = { "Hello", "Press q to close" }
float.open(lines)

]]
function M.open(lines, opts, keymaps)
  opts = opts or {}
  local width = opts.width or math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, lines))) + 2
  local height = opts.height or #lines + 2
  local row = opts.row or math.floor((vim.o.lines - height) / 2)
  local col = opts.col or math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- default 'q' closes window
  vim.keymap.set("n", "q", function() M.close(win) end, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", function() M.close(win) end, { buffer = buf, nowait = true, silent = true })

  -- set keymaps for this buffer
  if keymaps then
    for k, fn in pairs(keymaps) do
      vim.keymap.set("n", k, function() fn(buf, win) end, { buffer = buf, nowait = true, silent = true })
    end
  end

  return buf, win
end

-- Safely close window
function M.close(win)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

return M
