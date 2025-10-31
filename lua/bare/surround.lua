--[[
Keymaps:
- Visual mode `sa`: Surround the selected text with a chosen character.
- Normal mode `sa`: Surround the word under the cursor with a chosen character.
- Normal mode `sd`: Delete surrounding characters around the cursor.
- Normal mode `sc`: Change surrounding characters around the cursor.
--]]

local M = {}
-- Supported pairs
M.pairs = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["<"] = ">", ["`"] = "`" }

-- Add surround
function M.add(left)
  local right = M.pairs[left] or left
  if not right then return end

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
  local right = M.pairs[left] or left
  if not right then return end

  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local row = vim.fn.line(".")

  local start_col = col
  local end_col = col

  while start_col > 1 and line:sub(start_col - 1, start_col - 1):match("[%w_]") do
    start_col = start_col - 1
  end

  while end_col <= #line and line:sub(end_col, end_col):match("[%w_]") do
    end_col = end_col + 1
  end
  end_col = end_col - 1

  if not line:sub(col, col):match("[%w_]") then
    print("Not on a word")
    return
  end

  local new_line = line:sub(1, start_col - 1) .. left .. line:sub(start_col, end_col) .. right .. line:sub(end_col + 1)
  vim.api.nvim_set_current_line(new_line)

  vim.fn.cursor(row, start_col)
end

local function find_surround()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
  for i = col, 1, -1 do
    local c = line:sub(i, i)
    local right = M.pairs[c]
    if right then
      for j = col, #line do
        if line:sub(j, j) == right then return i, j, c, right end
      end
    end
  end
end

function M.delete()
  local l, r = find_surround()
  local line = vim.api.nvim_get_current_line()

  if not l then
    local left = vim.fn.input("Left surround character to delete: ")
    if left == "" then return end
    local right = M.pairs[left] or vim.fn.input("Right surround character to delete: ")
    local s, e = line:find(left, 1, true), line:find(right, 1, true)
    if not s or not e then return print("Surround not found") end
    vim.api.nvim_set_current_line(line:sub(1, s - 1) .. line:sub(s + 1, e - 1) .. line:sub(e + 1))
  else
    vim.api.nvim_set_current_line(line:sub(1, l - 1) .. line:sub(l + 1, r - 1) .. line:sub(r + 1))
  end
end

function M.change()
  local l, r = find_surround()
  if not l then return print("No surround found") end
  local line = vim.api.nvim_get_current_line()
  local left = vim.fn.input("New left: ")
  if left == "" then return end
  local right = M.pairs[left] or vim.fn.input("New right: ")
  vim.api.nvim_set_current_line(line:sub(1, l - 1) .. left .. line:sub(l + 1, r - 1) .. right .. line:sub(r + 1))
end

function M.setup()
  -- Visual mode: surround selection
  vim.keymap.set('x', 'sa', function()
    local key = vim.fn.getchar()
    local char = type(key) == 'number' and vim.fn.nr2char(key) or key
    M.add(char)
  end, { noremap = true, silent = true })

  -- Normal mode: surround word under cursor
  vim.keymap.set('n', 'sa', function()
    local key = vim.fn.getchar()
    local char = type(key) == 'number' and vim.fn.nr2char(key) or key
    M.add_word(char)
  end, { noremap = true, silent = true })

  vim.keymap.set("n", "sd", M.delete, { noremap = true, silent = true })
  vim.keymap.set("n", "sc", M.change, { noremap = true, silent = true })
end

return M
