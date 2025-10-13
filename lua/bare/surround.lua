local M = {}
-- Surround pairs
M.pairs = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["<"] = ">", ["`"] = "`" }
-- Add surround in visual mode
function M.add(char)
  if not char or char == "" then return end
  local left, right = char, M.pairs[char] or char
  local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
  if #lines == 0 then return end

  if #lines == 1 then
    lines[1] = lines[1]:sub(1, s[3] - 1) .. left ..
        lines[1]:sub(s[3], e[3]) .. right ..
        lines[1]:sub(e[3] + 1)
  else
    lines[1] = lines[1]:sub(1, s[3] - 1) .. left .. lines[1]:sub(s[3])
    lines[#lines] = lines[#lines]:sub(1, e[3]) .. right .. lines[#lines]:sub(e[3] + 1)
  end

  vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, lines)
  vim.cmd('normal! <Esc>')
end

-- Find nearest surround around cursor
local function find_surround()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col('.')
  local left_pos, right_pos, left_char, right_char
  for i = col, 1, -1 do
    local c = line:sub(i, i)
    if M.pairs[c] then
      left_pos, left_char, right_char = i, c, M.pairs[c]
      break
    end
  end
  if not left_pos then return end
  for i = col, #line do
    if line:sub(i, i) == right_char then
      right_pos = i
      break
    end
  end
  if not right_pos then return end
  return left_pos, right_pos, left_char, right_char
end

-- Delete surround
function M.delete()
  local left_pos, right_pos = find_surround()
  if not left_pos then
    print("No surround found")
    return
  end
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col('.')
  line = line:sub(1, left_pos - 1) .. line:sub(left_pos + 1, right_pos - 1) .. line:sub(right_pos + 1)
  vim.api.nvim_set_current_line(line)
  if col > left_pos then vim.fn.cursor(vim.fn.line('.'), col - 1) end
end

-- Change surround
function M.change()
  local left_pos, right_pos = find_surround()
  if not left_pos then
    print("No surround found")
    return
  end
  local line = vim.api.nvim_get_current_line()
  local left = vim.fn.input("New left: ")
  if left == "" then return end
  local right = M.pairs[left] or vim.fn.input("New right: ")
  if right == "" then return end
  line = line:sub(1, left_pos - 1) .. left .. line:sub(left_pos + 1, right_pos - 1) .. right .. line:sub(right_pos + 1)
  vim.api.nvim_set_current_line(line)
end

-- Keymaps
function M.setup()
  vim.keymap.set('x', 'sa', function()
    local char = vim.fn.nr2char(vim.fn.getchar())
    M.add(char)
  end, { noremap = true, silent = true })
  vim.keymap.set("n", "sd", M.delete, { noremap = true, silent = true })
  vim.keymap.set("n", "sc", M.change, { noremap = true, silent = true })
end

return M
