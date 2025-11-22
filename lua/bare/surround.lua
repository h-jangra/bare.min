--[[
Keymaps:
  - Visual mode `sa`: Surround the selected text with a chosen character.
  - Normal mode `sa`: Surround the word under the cursor with a chosen character.
  - Normal mode `sd`: Delete surrounding characters around the cursor.
  - Normal mode `sc`: Change surrounding characters around the cursor.
  - Normal mode `sr`: Alias for sc.
--]]

local M = {}
M.pairs = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["<"] = ">", ["`"] = "`" }

local function get_pair(c) return M.pairs[c] or c end

local function find_surround(c)
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local pair = get_pair(c)

  local left = nil
  for i = col - 1, 1, -1 do
    if line:sub(i, i) == c then
      left = i
      break
    end
  end

  if not left then return nil end

  local right = nil
  for i = #line, col, -1 do
    if line:sub(i, i) == pair then
      right = i
      break
    end
  end

  return left, right
end

local function get_word()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")

  if not line:sub(col, col):match("%w") then return nil end

  local s, e = col, col
  while s > 1 and line:sub(s - 1, s - 1):match("%w") do s = s - 1 end
  while e < #line and line:sub(e + 1, e + 1):match("%w") do e = e + 1 end

  return s, e
end

function M.add(c)
  local pair = get_pair(c)
  local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")

  if s[2] ~= 0 and e[2] ~= 0 then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)
    vim.schedule(function()
      local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
      if #lines == 1 then
        lines[1] = lines[1]:sub(1, s[3] - 1) .. c .. lines[1]:sub(s[3], e[3]) .. pair .. lines[1]:sub(e[3] + 1)
      else
        lines[1] = lines[1]:sub(1, s[3] - 1) .. c .. lines[1]:sub(s[3])
        lines[#lines] = lines[#lines]:sub(1, e[3]) .. pair .. lines[#lines]:sub(e[3] + 1)
      end
      vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, lines)
    end)
  else
    local start, end_ = get_word()
    if not start then
      vim.notify("Not on a word", vim.log.levels.WARN)
      return
    end
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_set_current_line(line:sub(1, start - 1) .. c .. line:sub(start, end_) .. pair .. line:sub(end_ + 1))
    vim.fn.cursor(vim.fn.line("."), start + 1)
  end
end

function M.delete(c)
  local left, right = find_surround(c)
  if not left or not right then
    vim.notify("Not found", vim.log.levels.WARN)
    return
  end
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line:sub(1, left - 1) .. line:sub(left + 1, right - 1) .. line:sub(right + 1))
  vim.fn.cursor(vim.fn.line("."), left)
end

function M.change(c)
  local left, right = find_surround(c)
  if not left or not right then
    vim.notify("Not found", vim.log.levels.WARN)
    return
  end
  local new_c = vim.fn.getcharstr()
  if new_c == "" then return end
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line:sub(1, left - 1) ..
    new_c .. line:sub(left + 1, right - 1) .. get_pair(new_c) .. line:sub(right + 1))
end

function M.setup()
  local map = vim.keymap.set
  local get_char = function()
    local k = vim.fn.getchar()
    return type(k) == 'number' and vim.fn.nr2char(k) or k
  end
  map('x', 'sa', function() M.add(get_char()) end, {})
  map('n', 'sa', function() M.add(get_char()) end, {})
  map('n', 'sd', function() M.delete(get_char()) end, {})
  map('n', 'sc', function() M.change(get_char()) end, {})
  map('n', 'sr', function() M.change(get_char()) end, {})
end

return M
