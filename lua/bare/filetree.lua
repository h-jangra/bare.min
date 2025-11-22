--[[
FileTree Keymaps:
l, <CR>   - Open file / expand folder
h         - Collapse folder / go to parent
m         - Toggle select
M         - Clear selection
a         - Create file
A         - Create folder
d         - Delete
r         - Rename
y         - Copy
x         - Cut
p         - Paste
H         - Toggle hidden files
q, <Esc>  - Close tree
]]
local M = {}
local state = {
  expanded = {},
  show_hidden = false,
  clipboard = nil,
  selected = {},
}
local has_icons, icons = pcall(require, "bare.icons")
local folder_icons = {
  expanded  = { icon = " ", color = "#7ebae4" },
  collapsed = { icon = " ", color = "#e4b87e" },
}
local function get_icon(name, is_dir, is_expanded)
  if is_dir then
    local f = is_expanded and folder_icons.expanded or folder_icons.collapsed
    return f.icon
  end
  if has_icons then
    local ext = name:match("^.+%.(.+)$")
    if ext then
      local icon = icons.get_icon(ext)
      if icon and icon ~= "" then
        return icon .. " "
      end
    end
  end
  return "󰈔 "
end
local function read_dir(path)
  local items, handle = {}, vim.loop.fs_scandir(path)
  if not handle then return items end
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if state.show_hidden or name:sub(1, 1) ~= "." then
      table.insert(items, {
        name = name,
        path = path .. "/" .. name,
        is_dir = type == "directory",
      })
    end
  end
  table.sort(items, function(a, b)
    if a.is_dir ~= b.is_dir then return a.is_dir end
    return a.name:lower() < b.name:lower()
  end)
  return items
end

local function build_tree(path, depth, lines, map, extmarks)
  depth, lines, map, extmarks = depth or 0, lines or {}, map or {}, extmarks or {}
  for _, item in ipairs(read_dir(path)) do
    local is_expanded = state.expanded[item.path]
    local is_selected = state.selected[item.path]
    local icon = get_icon(item.name, item.is_dir, is_expanded)
    local prefix = is_selected and "▌ " or "  "
    local line_text = string.rep("  ", depth) .. prefix .. icon .. item.name
    table.insert(lines, line_text)
    table.insert(map, { path = item.path, is_dir = item.is_dir })

    local indent_len = depth * 2
    local prefix_len = #prefix
    local icon_len = #icon

    if item.is_dir then
      table.insert(extmarks, {
        line = #lines - 1,
        col = indent_len + prefix_len,
        end_col = indent_len + prefix_len + icon_len,
        hl = "FileTreeFolder" .. (is_expanded and "Expanded" or "Collapsed")
      })
    elseif has_icons then
      local ext = item.name:match("^.+%.(.+)$")
      if ext then
        local hl = icons.get_hl(ext)
        if hl then
          table.insert(extmarks, {
            line = #lines - 1,
            col = indent_len + prefix_len,
            end_col = indent_len + prefix_len + icon_len,
            hl = hl
          })
        end
      end
    end

    if item.is_dir and is_expanded then
      build_tree(item.path, depth + 1, lines, map, extmarks)
    end
  end
  return lines, map, extmarks
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, "FileTreeFolderExpanded", { fg = folder_icons.expanded.color, bold = true })
  vim.api.nvim_set_hl(0, "FileTreeFolderCollapsed", { fg = folder_icons.collapsed.color, bold = true })
end

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

  setup_highlights()

  local lines, map, extmarks = build_tree(state.root or vim.fn.getcwd(), 0)
  table.insert(lines, 1, "  " .. state.root .. "/" .. (state.show_hidden and "" or " 󱞞"))
  for i = 2, #lines do lines[i] = "  " .. lines[i] end

  for _, extmark in ipairs(extmarks) do
    extmark.line = extmark.line + 1 -- Account for header line
    extmark.col = extmark.col + 2   -- Account for the extra "  " prefix
    extmark.end_col = extmark.end_col + 2
  end

  state.line_to_path = map
  vim.bo[state.buf].modifiable = true

  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)

  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  -- Apply extmarks for highlighting
  local ns = vim.api.nvim_create_namespace("filetree")
  for _, extmark in ipairs(extmarks) do
    vim.api.nvim_buf_set_extmark(
      state.buf,
      ns,
      extmark.line,
      extmark.col,
      {
        end_row = extmark.line,
        end_col = extmark.end_col,
        hl_group = extmark.hl
      }
    )
  end

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

