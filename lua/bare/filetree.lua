local M = {}
local fn = vim.fn

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

local function read_dir(path)
  local items, handle = {}, vim.loop.fs_scandir(path)
  if not handle then return items end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if state.show_hidden or name:sub(1, 1) ~= "." then
      table.insert(items, { name = name, path = path .. "/" .. name, is_dir = type == "directory" })
    end
  end
  table.sort(items, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end
    return tostring(a.name):lower() < tostring(b.name):lower()
  end)
  return items
end

local function build_tree(path, depth, lines, map)
  depth, lines, map = depth or 0, lines or {}, map or {}
  local indent = string.rep("  ", depth)

  for _, item in ipairs(read_dir(path)) do
    local is_expanded = state.expanded[item.path]
    table.insert(lines, indent .. get_icon(item.name, item.is_dir, is_expanded) .. item.name)
    table.insert(map, { path = item.path, is_dir = item.is_dir })
    if item.is_dir and is_expanded then
      build_tree(item.path, depth + 1, lines, map)
    end
  end
  return lines, map
end

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

  local lines, map = build_tree(state.root, 0)
  local header = "  " .. state.root .. "/" .. (state.show_hidden and "" or " (󱞞)")
  table.insert(lines, 1, header)
  for i = 2, #lines do lines[i] = "  " .. lines[i] end

  state.line_to_path = map
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_set_cursor, state.win, state.last_cursor or { 2, 0 })
  end
end

local function get_item()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then return end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  return row > 1 and state.line_to_path[row - 1]
end

local function find_win()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if w ~= state.win and vim.api.nvim_win_get_config(w).relative == "" then
      return w
    end
  end
end

local function open_file(path)
  local win = find_win()
  if win then
    vim.api.nvim_set_current_win(win)
  else
    vim.cmd("wincmd l")
    if vim.api.nvim_get_current_win() == state.win then vim.cmd("vsplit") end
  end
  vim.cmd("edit " .. fn.fnameescape(path))
end

local function toggle_or_open()
  local item = get_item()
  if not item then return end

  if item.is_dir then
    state.expanded[item.path] = not state.expanded[item.path]
    state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
    render()
  else
    open_file(item.path)
  end
end

local function collapse()
  local item = get_item()
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
            vim.api.nvim_win_set_cursor(state.win, { i + 1, 0 })
          end
          break
        end
      end
    end
  end

  state.last_cursor = state.win and vim.api.nvim_win_is_valid(state.win) and vim.api.nvim_win_get_cursor(state.win)
  render()
end

local function refresh()
  state.last_cursor = state.win and vim.api.nvim_win_is_valid(state.win) and vim.api.nvim_win_get_cursor(state.win)
  render()
end

local function prompt(msg, default)
  local result
  vim.ui.input({ prompt = msg .. ": ", default = default or "" }, function(r) result = r end)
  return result
end

local function create_file()
  local item = get_item()
  local parent = (item and (item.is_dir and item.path or fn.fnamemodify(item.path, ":h"))) or state.root
  local name = prompt("New file name")
  if not name or name == "" then return end

  local path = parent .. "/" .. name
  local ok, err = io.open(path, "w")
  if not ok then
    vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  ok:close()
  vim.notify("Created: " .. name)
  open_file(path)
  M.close()
  state.expanded[parent] = true
  refresh()
end

local function create_dir()
  local item = get_item()
  local parent = (item and (item.is_dir and item.path or fn.fnamemodify(item.path, ":h"))) or state.root
  local name = prompt("New directory name")
  if not name or name == "" then return end

  if vim.fn.mkdir(parent .. "/" .. name, "p") == 0 then
    vim.notify("Failed to create directory", vim.log.levels.ERROR)
  else
    vim.notify("Created: " .. name)
    state.expanded[parent] = true
    refresh()
  end
end

local function delete_item()
  local item = get_item()
  if not item then return end

  local name = fn.fnamemodify(item.path, ":t")
  if prompt("Delete " .. name .. "? (y/N)"):lower() ~= "y" then return end

  if vim.fn.delete(item.path, item.is_dir and "rf" or "") ~= 0 then
    vim.notify("Failed to delete", vim.log.levels.ERROR)
  else
    vim.notify("Deleted: " .. name)
    refresh()
  end
