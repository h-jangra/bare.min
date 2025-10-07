local M = {}
local fn = vim.fn

-- State
local state = {
  buf = nil,
  win = nil,
  root = nil,
  show_hidden = false,
  expanded = {}, -- Track expanded directories
}

local has_icons, icons = pcall(require, "bare.icons")

local function get_icon(name, is_dir, is_expanded)
  if is_dir then
    if is_expanded then
      return "📂 "
    else
      return "📁 "
    end
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

  return " "
end

-- Check if a file is hidden
local function is_hidden(name)
  return name:sub(1, 1) == "."
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

    if state.show_hidden or not is_hidden(name) then
      local full_path = path .. "/" .. name
      local is_dir = type == "directory"

      table.insert(items, {
        name = name,
        path = full_path,
        is_dir = is_dir,
      })
    end
  end

  -- Sort: directories first, then alphabetically
  table.sort(items, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end
    return a.name:lower() < b.name:lower()
  end)

  return items
end

-- Build tree recursively
local function build_tree(path, depth, lines, line_to_path)
  depth = depth or 0
  lines = lines or {}
  line_to_path = line_to_path or {}

  local items = read_dir(path)
  local indent = string.rep("  ", depth)

  for _, item in ipairs(items) do
    local is_expanded = state.expanded[item.path]
    local icon = get_icon(item.name, item.is_dir, is_expanded)
    local line = indent .. icon .. item.name

    table.insert(lines, line)
    table.insert(line_to_path, {
      path = item.path,
      is_dir = item.is_dir,
      name = item.name,
      depth = depth,
    })

    -- Recursively add children if directory is expanded
    if item.is_dir and is_expanded then
      build_tree(item.path, depth + 1, lines, line_to_path)
    end
  end

  return lines, line_to_path
end

-- Render the tree
local function render()
  if not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local lines, line_to_path = build_tree(state.root, 0)

  -- Store mapping for later use
  state.line_to_path = line_to_path

  -- Add header
  local header = state.root .. "/"
  if not state.show_hidden then
    header = header .. " (󱞞)"
  end
  table.insert(lines, 1, header)

  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)

  -- Restore cursor position if possible
  if state.last_cursor then
    pcall(vim.api.nvim_win_set_cursor, state.win, state.last_cursor)
  end
end

-- Toggle hidden files
local function toggle_hidden()
  state.show_hidden = not state.show_hidden
  render()
end

-- Get item at cursor
local function get_current_item()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  -- Skip header line
  if row <= 1 then
    return nil
  end

  -- Adjust for header offset
  local item_index = row - 1

  if state.line_to_path and state.line_to_path[item_index] then
    return state.line_to_path[item_index]
  end

  return nil
end

-- Toggle directory expansion or open file
local function toggle_or_open()
  local item = get_current_item()
  if not item then
    return
  end

  if item.is_dir then
    -- Toggle expansion
    state.expanded[item.path] = not state.expanded[item.path]
    state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
    render()
  else
    -- Get the previous window
    local prev_win = fn.win_getid(fn.winnr('#'))

    -- If previous window is the explorer, find another window
    if prev_win == state.win or not vim.api.nvim_win_is_valid(prev_win) then
      local wins = vim.api.nvim_list_wins()
      for _, win in ipairs(wins) do
        if win ~= state.win then
          prev_win = win
          break
        end
      end
    end

    -- Open file in target window
    if prev_win and vim.api.nvim_win_is_valid(prev_win) then
      vim.api.nvim_set_current_win(prev_win)
      vim.cmd("edit " .. fn.fnameescape(item.path))
    else
      -- Create new split if no other window exists
      vim.cmd("wincmd l")
      vim.cmd("edit " .. fn.fnameescape(item.path))
    end
  end
end

-- Collapse directory
local function collapse()
  local item = get_current_item()
  if not item then
    return
  end

  if item.is_dir and state.expanded[item.path] then
    -- Collapse current directory
    state.expanded[item.path] = false
    state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
    render()
  else
    -- Jump to parent directory
    local parent = fn.fnamemodify(item.path, ":h")
    if parent ~= item.path then
      -- Find parent in tree and jump to it
      for i, line_item in ipairs(state.line_to_path) do
        if line_item.path == parent then
          vim.api.nvim_win_set_cursor(state.win, { i + 2, 0 })
          break
        end
      end
    end
  end
end

