local M = {}

local autopairs = {}

function M.setup(config)
  config = config or {}

  local default_pairs = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['"'] = '"',
    ["'"] = "'",
    ['`'] = '`',
  }

  autopairs = config.pairs or default_pairs

  for open, close in pairs(autopairs) do
    if open == close then
      vim.keymap.set('i', open, function() return M.closeopen(open, close) end, { expr = true })
    else
      vim.keymap.set('i', open, function() return M.open(open, close) end, { expr = true })
      vim.keymap.set('i', close, function() return M.close(open, close) end, { expr = true })
    end
  end

  vim.keymap.set('i', '<BS>', M.bs, { expr = true })
  vim.keymap.set('i', '<CR>', M.cr, { expr = true })
end

local function get_chars()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col('.') - 1
  local before = col > 0 and line:sub(col, col) or ''
  local after = line:sub(col + 1, col + 1) or ''
  return before, after
end

function M.open(open, close)
  local before, _ = get_chars()
  if before == '\\' or (open == close and before:match('[%w]')) then
    return open
  end
  return open .. close .. '<Left>'
end

function M.close(_, close)
  local _, after = get_chars()
  if after == close then
    return '<Right>'
  end
  return close
end

function M.closeopen(open, close)
  local _, after = get_chars()
  if after == close then
    return '<Right>'
  end
  return M.open(open, close)
end

function M.bs()
  local before, after = get_chars()
  for open, close in pairs(autopairs) do
    if before == open and after == close then
      return '<BS><Del>'
    end
  end
  return '<BS>'
end

function M.cr()
  local before, after = get_chars()
  for open, close in pairs(autopairs) do
    if before == open and after == close then
      return '<CR><C-o>O'
    end
  end
  return '<CR>'
end

return M
