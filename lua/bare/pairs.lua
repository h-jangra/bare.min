local M = {}

local pair_map = {
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
  ['"'] = '"',
  ["'"] = "'",
  ['`'] = '`',
  ['<'] = '>',
}

function M.setup(config)
  config = config or {}
  pair_map = config.pairs or pair_map

  for open, close in pairs(pair_map) do
    vim.keymap.set('i', open, function() return M.insert_pair(open, close) end, { expr = true })
    if open ~= close then
      vim.keymap.set('i', close, function() return M.skip_close(close) end, { expr = true })
    end
  end

  vim.keymap.set('i', '<BS>', M.handle_backspace, { expr = true })
  vim.keymap.set('i', '<CR>', M.handle_enter, { expr = true })
end

function M.get_surrounding_chars()
  local col = vim.fn.col('.') - 1
  local line = vim.api.nvim_get_current_line()
  return line:sub(col, col), line:sub(col + 1, col + 1)
end

function M.insert_pair(open, close)
  local before, _ = M.get_surrounding_chars()
  if before == '\\' or (open == close and before:match('%w')) then
    return open
  end
  return open .. close .. '<Left>'
end

function M.skip_close(close)
  local _, after = M.get_surrounding_chars()
  return after == close and '<Right>' or close
end

function M.handle_backspace()
  local before, after = M.get_surrounding_chars()
  for open, close in pairs(pair_map) do
    if before == open and after == close then
      return '<BS><Del>'
    end
  end
  return '<BS>'
end

function M.handle_enter()
  local before, after = M.get_surrounding_chars()
  for open, close in pairs(pair_map) do
    if before == open and after == close then
      return '<CR><Esc>O'
    end
  end
  return '<CR>'
end

return M
