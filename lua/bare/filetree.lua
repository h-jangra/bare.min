local M = {}
local fn = vim.fn

-- State
local state = {
  buf = nil,
  win = nil,
  root = nil,
  show_hidden = false,
  expanded = {},
  line_to_path = {},
  last_cursor = nil,
  clipboard = nil,
}

local has_icons, icons = pcall(require, "bare.icons")

-- Utilities
local function get_icon(name, is_dir, is_expanded)
  if is_dir then return is_expanded and "📂 " or "📁 " end
  if has_icons then
    local ext = name:match("^.+%.(.+)$")
    if ext then
      local icon = icons.get(ext)
      if icon then return icon .. " " end
    end
  end
  return "📄 "
end

local function is_hidden(name)
  return name:sub(1, 1) == "."
end

local function read_dir(path)
  local items, handle = {}, vim.loop.fs_scandir(path)
  if not handle then return items end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if state.show_hidden or not is_hidden(name) then
      table.insert(items, { name = name, path = path .. "/" .. name, is_dir = type == "directory" })
    end
  end

  table.sort(items, function(a, b)
    if a.is_dir ~= b.is_dir then return a.is_dir end
    return a.name:lower() < b.name:lower()
  end)
  return items
end

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
    table.insert(line_to_path, { path = item.path, is_dir = item.is_dir })
    if item.is_dir and is_expanded then
      build_tree(item.path, depth + 1, lines, line_to_path)
    end
  end
  return lines, line_to_path
end

local PADDING = "  "

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

  local lines, line_to_path = build_tree(state.root, 0)
  local header = state.root .. "/"
  if not state.show_hidden then header = header .. " (󱞞)" end
  table.insert(lines, 1, PADDING .. header)
  for i = 2, #lines do lines[i] = PADDING .. lines[i] end

  state.line_to_path = line_to_path

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    if state.last_cursor then
      pcall(vim.api.nvim_win_set_cursor, state.win, state.last_cursor)
    else
      pcall(vim.api.nvim_win_set_cursor, state.win, {2, 0})
    end
  end
end

local function get_current_item()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then return nil end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  if row <= 1 then return nil end
  return state.line_to_path[row - 1]
end

local function toggle_or_open()
  local item = get_current_item()
  if not item then return end

  if item.is_dir then
    state.expanded[item.path] = not state.expanded[item.path]
    state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
    render()
  else
    -- Open file in another window if possible
    local prev_win = nil
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= state.win and vim.api.nvim_win_get_config(w).relative == "" then
        prev_win = w
        break
      end
    end

    if prev_win then
      vim.api.nvim_set_current_win(prev_win)
      vim.cmd("edit " .. fn.fnameescape(item.path))
    else
      vim.cmd("wincmd l")
      if vim.api.nvim_get_current_win() == state.win then
        vim.cmd("vsplit")
      end
      vim.cmd("edit " .. fn.fnameescape(item.path))
    end
  end
end

local function collapse()
  local item = get_current_item()
  if not item then return end
  
  if item.is_dir and state.expanded[item.path] then
    state.expanded[item.path] = false
  else
    local parent = fn.fnamemodify(item.path, ":h")
    if parent ~= item.path and parent ~= state.root then
      state.expanded[parent] = false
      for i, v in ipairs(state.line_to_path) do
        if v.path == parent then
          if state.win and vim.api.nvim_win_is_valid(state.win) then
            vim.api.nvim_win_set_cursor(state.win, {i + 1, 0})
          end
          break
        end
      end
    end
  end
  
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
  end
  render()
end

local function toggle_hidden()
  state.show_hidden = not state.show_hidden
  render()
end

-- ======= Async input prompt =======
local function prompt_input(prompt, callback)
  vim.ui.input({ prompt = prompt .. ": " }, function(input)
    if input and input ~= "" then
      callback(input)
    end
  end)
end

local function refresh()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
  end
  render()
end

-- ======= File operations =======
local function create_file()
  local item = get_current_item()
  local parent_dir = item and (item.is_dir and item.path or fn.fnamemodify(item.path, ":h")) or state.root

  prompt_input("New file name", function(name)
    local path = parent_dir .. "/" .. name
    local ok, err = io.open(path, "w")
    if ok then ok:close() vim.notify("Created: " .. name)
    else vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR) end

    state.expanded[parent_dir] = true
    refresh()
  end)
end

local function create_dir()
  local item = get_current_item()
  local parent_dir = item and (item.is_dir and item.path or fn.fnamemodify(item.path, ":h")) or state.root

  prompt_input("New directory name", function(name)
    local path = parent_dir .. "/" .. name
    local ok = vim.fn.mkdir(path, "p")
    if ok == 0 then vim.notify("Failed to create directory", vim.log.levels.ERROR)
    else vim.notify("Created: " .. name) end

    state.expanded[parent_dir] = true
    refresh()
  end)
