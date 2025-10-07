local M = {}

-- Store registered pairs
local autopairs = {}

function M.setup(config)
  config = config or {}

  -- Default pairs
  local default_pairs = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['"'] = '"',
    ["'"] = "'",
    ['`'] = '`',
  }

  autopairs = config.pairs or default_pairs

  -- Create mappings
  for open, close in pairs(autopairs) do
    if open == close then
      -- Symmetric pairs (quotes)
      vim.keymap.set('i', open, function() return M.closeopen(open, close) end, { expr = true })
    else
      -- Asymmetric pairs (brackets)
      vim.keymap.set('i', open, function() return M.open(open, close) end, { expr = true })
      vim.keymap.set('i', close, function() return M.close(open, close) end, { expr = true })
    end
  end

  -- Backspace and CR mappings
  vim.keymap.set('i', '<BS>', M.bs, { expr = true })
  vim.keymap.set('i', '<CR>', M.cr, { expr = true })
end

-- Get characters around cursor
local function get_chars()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col('.') - 1
  local before = col > 0 and line:sub(col, col) or ''
  local after = line:sub(col + 1, col + 1) or ''
  return before, after
end

-- Open pair
function M.open(open, close)
  local before, after = get_chars()
  -- Don't pair after backslash or alphanumeric (for quotes)
  if before == '\\' or (open == close and before:match('[%w]')) then
    return open
  end
  return open .. close .. '<Left>'
end

-- Close pair
function M.close(open, close)
  local _, after = get_chars()
  -- Jump over if next char is the closing pair
  if after == close then
    return '<Right>'
  end
  return close
end

-- Close-open (for symmetric pairs)
function M.closeopen(open, close)
  local _, after = get_chars()
  -- Jump over if next char matches
  if after == close then
    return '<Right>'
  end
  -- Otherwise, open pair
  return M.open(open, close)
end

-- Backspace - delete pair if between matching pair
function M.bs()
  local before, after = get_chars()
  -- Check if we're between a pair
  for open, close in pairs(autopairs) do
    if before == open and after == close then
      return '<BS><Del>'
    end
  end
  return '<BS>'
end

-- CR - add line between pair
function M.cr()
  local before, after = get_chars()
  -- Check if we're between a pair
  for open, close in pairs(autopairs) do
    if before == open and after == close then
      return '<CR><C-o>O'
    end
  end
  return '<CR>'
end

return M
