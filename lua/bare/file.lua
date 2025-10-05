local M = {}
local fn = vim.fn

-- State
local state = {
  buf = nil,
  win = nil,
  cwd = nil,
}

local has_icons, icons = pcall(require, "bare.icons")

local function get_icon(name, is_dir)
  if is_dir then
    return "📁 "
  end

  if has_icons then
    local ext = name:match("^.+%.(.+)$")
    if ext then
      local icon = icons.get(ext)
      if icon then
        return icon .. " "
      end
    end
  end

  return "󰈚 "
end

-- Read directory contents
local function read_dir(path)
  local items = {}
  local handle = vim.loop.fs_scandir(path)

  if not handle then
    return items
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end

    local full_path = path .. "/" .. name
    local is_dir = type == "directory"

    table.insert(items, {
      name = name,
      path = full_path,
      is_dir = is_dir,
    })
  end

  -- Sort: dir first, then alphabetically
  table.sort(items, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end
    return a.name:lower() < b.name:lower()
  end)

  return items
end

-- Render the explorer
local function render()
  if not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local items = read_dir(state.cwd)
  local lines = {}

  -- Header
  table.insert(lines, state.cwd .. "/")

  -- Optional parent directory line
  if state.cwd ~= "/" then
    table.insert(lines, "📁 ../")
  end

  -- Items
  for _, item in ipairs(items) do
    local icon = get_icon(item.name, item.is_dir)
    local suffix = item.is_dir and "/" or ""
    table.insert(lines, " " .. icon .. item.name .. suffix)
  end

  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
end
-- Get item at cursor
local function get_current_item()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  -- Skip header lines
  if row <= 2 then
    return nil
  end

  -- Parent directory
  if line:match("%.%./") then
    return {
      name = "..",
      path = fn.fnamemodify(state.cwd, ":h"),
      is_dir = true,
    }
  end

  -- Extract name from line
  local name = line:match("%s+[^%s]+%s+(.+)")
  if not name then
    return nil
  end

  name = name:gsub("/$", "") -- Remove trailing slash
  local full_path = state.cwd .. "/" .. name

  return {
    name = name,
    path = full_path,
    is_dir = fn.isdirectory(full_path) == 1,
  }
end

-- Open file or directory
local function open_item()
  local item = get_current_item()
  if not item then
    return
  end

  if item.is_dir then
    state.cwd = item.path
    render()
  else
    -- Get the previous window
    local prev_win = fn.win_getid(fn.winnr('#'))

    -- Close explorer
    M.close()

    -- If previous window is valid and not the explorer, use it
    if prev_win ~= 0 and vim.api.nvim_win_is_valid(prev_win) then
      vim.api.nvim_set_current_win(prev_win)
    end

    -- Open file in current window
    vim.cmd("edit " .. fn.fnameescape(item.path))
  end
end

-- Go up one directory
local function go_up()
  if state.cwd ~= "/" then
    state.cwd = fn.fnamemodify(state.cwd, ":h")
    render()
  end
end

-- Create new file (netrw-style with %)
local function create_file()
  local filename = fn.input("New file name: ")
  if filename == "" then
    return
  end

  local full_path = state.cwd .. "/" .. filename

  -- Get the previous window
  local prev_win = fn.win_getid(fn.winnr('#'))

  -- Close explorer
  M.close()

  -- If previous window is valid, use it
  if prev_win ~= 0 and vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end

  -- Create and open file
  vim.cmd("edit " .. fn.fnameescape(full_path))
end

-- Create new directory (netrw-style with d)
local function create_dir()
  local dirname = fn.input("New directory name: ")
  if dirname == "" then
    return
  end

  local full_path = state.cwd .. "/" .. dirname
  fn.mkdir(full_path, "p")
  render()
end

-- Delete file/directory (netrw-style with D)
local function delete_item()
  local item = get_current_item()
  if not item or item.name == ".." then
    return
  end

  local confirm = fn.input("Delete '" .. item.name .. "'? (y/n): ")
  if confirm:lower() ~= "y" then
    return
  end

  if item.is_dir then
    fn.delete(item.path, "rf")
  else
    fn.delete(item.path)
  end

  render()
end

-- Rename file/directory (netrw-style with R)
local function rename_item()
  local item = get_current_item()
  if not item or item.name == ".." then
    return
  end

  local new_name = fn.input("Rename to: ", item.name)
  if new_name == "" or new_name == item.name then
    return
  end

  local new_path = state.cwd .. "/" .. new_name
  fn.rename(item.path, new_path)
  render()
end

-- Set up keymaps (netrw-style)
local function setup_keymaps()
  local opts = { buffer = state.buf, silent = true, nowait = true }

  -- Navigation
  vim.keymap.set("n", "<CR>", open_item, opts)
  vim.keymap.set("n", "l", open_item, opts)
  vim.keymap.set("n", "h", go_up, opts)
  vim.keymap.set("n", "-", go_up, opts)

  -- File operations
  vim.keymap.set("n", "%", create_file, opts) -- % creates file
  vim.keymap.set("n", "d", create_dir, opts)  -- d creates directory
  vim.keymap.set("n", "D", delete_item, opts) -- D deletes
  vim.keymap.set("n", "R", rename_item, opts) -- R renames

  -- Close
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
  vim.keymap.set("n", "r", render, opts) -- r refreshes
end

-- Open explorer
function M.open()
  -- If already open, just focus it
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return
  end

  -- Create buffer if needed
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(state.buf, "Explorer")

    -- Buffer options
    vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(state.buf, "filetype", "explorer")
    vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
    vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
    vim.api.nvim_buf_set_option(state.buf, "buflisted", false)
  end

  -- Always reset to root directory (getcwd) when opening
  state.cwd = fn.getcwd()

  -- Create window by splitting, not creating new buffer first
  vim.cmd("topleft 35vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)

  -- Window options
  vim.api.nvim_win_set_option(state.win, "number", false)
  vim.api.nvim_win_set_option(state.win, "relativenumber", false)
  vim.api.nvim_win_set_option(state.win, "signcolumn", "no")
  vim.api.nvim_win_set_option(state.win, "wrap", false)
  vim.api.nvim_win_set_option(state.win, "cursorline", true)

  -- Set up keymaps and render
  setup_keymaps()
  render()
end

-- Close explorer
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
end

-- Toggle explorer
function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Set up toggle keymap
  vim.keymap.set("n", "<leader>e", M.toggle, { desc = "Toggle file explorer" })

  -- Optional: auto-close on file open
  if opts.auto_close ~= false then
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.bo.filetype ~= "explorer" and state.win and vim.api.nvim_win_is_valid(state.win) then
          local wins = vim.api.nvim_list_wins()
          if #wins > 1 then
            M.close()
          end
        end
      end,
    })
  end
end

return M