local function toggle_or_open()
  local item = get_item()
  if not item then return end
  if item.is_dir then
    state.expanded[item.path] = not state.expanded[item.path]
    state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
    render()
  else
    local win = vim.api.nvim_get_current_win()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= state.win and vim.api.nvim_win_get_config(w).relative == "" then
        win = w
        break
      end
    end
    vim.api.nvim_set_current_win(win)
    vim.cmd("edit " .. vim.fn.fnameescape(item.path))
  end
end

local function collapse()
  local item = get_item()
  if not item then return end
  if item.is_dir and state.expanded[item.path] then
    state.expanded[item.path] = false
  else
    local parent = vim.fn.fnamemodify(item.path, ":h")
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
  state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
  render()
end

local function prompt(msg, default)
  local result
  vim.ui.input({ prompt = msg .. ": ", default = default }, function(r)
    result = r
  end)
  return result
end

local function toggle_select()
  local item = get_item()
  if not item then return end
  if state.selected[item.path] then
    state.selected[item.path] = nil
  else
    state.selected[item.path] = true
  end
  state.last_cursor = vim.api.nvim_win_get_cursor(state.win)
  render()
end

local function clear_selection()
  state.selected = {}
  render()
end
local function create_file()
  local item = get_item()
  local parent = (item and (item.is_dir and item.path or vim.fn.fnamemodify(item.path, ":h"))) or state.root
  local name = prompt("New file name", "")
  if not name or name == "" then return end
  local path = parent .. "/" .. name
  local f, err = io.open(path, "w")
  if not f then
    vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  f:close()
  state.expanded[parent] = true
  vim.notify("Created: " .. name)
  render()
  vim.schedule(function()
    vim.cmd("wincmd l")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end)
end

local function create_dir()
  local item   = get_item()
  local parent = (item and (item.is_dir and item.path or vim.fn.fnamemodify(item.path, ":h"))) or state.root
  local name   = prompt("New directory name", "")
  if not name or name == "" then return end
  local ok = vim.fn.mkdir(parent .. "/" .. name, "p")
  if ok == 0 then
    vim.notify("Failed to create directory", vim.log.levels.ERROR)
  else
    vim.notify("Created: " .. name)
    state.expanded[parent] = true
    render()
  end
end

local function delete_item()
  local item = get_item()
  if not item then return end
  local selected_count = 0
  for _ in pairs(state.selected) do selected_count = selected_count + 1 end
  local paths = {}
  if selected_count > 0 then
    for p, _ in pairs(state.selected) do
      table.insert(paths, p)
    end
  else
    table.insert(paths, item.path)
  end
  if #paths == 0 then return end
  local label = selected_count > 0
      and ("Delete " .. selected_count .. " items? (y/N)")
      or ("Delete " .. vim.fn.fnamemodify(item.path, ":t") .. "? (y/N)")
  if prompt(label, ""):lower() ~= "y" then return end
  for _, p in ipairs(paths) do
    local res = vim.fn.delete(p, vim.fn.isdirectory(p) == 1 and "rf" or "")
    if res ~= 0 then
      vim.notify("Failed to delete: " .. p, vim.log.levels.ERROR)
    else
      vim.notify("Deleted: " .. vim.fn.fnamemodify(p, ":t"))
    end
  end
  state.selected = {}
  render()
end

