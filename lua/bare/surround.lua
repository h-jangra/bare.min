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
  if not c or #c ~= 1 then return end
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local pair = get_pair(c)
  local is_same = c == pair
  
  local left
  for i = col - 1, 1, -1 do
    local char = line:sub(i, i)
    if char == c then
      if is_same and i > 1 and line:sub(i-1, i-1) == "\\" then goto continue end
      left = i
      break
    end
    ::continue::
  end
  if not left then return end
  
  local right
  if is_same then
    local depth = 1
    for i = left + 1, #line do
      local char = line:sub(i, i)
      if char == c and (i == 1 or line:sub(i-1, i-1) ~= "\\") then
        depth = depth - 1
        if depth == 0 then right = i; break end
      end
    end
  else
    local depth = 1
    for i = left + 1, #line do
      local char = line:sub(i, i)
      if char == c then depth = depth + 1
      elseif char == pair then
        depth = depth - 1
        if depth == 0 then right = i; break end
      end
    end
  end
  
  if not right or right <= left then return end
  return left, right
end

local function get_word()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  if col > #line or not line:sub(col, col):match("[%w_]") then return end
  local s, e = col, col
  while s > 1 and line:sub(s - 1, s - 1):match("[%w_]") do s = s - 1 end
  while e < #line and line:sub(e + 1, e + 1):match("[%w_]") do e = e + 1 end
  return s, e
end

local function get_char()
  local k = vim.fn.getchar()
  if k == 0 or k == 27 then return end
  return type(k) == 'number' and vim.fn.nr2char(k) or k
end

function M.add(c)
  if not c or c == "" then return end
  local pair = get_pair(c)
  local mode = vim.fn.mode()
  
  if mode:match("[vV]") then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local visual_mode = mode
    
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'nx', true)
    
    vim.schedule(function()
      local buf_lines = vim.api.nvim_buf_line_count(0)
      if start_pos[2] < 1 or start_pos[2] > buf_lines or end_pos[2] < 1 or end_pos[2] > buf_lines then return end
      
      local start_line = math.max(0, start_pos[2] - 1)
      local end_line = math.min(buf_lines, end_pos[2])
      local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
      if #lines == 0 then return end
      
      if visual_mode == "V" then
        if #lines == 1 then
          lines[1] = c .. lines[1] .. pair
        else
          lines[1] = c .. lines[1]
          lines[#lines] = lines[#lines] .. pair
        end
      else
        local col_start = start_pos[3]
        local col_end = end_pos[3]
        if col_start > 2147480000 then col_start = 1 end
        if col_end > 2147480000 then col_end = #lines[1] + 1 end
        
        if start_pos[2] == end_pos[2] then
          local line = lines[1]
          col_start = math.min(col_start, #line + 1)
          col_end = math.min(col_end, #line)
          lines[1] = line:sub(1, col_start - 1) .. c .. line:sub(col_start, col_end) .. pair .. line:sub(col_end + 1)
        else
          local first_len = #lines[1]
          col_start = math.min(col_start, first_len + 1)
          lines[1] = lines[1]:sub(1, col_start - 1) .. c .. lines[1]:sub(col_start)
          
          local last_len = #lines[#lines]
          col_end = math.min(col_end, last_len)
          lines[#lines] = lines[#lines]:sub(1, col_end) .. pair .. lines[#lines]:sub(col_end + 1)
        end
      end
      
      vim.api.nvim_buf_set_lines(0, start_line, end_line, false, lines)
      if visual_mode == "V" then
        vim.fn.cursor(start_pos[2], 1)
      else
        vim.fn.cursor(start_pos[2], math.min(start_pos[3] + 1, #vim.api.nvim_get_current_line()))
      end
    end)
  else
    local start, end_ = get_word()
    if not start then vim.notify("Not on a word", vim.log.levels.WARN); return end
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_set_current_line(line:sub(1, start - 1) .. c .. line:sub(start, end_) .. pair .. line:sub(end_ + 1))
    vim.fn.cursor(vim.fn.line("."), start + 1)
  end
end

function M.delete(c)
  if not c or c == "" then return end
  local left, right = find_surround(c)
  if not left or not right then vim.notify("Not found", vim.log.levels.WARN); return end
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line:sub(1, left - 1) .. line:sub(left + 1, right - 1) .. line:sub(right + 1))
  vim.fn.cursor(vim.fn.line("."), left)
end

function M.change(c)
  if not c or c == "" then return end
  local left, right = find_surround(c)
  if not left or not right then vim.notify("Not found", vim.log.levels.WARN); return end
  local new_c = get_char()
  if not new_c or new_c == "" then return end
  local pair = get_pair(new_c)
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line:sub(1, left - 1) .. new_c .. line:sub(left + 1, right - 1) .. pair .. line:sub(right + 1))
  vim.fn.cursor(vim.fn.line("."), left + 1)
end

function M.setup()
  local map = vim.keymap.set
  map('x', 'sa', function() M.add(get_char()) end, {})
  map('n', 'sa', function() M.add(get_char()) end, {})
  map('n', 'sd', function() M.delete(get_char()) end, {})
  map('n', 'sc', function() M.change(get_char()) end, {})
  map('n', 'sr', function() M.change(get_char()) end, {})
end

return M
