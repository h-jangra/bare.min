-- bare.hint.lua
local M = {}
local state = {
  prefix = "",
  win = nil,
  buf = nil,
  current_mode = "n",
  active = false,
  original_cursor = nil,
  timeout_timer = nil,
  keymap_ns = vim.api.nvim_create_namespace("bare_hint")
}

--- Close the floating window and reset state.
local function close_win()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.win, state.buf = nil, nil
  if state.timeout_timer then
    state.timeout_timer:stop()
    state.timeout_timer = nil
  end
  if state.original_cursor then
    vim.api.nvim_win_set_cursor(0, state.original_cursor)
  end
end

--- Expand special keys like <leader> to their actual values
local function expand_special_keys(lhs)
  local leader = vim.g.mapleader or "\\"
  return lhs:gsub("<leader>", leader):gsub("<localleader>", vim.g.maplocalleader or "\\")
end

--- Get all keymaps for the current mode and prefix
local function get_mappings(prefix, mode)
  local maps = {}
  local expanded_prefix = expand_special_keys(prefix)
  local keymaps = vim.api.nvim_get_keymap(mode)

  for _, km in ipairs(keymaps) do
    local expanded_lhs = expand_special_keys(km.lhs)
    if expanded_lhs:match("^" .. vim.pesc(expanded_prefix)) then
      local suffix = expanded_lhs:sub(#expanded_prefix + 1)
      if suffix ~= "" then
        local first_char = suffix:sub(1, 1)
        if not maps[first_char] then
          maps[first_char] = {
            desc = km.desc,
            rhs = km.rhs,
            full = expanded_lhs,
            suffix = suffix
          }
        end
      end
    end
  end
  return maps
end

--- Check if the current prefix matches any complete mapping
local function is_complete_mapping(prefix, mode)
  local expanded_prefix = expand_special_keys(prefix)
  local keymaps = vim.api.nvim_get_keymap(mode)

  for _, km in ipairs(keymaps) do
    local expanded_lhs = expand_special_keys(km.lhs)
    if expanded_lhs == expanded_prefix then
      return true, {
        full = expanded_lhs,
        lhs = km.lhs,
        rhs = km.rhs,
        desc = km.desc
      }
    end
  end
  return false, nil
end

--- Count sub-mappings for a key
local function count_sub_mappings(prefix, key, mode)
  local count = 0
  local expanded_prefix = expand_special_keys(prefix .. key)
  local keymaps = vim.api.nvim_get_keymap(mode)

  for _, km in ipairs(keymaps) do
    local expanded_lhs = expand_special_keys(km.lhs)
    if expanded_lhs:match("^" .. vim.pesc(expanded_prefix)) and expanded_lhs ~= expanded_prefix then
      count = count + 1
    end
  end
  return count
end

--- Show the floating window
local function show_window()
  if not state.active then return end

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  local mappings = get_mappings(state.prefix, state.current_mode)
  local lines = {}

  for key, map in pairs(mappings) do
    local sub_count = count_sub_mappings(state.prefix, key, state.current_mode)
    if sub_count and sub_count > 0 then
      table.insert(lines, string.format("%s +%d", key, sub_count))
    else
      table.insert(lines, string.format("%s - %s", key, map.desc or map.rhs or "No description"))
    end
  end

  table.sort(lines)

  if #lines == 0 then
    close_win()
    state.active = false
    vim.on_key(nil, state.keymap_ns)
    return
  end

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set title as first line
  local title = state.prefix:gsub("<leader>", "Leader"):gsub("<localleader>", "LocalLeader")
  if title == "" then title = "Mappings" end
  table.insert(lines, 1, title)

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Highlight title
  vim.api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)

  -- Calculate window dimensions
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width, 40)
  width = math.max(width, 20)

  local height = math.min(#lines, 10)

  -- Position at bottom-right
  local row = vim.o.lines - height - 2
  local col = vim.o.columns - width - 2

  -- Create window
  local win = vim.api.nvim_open_win(buf, false, {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    anchor = "NE",
    border = "single",
  })

  -- Set highlight
  vim.api.nvim_set_hl(0, "Title", { bold = true, fg = "#ffffff", bg = "#5f87af" })
  vim.api.nvim_win_set_hl_ns(win, 0)

  state.win, state.buf = win, buf
end

--- Reset timeout timer
local function reset_timeout()
  if state.timeout_timer then
    state.timeout_timer:stop()
  end
  state.timeout_timer = vim.loop.new_timer()
  state.timeout_timer:start(1500, 0, vim.schedule_wrap(function()
    if state.active then
      state.active = false
      close_win()
      vim.on_key(nil, state.keymap_ns)
    end
  end))
end

--- Get character safely with redraws
local function getcharstr()
  local timer = vim.loop.new_timer()
  if timer then
    timer:start(0, 50, vim.schedule_wrap(function() vim.cmd('redraw') end))

    local ok, char = pcall(vim.fn.getcharstr)
    timer:stop()

    if not ok or char == '' or char == '\27' then
      return nil
    end
    return char
  end
end

--- Execute the final keymap
local function execute_mapping(map)
  state.active = false
  close_win()
  vim.on_key(nil, state.keymap_ns)

  -- Use the correct feedkeys approach from mini.clue
  local keys_to_exec = map.full or map.lhs or state.prefix
  if not keys_to_exec then return end

  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys_to_exec, true, true, true),
    'mit',
    false
  )
end

--- Main input loop
local function query_loop()
  if not state.active then return end

  show_window()
  reset_timeout()

  while state.active do
    local char = getcharstr()

    if char == nil then
      state.active = false
      close_win()
      vim.on_key(nil, state.keymap_ns)
      return
    end

    -- ESC to cancel
    if char == "\27" then
      state.active = false
      close_win()
      vim.on_key(nil, state.keymap_ns)
      return
    end

    local new_prefix = state.prefix .. char

    -- Check if this is a complete mapping
    local is_complete, map = is_complete_mapping(new_prefix, state.current_mode)
    if is_complete then
      execute_mapping(map)
      return
    end

    -- Check if new prefix has valid continuations
    local next_mappings = get_mappings(new_prefix, state.current_mode)
    if vim.tbl_count(next_mappings) == 0 then
      state.active = false
      close_win()
      vim.on_key(nil, state.keymap_ns)
      return
    end

    -- Update prefix and continue
    state.prefix = new_prefix
    reset_timeout()
    show_window()
  end
end

--- Start the hint system
function M.start(prefix, mode)
  if state.active then return end

  state.prefix = prefix
  state.current_mode = mode
  state.active = true

  -- Create highlight for title
  vim.api.nvim_set_hl(0, "Title", { bold = true, fg = "#ffffff", bg = "#5f87af" })

  -- Save original cursor position
  state.original_cursor = vim.api.nvim_win_get_cursor(0)

  -- Start the query loop (non-blocking, uses getcharstr internally)
  query_loop()
end

function M.stop()
  state.active = false
  close_win()
  vim.on_key(nil, state.keymap_ns)
end

return M