-- Expand all subdirectories of current directory
local function expand_all()
  local item = get_current_item()
  if not item or not item.is_dir then
    return
  end

  local function expand_recursive(path)
    state.expanded[path] = true
    local items = read_dir(path)
    for _, subitem in ipairs(items) do
      if subitem.is_dir then
        expand_recursive(subitem.path)
      end
    end
  end

  expand_recursive(item.path)
  state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
  render()
end

-- Collapse all directories
local function collapse_all()
  state.expanded = {}
  render()
end

-- Create new file
local function create_file()
  local item = get_current_item()
  local base_dir = state.root

  if item then
    base_dir = item.is_dir and item.path or fn.fnamemodify(item.path, ":h")
  end

  local filename = fn.input("New file name: ", base_dir .. "/")
  if filename == "" or filename == base_dir .. "/" then
    return
  end

  -- Create parent directories if needed
  local parent = fn.fnamemodify(filename, ":h")
  fn.mkdir(parent, "p")

  -- Open file in the other window
  local prev_win = fn.win_getid(fn.winnr('#'))
  if prev_win == state.win or not vim.api.nvim_win_is_valid(prev_win) then
    vim.cmd("wincmd l")
  else
    vim.api.nvim_set_current_win(prev_win)
  end

  vim.cmd("edit " .. fn.fnameescape(filename))

  -- Expand parent directory in tree
  state.expanded[parent] = true
  render()
end

-- Create new directory
local function create_dir()
  local item = get_current_item()
  local base_dir = state.root

  if item then
    base_dir = item.is_dir and item.path or fn.fnamemodify(item.path, ":h")
  end

  local dirname = fn.input("New directory name: ", base_dir .. "/")
  if dirname == "" or dirname == base_dir .. "/" then
    return
  end

  fn.mkdir(dirname, "p")

  -- Expand parent directory
  local parent = fn.fnamemodify(dirname, ":h")
  state.expanded[parent] = true
  render()
end

-- Delete file/directory
local function delete_item()
  local item = get_current_item()
  if not item then
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

-- Rename file/directory
local function rename_item()
  local item = get_current_item()
  if not item then
    return
  end

  local new_name = fn.input("Rename to: ", item.name)
  if new_name == "" or new_name == item.name then
    return
  end

  local parent = fn.fnamemodify(item.path, ":h")
  local new_path = parent .. "/" .. new_name
  fn.rename(item.path, new_path)

  -- Update expanded state if it was a directory
  if item.is_dir and state.expanded[item.path] then
    state.expanded[item.path] = nil
    state.expanded[new_path] = true
  end

  render()
end

-- Change root directory
local function change_root()
  local item = get_current_item()
  if not item or not item.is_dir then
    return
  end

  state.root = item.path
  state.expanded = {}
  render()
end

-- Go to parent directory as root
local function root_parent()
  local parent = fn.fnamemodify(state.root, ":h")
  if parent ~= state.root then
    state.root = parent
    state.expanded = {}
    render()
  end
end

-- Set up keymaps
local function setup_keymaps()
  local opts = { buffer = state.buf, silent = true, nowait = true }

  -- Navigation
  vim.keymap.set("n", "<CR>", toggle_or_open, opts)
  vim.keymap.set("n", "l", toggle_or_open, opts)
  vim.keymap.set("n", "h", collapse, opts)
  vim.keymap.set("n", "o", toggle_or_open, opts)

  -- Expand/collapse
  vim.keymap.set("n", "E", expand_all, opts)
  vim.keymap.set("n", "W", collapse_all, opts)

  -- File operations
  vim.keymap.set("n", "%", create_file, opts)
  vim.keymap.set("n", "d", create_dir, opts)
  vim.keymap.set("n", "D", delete_item, opts)
  vim.keymap.set("n", "r", rename_item, opts)

  -- Root operations
  vim.keymap.set("n", "C", change_root, opts)
  vim.keymap.set("n", "u", root_parent, opts)

  -- Toggle hidden files
  vim.keymap.set("n", "H", toggle_hidden, opts)

  -- Refresh and close
  vim.keymap.set("n", "R", render, opts)
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
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
    vim.api.nvim_buf_set_name(state.buf, "FileTree")

    -- Buffer options
    vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(state.buf, "filetype", "filetree")
    vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
    vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
    vim.api.nvim_buf_set_option(state.buf, "buflisted", false)
  end

  -- Set root to current working directory
  if not state.root then
    state.root = fn.getcwd()
  end

  -- Create window
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
  vim.keymap.set("n", "<leader>e", M.toggle, { desc = "Toggle file tree" })

  -- Optional: auto-close on file open
  if opts.auto_close then
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.bo.filetype ~= "filetree" and state.win and vim.api.nvim_win_is_valid(state.win) then
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
