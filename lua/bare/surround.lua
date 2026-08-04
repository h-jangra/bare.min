--[[
Keymaps:
  - Visual mode `sa`: Surround the selected text with a chosen character.
  - Normal mode `sa`: Surround the word under the cursor with a chosen character.
  - Normal mode `sd`: Delete surrounding characters around the cursor.
  - Normal mode `sc`: Change surrounding characters around the cursor.
  - Normal mode `sr`: Alias for sc.
--]]

local M = {}

local surround_pairs = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["<"] = ">", ["`"] = "`" }
local function pair(c) return surround_pairs[c] or c end

local function find_surround(c)
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
  local left = line:sub(1, col):match(".*()" .. vim.pesc(c))
  return left, left and line:find(pair(c), col, true)
end

local function get_word()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
  if not line:sub(col, col):match("%w") then return nil end
  return line:sub(1, col):match("()%w+$"), (line:find("%W", col) or (#line + 1)) - 1
end

function M.add(c)
  local start, end_ = get_word()
  if not start then return end
  local p = pair(c)
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line:sub(1, start - 1) .. c .. line:sub(start, end_) .. p .. line:sub(end_ + 1))
  vim.fn.cursor(vim.fn.line("."), start + 1)
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
  vim.api.nvim_set_current_line(
    line:sub(1, left - 1) .. new_c .. line:sub(left + 1, right - 1) .. pair(new_c) .. line:sub(right + 1)
  )
end

function M.setup()
  local map = vim.keymap.set
  map("x", "sa", function()
    local open = vim.fn.getcharstr()
    local close = pair(open)
    local keys = vim.api.nvim_replace_termcodes("<Esc>`>a" .. close .. "<Esc>`<i" .. open .. "<Esc>", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
  end)
  for lhs, fn in pairs({ sa = M.add, sd = M.delete, sc = M.change, sr = M.change }) do
    map("n", lhs, function() fn(vim.fn.getcharstr()) end)
  end
end

return M