end

local function rename_item()
  local item = get_item()
  if not item then return end

  local old = fn.fnamemodify(item.path, ":t")
  local new = prompt("Rename '" .. old .. "' to", old)
  if not new or new == "" or new == old then return end

  local parent = fn.fnamemodify(item.path, ":h")
  local new_path = parent .. "/" .. new

  if vim.fn.filereadable(new_path) == 1 or vim.fn.isdirectory(new_path) == 1 then
    vim.notify("Target already exists: " .. new, vim.log.levels.ERROR)
    return
  end

  local ok, err = os.rename(item.path, new_path)
  if not ok then
    vim.notify("Rename failed: " .. tostring(err), vim.log.levels.ERROR)
  else
    if item.is_dir and state.expanded[item.path] then
      state.expanded[item.path] = nil
      state.expanded[new_path] = true
    end
    vim.notify("Renamed: " .. old .. " → " .. new)
    refresh()
  end
end

local function copy_item()
  local item = get_item()
  if not item then return end
  state.clipboard = { path = item.path, move = false, is_dir = item.is_dir }
  vim.notify("Copied: " .. fn.fnamemodify(item.path, ":t"))
end

local function move_item()
  local item = get_item()
  if not item then return end
  state.clipboard = { path = item.path, move = true, is_dir = item.is_dir }
  vim.notify("Cut: " .. fn.fnamemodify(item.path, ":t"))
end

local function paste_item()
  if not state.clipboard then
    vim.notify("Clipboard empty", vim.log.levels.WARN)
    return
  end

  local item = get_item()
  local dest = (item and (item.is_dir and item.path or fn.fnamemodify(item.path, ":h"))) or state.root
  local src = state.clipboard.path
  local filename = fn.fnamemodify(src, ":t")
  local target = dest .. "/" .. filename

  if vim.fn.filereadable(src) == 0 and vim.fn.isdirectory(src) == 0 then
    vim.notify("Source no longer exists", vim.log.levels.ERROR)
    state.clipboard = nil
    return
  end

  if target == src then
    vim.notify("Cannot paste to same location", vim.log.levels.WARN)
    return
  end

  if vim.fn.filereadable(target) == 1 or vim.fn.isdirectory(target) == 1 then
    vim.notify("Target already exists: " .. filename, vim.log.levels.ERROR)
    return
  end

  if state.clipboard.move then
    local ok, err = os.rename(src, target)
    if not ok then
      vim.notify("Move failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    vim.notify("Moved: " .. filename)
    state.clipboard = nil
  else
    if state.clipboard.is_dir then
    else
      -- Netrw setup with icons
      local sf = io.open(src, "rb")
      if not sf then
        vim.notify("Cannot read source file", vim.log.levels.ERROR)
        return
      end
      local data = sf:read("*a")
      sf:close()

      local df = io.open(target, "wb")
      if not df then
        vim.notify("Cannot write to destination", vim.log.levels.ERROR)
        return
      end
      df:write(data)
      df:close()
    end
    vim.notify("Copied: " .. filename)
  end

  state.expanded[dest] = true
  refresh()
end

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

    local opts = { buffer = state.buf, silent = true, nowait = true }
    vim.keymap.set("n", "<CR>", toggle_or_open, opts)
    vim.keymap.set("n", "l", toggle_or_open, opts)
    vim.keymap.set("n", "h", collapse, opts)
    vim.keymap.set("n", "H", function()
      state.show_hidden = not state.show_hidden; render()
    end, opts)
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
    local win_count = #vim.tbl_filter(function(w)
      return vim.api.nvim_win_get_config(w).relative == ""
    end, vim.api.nvim_list_wins())

    if win_count > 1 then
      vim.api.nvim_win_close(state.win, true)
      state.win = nil
      state.last_cursor = nil
    end
  end
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then M.close() else M.open() end
end

function M.setup(opts)
  opts = opts or {}
  vim.keymap.set("n", "<leader>e", M.toggle, { desc = "Toggle file tree" })

  if opts.auto_close then
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.bo.filetype ~= "filetree" and state.win and vim.api.nvim_win_is_valid(state.win) then
          if #vim.api.nvim_list_wins() > 1 then M.close() end
        end
      end,
    })
  end
end

return M