end

local function delete_item()
  local item = get_current_item()
  if not item then return end

  local name = fn.fnamemodify(item.path, ":t")
  prompt_input("Delete " .. name .. "? (y/N)", function(confirm)
    if confirm:lower() ~= "y" then return end
    local ok = vim.fn.delete(item.path, item.is_dir and "rf" or "")
    if ok ~= 0 then vim.notify("Failed to delete", vim.log.levels.ERROR)
    else vim.notify("Deleted: " .. name) end
    refresh()
  end)
end

local function rename_item()
  local item = get_current_item()
  if not item then return end

  local old_name = fn.fnamemodify(item.path, ":t")
  prompt_input("Rename '" .. old_name .. "' to", function(newname)
    local newpath = fn.fnamemodify(item.path, ":h") .. "/" .. newname
    local ok = os.rename(item.path, newpath)
    if not ok then vim.notify("Rename failed", vim.log.levels.ERROR)
    else vim.notify("Renamed: " .. old_name .. " → " .. newname) end
    refresh()
  end)
end

local function copy_item()
  local item = get_current_item()
  if not item then return end
  state.clipboard = { path = item.path, move = false, is_dir = item.is_dir }
  vim.notify("Copied: " .. fn.fnamemodify(item.path, ":t"))
end

local function move_item()
  local item = get_current_item()
  if not item then return end
  state.clipboard = { path = item.path, move = true, is_dir = item.is_dir }
  vim.notify("Cut: " .. fn.fnamemodify(item.path, ":t"))
end

local function paste_item()
  if not state.clipboard then
    vim.notify("Clipboard empty", vim.log.levels.WARN)
    return
  end

  local item = get_current_item()
  local dest = item and (item.is_dir and item.path or fn.fnamemodify(item.path, ":h")) or state.root

  local src = state.clipboard.path
  local filename = fn.fnamemodify(src, ":t")
  local target = dest .. "/" .. filename

  if target == src then
    vim.notify("Cannot paste to same location", vim.log.levels.WARN)
    return
  end

  if state.clipboard.move then
    local ok = os.rename(src, target)
    if not ok then vim.notify("Move failed", vim.log.levels.ERROR) return end
    vim.notify("Moved: " .. filename)
  else
    if state.clipboard.is_dir then
      vim.fn.system({ "cp", "-r", src, target })
      if vim.v.shell_error ~= 0 then vim.notify("Copy failed", vim.log.levels.ERROR) return end
    else
      local function copy_file(s, d)
        local sf = io.open(s, "rb")
        if not sf then return false end
        local data = sf:read("*a")
        sf:close()
        local df = io.open(d, "wb")
        if not df then return false end
        df:write(data)
        df:close()
        return true
      end
      if not copy_file(src, target) then vim.notify("Copy failed", vim.log.levels.ERROR) return end
    end
    vim.notify("Copied: " .. filename)
  end

  state.clipboard = nil
  state.expanded[dest] = true
  refresh()
end

-- Keymaps
local function setup_keymaps()
  local opts = { buffer = state.buf, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>", toggle_or_open, opts)
  vim.keymap.set("n", "l", toggle_or_open, opts)
  vim.keymap.set("n", "h", collapse, opts)
  vim.keymap.set("n", "H", toggle_hidden, opts)
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)

  vim.keymap.set("n", "a", create_file, opts)
  vim.keymap.set("n", "A", create_dir, opts)
  vim.keymap.set("n", "d", delete_item, opts)
  vim.keymap.set("n", "r", rename_item, opts)
  vim.keymap.set("n", "y", copy_item, opts)
  vim.keymap.set("n", "x", move_item, opts)
  vim.keymap.set("n", "p", paste_item, opts)
  vim.keymap.set("n", "R", refresh, opts)
end

-- Open explorer
function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return
  end

  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(state.buf, "FileTree")
    vim.bo[state.buf].bufhidden = "wipe"
    vim.bo[state.buf].filetype = "filetree"
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].swapfile = false
    vim.bo[state.buf].modifiable = false
    vim.bo[state.buf].buflisted = false
    
    setup_keymaps()
  end

  state.root = state.root or fn.getcwd()
  vim.cmd("topleft 35vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)

  vim.wo[state.win].wrap = false
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].foldcolumn = "0"
  vim.wo[state.win].spell = false

  render()
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
    state.last_cursor = nil
  end
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

function M.setup(opts)
  opts = opts or {}
  vim.keymap.set("n", "<leader>e", M.toggle, { desc = "Toggle file tree" })
  
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