local function rename_item()
  local item = get_item()
  if not item then return end
  local old = vim.fn.fnamemodify(item.path, ":t")
  local new = prompt("Rename '" .. old .. "' to", old)
  if not new or new == "" or new == old then return end
  local parent = vim.fn.fnamemodify(item.path, ":h")
  local newp   = parent .. "/" .. new
  if vim.fn.filereadable(newp) == 1 or vim.fn.isdirectory(newp) == 1 then
    vim.notify("Target already exists: " .. new, vim.log.levels.ERROR)
    return
  end
  local ok, err = os.rename(item.path, newp)
  if not ok then
    vim.notify("Rename failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  if item.is_dir and state.expanded[item.path] then
    state.expanded[item.path] = nil
    state.expanded[newp] = true
  end
  vim.notify("Renamed: " .. old .. " → " .. new)
  render()
end

local function copy_item()
  local item = get_item()
  if not item then return end
  local paths = {}
  local count = 0
  for p in pairs(state.selected) do
    paths[#paths + 1] = p
    count = count + 1
  end
  if count > 0 then
    state.clipboard = { paths = paths, move = false }
    vim.notify("Copied " .. count .. " items")
  else
    state.clipboard = { path = item.path, move = false }
    vim.notify("Copied: " .. vim.fn.fnamemodify(item.path, ":t"))
  end
end

local function move_item()
  local item = get_item()
  if not item then return end
  local paths = {}
  local count = 0
  for p in pairs(state.selected) do
    paths[#paths + 1] = p
    count = count + 1
  end
  if count > 0 then
    state.clipboard = { paths = paths, move = true }
    vim.notify("Cut " .. count .. " items")
  else
    state.clipboard = { path = item.path, move = true }
    vim.notify("Cut: " .. vim.fn.fnamemodify(item.path, ":t"))
  end
end

local function copy_recursive(src, dest)
  if vim.fn.isdirectory(src) == 1 then
    vim.fn.mkdir(dest, "p")
    local handle = vim.loop.fs_scandir(src)
    local name = vim.loop.fs_scandir_next(handle)
    while name do
      copy_recursive(src .. "/" .. name, dest .. "/" .. name)
      name = vim.loop.fs_scandir_next(handle)
    end
    return true
  end
  local sf = io.open(src, "rb")
  if not sf then return false end
  local data = sf:read("*a")
  sf:close()
  local df = io.open(dest, "wb")
  if not df then return false end
  df:write(data)
  df:close()
  return true
end
local function paste_item()
  if not state.clipboard then
    vim.notify("Clipboard empty", vim.log.levels.WARN)
    return
  end
  local item = get_item()
  local dest = (item and (item.is_dir and item.path or vim.fn.fnamemodify(item.path, ":h")))
      or state.root
  local sources = state.clipboard.paths or { state.clipboard.path }
  for _, src in ipairs(sources) do
    local name   = vim.fn.fnamemodify(src, ":t")
    local target = dest .. "/" .. name
    if vim.fn.isdirectory(src) == 0 and vim.fn.filereadable(src) == 0 then
      vim.notify("Source missing: " .. name, vim.log.levels.ERROR)
      goto continue
    end
    if target == src then
      vim.notify("Cannot paste to the same location: " .. name, vim.log.levels.WARN)
      goto continue
    end
    if vim.fn.isdirectory(target) == 1 or vim.fn.filereadable(target) == 1 then
      vim.notify("Target exists: " .. name, vim.log.levels.ERROR)
      goto continue
    end
    if state.clipboard.move then
      local ok, err = os.rename(src, target)
      if not ok then
        vim.notify("Move failed: " .. tostring(err), vim.log.levels.ERROR)
      end
    else
      if not copy_recursive(src, target) then
        vim.notify("Copy failed: " .. name, vim.log.levels.ERROR)
      end
    end
    ::continue::
  end
  if state.clipboard.move then
    state.clipboard = nil
  end
  state.selected = {}
  state.expanded[dest] = true
  render()
end

local function setup_buffer()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.buf, "FileTree")
  local bo      = vim.bo[state.buf]
  bo.bufhidden  = "wipe"
  bo.filetype   = "filetree"
  bo.buftype    = "nofile"
  bo.swapfile   = false
  bo.modifiable = false
  bo.buflisted  = false
  local opts    = { buffer = state.buf, silent = true, nowait = true }
  local maps    = {
    { "<CR>", toggle_or_open },
    { "l",    toggle_or_open },
    { "h",    collapse },
    { "H", function()
      state.show_hidden = not state.show_hidden; render()
    end },
    { "q",     M.close },
    { "<Esc>", M.close },
    { "a",     create_file },
    { "A",     create_dir },
    { "m",     toggle_select },
    { "M",     clear_selection },
    { "d",     delete_item },
    { "r",     rename_item },
    { "y",     copy_item },
    { "x",     move_item },
    { "p",     paste_item },
    { "R",     render },
  }
  for _, m in ipairs(maps) do
    vim.keymap.set("n", m[1], m[2], opts)
  end
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return
  end
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    setup_buffer()
  end
  state.root = state.root or vim.fn.getcwd()
  vim.cmd("topleft 35vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  local wo = vim.wo[state.win]
  wo.wrap = false
  wo.cursorline = true
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.foldcolumn = "0"
  wo.spell = false
  render()
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    if #vim.api.nvim_list_wins() > 1 then
      vim.api.nvim_win_close(state.win, true)
    end
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
  vim.keymap.set("n", "<leader>e", M.toggle, { desc = "Open file tree" })
  setup_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      setup_highlights()
      if state.buf and vim.api.nvim_buf_is_valid(state.buf) then render() end
    end
  })
  vim.api.nvim_create_user_command("FileTree", function()
    M.toggle()
  end, {})
  if opts.auto_close then
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.bo.filetype ~= "filetree"
            and state.win
            and vim.api.nvim_win_is_valid(state.win)
            and #vim.api.nvim_list_wins() > 1 then
          M.close()
        end
      end
    })
  end
end

return M
