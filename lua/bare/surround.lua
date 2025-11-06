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

-- Reverse lookup for closing chars
local function get_pair(char)
  return M.pairs[char] or char
end

local function find_surround()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")

  -- Search backwards for opening char
  for i = col - 1, 1, -1 do
    local c = line:sub(i, i)
    local right = M.pairs[c]
    if right then
      -- Search forwards for closing char
      for j = col, #line do
        if line:sub(j, j) == right then
          return i, j, c, right
        end
      end
    end
  end
end

local function get_word_range()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")

  if not line:sub(col, col):match("[%w_]") then
    return nil
  end

  local start_col = col
  local end_col = col

  while start_col > 1 and line:sub(start_col - 1, start_col - 1):match("[%w_]") do
    start_col = start_col - 1
  end

  while end_col <= #line and line:sub(end_col, end_col):match("[%w_]") do
    end_col = end_col + 1
  end

  return start_col, end_col - 1
end

function M.add(left)
  local right = get_pair(left)

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)

  vim.schedule(function()
    local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
    local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
    if #lines == 0 then return end

    if #lines == 1 then
      lines[1] = lines[1]:sub(1, s[3] - 1) .. left .. lines[1]:sub(s[3], e[3]) .. right .. lines[1]:sub(e[3] + 1)
    else
      lines[1] = lines[1]:sub(1, s[3] - 1) .. left .. lines[1]:sub(s[3])
      lines[#lines] = lines[#lines]:sub(1, e[3]) .. right .. lines[#lines]:sub(e[3] + 1)
    end

    vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, lines)
    vim.cmd('normal! `<')
  end)
end

function M.add_word(left)
  local right = get_pair(left)
  local start_col, end_col = get_word_range()

  if not start_col then
    vim.notify("Not on a word", vim.log.levels.WARN)
    return
  end

  local line = vim.api.nvim_get_current_line()
  local row = vim.fn.line(".")
  local new_line = line:sub(1, start_col - 1) .. left .. line:sub(start_col, end_col) .. right .. line:sub(end_col + 1)

  vim.api.nvim_set_current_line(new_line)
  vim.fn.cursor(row, start_col)
end

function M.delete()
  local l, r = find_surround()

  if l then
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_set_current_line(line:sub(1, l - 1) .. line:sub(l + 1, r - 1) .. line:sub(r + 1))
    return
  end

  local left = vim.fn.input("Left char: ")
  if left == "" then return end

  local line = vim.api.nvim_get_current_line()
  local right = get_pair(left)
  local s, e = line:find(vim.pesc(left), 1, true), line:find(vim.pesc(right), 1, true)

  if not s or not e then
    vim.notify("Surround not found", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_set_current_line(line:sub(1, s - 1) .. line:sub(s + 1, e - 1) .. line:sub(e + 1))
end

function M.change()
  local l, r = find_surround()

  if not l then
    vim.notify("No surround found", vim.log.levels.WARN)
    return
  end

  local left = vim.fn.input("New left: ")
  if left == "" then return end

  local right = get_pair(left)
  local line = vim.api.nvim_get_current_line()

  vim.api.nvim_set_current_line(line:sub(1, l - 1) .. left .. line:sub(l + 1, r - 1) .. right .. line:sub(r + 1))
end

function M.setup()
  vim.keymap.set('x', 'sa', function()
    local key = vim.fn.getchar()
    local char = type(key) == 'number' and vim.fn.nr2char(key) or key
    M.add(char)
  end, { noremap = true, silent = true })

  vim.keymap.set('n', 'sa', function()
    local key = vim.fn.getchar()
    local char = type(key) == 'number' and vim.fn.nr2char(key) or key
    M.add_word(char)
  end, { noremap = true, silent = true })

  vim.keymap.set('n', 'sd', M.delete, { noremap = true, silent = true })
  vim.keymap.set('n', 'sc', M.change, { noremap = true, silent = true })
  vim.keymap.set('n', 'sr', M.change, { noremap = true, silent = true })
end

return M
