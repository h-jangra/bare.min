--[[
FileTree Keymaps:
l, <CR>   - Open / expand
s / v / t - Open in split / vsplit / tab
h         - Collapse / go to parent
-         - Go to parent directory as root
C         - Set highlighted directory as root
m         - Toggle select
M         - Clear selection
a         - New file (supports nested paths e.g. dir/file.lua)
A         - New folder
d         - Delete
r         - Rename
y         - Copy file
x         - Cut file
p         - Paste file
Y         - Copy relative path to clipboard
gy        - Copy absolute path to clipboard
H         - Toggle hidden files
q, <Esc>  - Close
R         - Refresh
?         - Show Help Window
]]
local M = {}
local state = {
  expanded = {},
  show_hidden = false,
  clipboard = nil,
  selected = {},
  git = {},
  width = 30,
}
local MIN_WIDTH = 20
local has_icons, icons = pcall(require, "bare.icons")
local folder_icons = {
  expanded  = { icon = "󰉋 ", color = "#7ebae4" },
  collapsed = { icon = "󰉓 ", color = "#e4b87e" },
}

local function get_icon(name, is_dir, is_expanded)
  if is_dir then
    local icon = (is_expanded and folder_icons.expanded or folder_icons.collapsed).icon
    local hl = "FileTreeFolder" .. (is_expanded and "Expanded" or "Collapsed")
    return icon, hl
  end
  if has_icons then
    local ft = vim.filetype.match({ filename = name }) or name:match("%.([^.]+)$")
    local icon, hl = icons.get(ft)
    if icon and icon ~= "" then return icon .. " ", hl end
  end
  return "󰈤 ", "FileIconDefault"
end

local function read_dir(path, cache)
  if cache and cache[path] then return cache[path] end
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
    if a.is_dir ~= b.is_dir then return a.is_dir end
    return a.name:lower() < b.name:lower()
  end)
  if cache then cache[path] = items end
  return items
end

local function build_tree(path, depth, lines, map, extmarks, cache, is_last_table)
  depth = depth or 0
  lines = lines or {}
  map = map or {}
  extmarks = extmarks or {}
  cache = cache or {}
  is_last_table = is_last_table or {}

  local items = read_dir(path, cache)
  local total_items = #items

  for idx, item in ipairs(items) do
    local is_last = (idx == total_items)
    is_last_table[depth + 1] = is_last

    local indent_str = ""
    local guide_cols = {}
    for d = 1, depth do
      local current_col = #indent_str
      if is_last_table[d] then
        indent_str = indent_str .. "  "
      else
        indent_str = indent_str .. "│ "
        table.insert(guide_cols, current_col)
      end
    end

    local is_expanded = state.expanded[item.path]
    local is_selected = state.selected[item.path]
    local icon, icon_hl = get_icon(item.name, item.is_dir, is_expanded)
    local prefix = is_selected and "▌" or ""

    local git = state.git[item.path]
    local git_hl = nil
    if git then
      if git:match("M") or git:match("R") then
        git_hl = "FileTreeGitModified"
      elseif git:match("A") then
        git_hl = "FileTreeGitAdded"
      elseif git:match("%?%?") or git:match("U") then
        git_hl = "FileTreeGitUntracked"
      elseif git:match("D") then
        git_hl = "FileTreeGitDeleted"
      end
    end

    local display_name = item.name
    local full_parts = { item.name }
    if item.is_dir then
      local current = item
      while true do
        local children = read_dir(current.path, cache)
        if #children == 1 and children[1].is_dir then
          current = children[1]
          table.insert(full_parts, current.name)
        else
          break
        end
      end
      if #full_parts > 1 then display_name = table.concat(full_parts, "/") end
    end

    -- 1 space padding on left margin so items don't stick to the left side
    local left_pad = " "
    local line_text = left_pad .. indent_str .. prefix .. icon .. display_name
    table.insert(lines, line_text)
    table.insert(map, {
      path = item.path,
      is_dir = item.is_dir,
      display_name = display_name,
      parts = full_parts
    })

    local line_idx = #lines - 1
    local pad_bytes = #left_pad

    -- Tree guide lines extmarks
    for _, g_col in ipairs(guide_cols) do
      table.insert(extmarks, {
        line = line_idx,
        col = pad_bytes + g_col,
        end_col = pad_bytes + g_col + 3, -- 3 bytes for UTF-8 '│'
        hl = "FileTreeIndentGuide"
      })
    end

    -- Selection prefix highlight
    if is_selected then
      local p_col = pad_bytes + #indent_str
      table.insert(extmarks, {
        line = line_idx,
        col = p_col,
        end_col = p_col + #prefix,
        hl = "FileTreeSelected"
      })
    end

    -- Icon extmark
    local icon_col = pad_bytes + #indent_str + #prefix
    table.insert(extmarks, {
      line = line_idx,
      col = icon_col,
      end_col = icon_col + #icon,
      hl = git_hl or icon_hl
    })

    -- Text extmark: Zed editor style coloring based on git status
    local text_col = icon_col + #icon
    local text_hl = git_hl or (item.name:sub(1, 1) == "." and "FileTreeHidden" or nil)
    if text_hl then
      table.insert(extmarks, {
        line = line_idx,
        col = text_col,
        end_col = text_col + #display_name,
        hl = text_hl
      })
    end

    local next_path = item.path
    if item.is_dir then
      local current = item
      while true do
        local children = read_dir(current.path, cache)
        if #children == 1 and children[1].is_dir then current = children[1] else break end
      end
      next_path = current.path
    end

    if item.is_dir and is_expanded then
      build_tree(next_path, depth + 1, lines, map, extmarks, cache, is_last_table)
    end
  end
  return lines, map, extmarks
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, "FileTreeRoot", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "FileTreeIndentGuide", { fg = "#3b4261" })
  vim.api.nvim_set_hl(0, "FileTreeFolderExpanded", { fg = folder_icons.expanded.color, bold = true })
  vim.api.nvim_set_hl(0, "FileTreeFolderCollapsed", { fg = folder_icons.collapsed.color, bold = true })
  vim.api.nvim_set_hl(0, "FileTreeGitModified", { fg = "#e0af68", bold = true })
  vim.api.nvim_set_hl(0, "FileTreeGitAdded", { fg = "#9ece6a", bold = true })
  vim.api.nvim_set_hl(0, "FileTreeGitUntracked", { fg = "#7dcfff", bold = true })
  vim.api.nvim_set_hl(0, "FileTreeGitDeleted", { fg = "#f7768e", bold = true })
  vim.api.nvim_set_hl(0, "FileTreeHidden", { fg = "#565f89", italic = true })
  vim.api.nvim_set_hl(0, "FileTreeSelected", { fg = "#bb9af7", bold = true })
end

local function get_item()
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then return end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  return row > 1 and state.line_to_path[row - 1]
end

local function update_git_status(cb)
  local root = state.root or vim.fn.getcwd()
  if vim.fn.isdirectory(root .. "/.git") == 0 then
    state.git = {}
    if cb then cb() end
    return
  end
  vim.system({ "git", "-C", root, "status", "--porcelain" }, { text = true }, function(obj)
    local git = {}
    if obj.code == 0 and obj.stdout then
      for line in obj.stdout:gmatch("[^\r\n]+") do
        local status = line:sub(1, 2)
        local file = line:sub(4)
        if file:sub(1, 1) == '"' and file:sub(-1) == '"' then
          file = file:sub(2, -2)
        end
        local full_path = root .. "/" .. file
        git[full_path] = status

        local parent = vim.fn.fnamemodify(full_path, ":h")
        while parent and #parent >= #root and parent ~= root do
          if not git[parent] then
            git[parent] = status
          end
          parent = vim.fn.fnamemodify(parent, ":h")
        end
      end
    end
    vim.schedule(function()
      state.git = git
      if cb then cb() end
    end)
  end)
end

local function render(update_git)
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then return end
  setup_highlights()

  local current_path = nil
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local item = get_item()
    if item then current_path = item.path end
  end

  local cache = {}
  local lines, map, extmarks = build_tree(state.root or vim.fn.getcwd(), 0, nil, nil, nil, cache, {})
  local root_text = " 󰉋 " .. vim.fn.fnamemodify(state.root or vim.fn.getcwd(), ":~") .. "/"
  table.insert(lines, 1, root_text)

  state.line_to_path = map
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("filetree")
  vim.api.nvim_buf_set_extmark(state.buf, ns, 0, 0, {
    end_row = 0,
    end_col = #root_text,
    hl_group = "FileTreeRoot"
  })

  for _, m in ipairs(extmarks) do
    if m.hl then
      vim.api.nvim_buf_set_extmark(state.buf, ns, m.line + 1, m.col, {
        end_row = m.line + 1,
        end_col = m.end_col,
        hl_group = m.hl
      })
    end
  end

  vim.bo[state.buf].modifiable = false
  if current_path and state.win and vim.api.nvim_win_is_valid(state.win) then
    for i, item in ipairs(state.line_to_path) do
      if item.path == current_path then
        vim.api.nvim_win_set_cursor(state.win, { i + 1, 0 }); break
      end
    end
  end

  if update_git then
    update_git_status(function()
      if state.buf and vim.api.nvim_buf_is_valid(state.buf) then render(false) end
    end)
  end
end

local function open_file(split_cmd)
  local item = get_item()
  if not item then return end
  if item.is_dir then
    state.expanded[item.path] = not state.expanded[item.path]
    render(true)
  else
    local target_win = nil
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= state.win and vim.api.nvim_win_get_config(w).relative == "" then
        target_win = w; break
      end
    end
    if not target_win then
      vim.cmd("wincmd v")
      target_win = vim.api.nvim_get_current_win()
    else
      vim.api.nvim_set_current_win(target_win)
    end
    if split_cmd then vim.cmd(split_cmd) end
    vim.cmd("edit " .. vim.fn.fnameescape(item.path))
  end
end

local function collapse()
  local item = get_item()
  if not item then return end
  if item.is_dir and state.expanded[item.path] then
    state.expanded[item.path] = false; render(true)
  else
    local curr, root = item.path, state.root or vim.fn.getcwd()
    while curr ~= root do
      local parent = vim.fn.fnamemodify(curr, ":h")
      if parent == curr then break end
      if state.expanded[parent] then
        state.expanded[parent] = false; render(true)
        for i, v in ipairs(state.line_to_path) do
          if v.path == parent then
            vim.api.nvim_win_set_cursor(state.win, { i + 1, 0 }); break
          end
        end
        return
      end
      curr = parent
    end
  end
end

local function toggle_select()
  local item = get_item()
  if not item then return end
  state.selected[item.path] = not state.selected[item.path] or nil
  render(false)
end

local function clear_selection()
  state.selected = {}
  render(false)
end

local function cd_up()
  state.root = vim.fn.fnamemodify(state.root or vim.fn.getcwd(), ":h")
  render(true)
end

local function cd_node()
  local item = get_item()
  if item and item.is_dir then
    state.root = item.path
    render(true)
  end
end

local function copy_path(rel)
  local item = get_item()
  if not item then return end
  local p = rel and vim.fn.fnamemodify(item.path, ":.") or item.path
  vim.fn.setreg("+", p)
  vim.notify("Copied path: " .. p)
end

local function show_help()
  local help_lines = {
    " ------------------------------------------ ",
    "             FileTree Keymaps               ",
    " ------------------------------------------ ",
    "  <CR>, l  : Open file / Expand folder",
    "  s / v / t: Open in Split / VSplit / Tab",
    "  h        : Collapse folder / Parent",
    "  - / C    : Up to parent / Set root",
    "  a / A    : New File / Folder",
    "  d / r    : Delete / Rename",
    "  y / x / p: Copy / Cut / Paste",
    "  Y / gy   : Copy Relative / Absolute Path",
    "  m / M    : Select item / Clear selection",
    "  H        : Toggle Hidden files",
    "  R        : Refresh tree",
    "  q, <Esc> : Close FileTree",
    "  ?        : Show this Help Window",
    " ------------------------------------------ ",
  }
  local ui = require("bare.ui")
  local buf, win = ui.float({
    width = 46,
    height = #help_lines,
    border = "rounded",
    title = " Help ",
  })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set("n", "?", function() vim.api.nvim_win_close(win, true) end, opts)
end

local function create_file()
  local item = get_item()
  local parent = (item and (item.is_dir and item.path or vim.fn.fnamemodify(item.path, ":h"))) or
  (state.root or vim.fn.getcwd())
  vim.ui.input({ prompt = "New file: " }, function(name)
    if not name or name == "" then return end
    local path = parent .. "/" .. name
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local f = io.open(path, "w")
    if f then f:close() end
    state.expanded[parent] = true; render(true)
    vim.schedule(function() open_file() end)
  end)
end

local function create_dir()
  local item = get_item()
  local parent = (item and (item.is_dir and item.path or vim.fn.fnamemodify(item.path, ":h"))) or
  (state.root or vim.fn.getcwd())
  vim.ui.input({ prompt = "New directory: " }, function(name)
    if not (name and name ~= "") then return end
    vim.fn.mkdir(parent .. "/" .. name, "p")
    state.expanded[parent] = true; render(true)
  end)
end

local function delete_item()
  local item = get_item()
  if not item then return end
  local paths = {}
  for p in pairs(state.selected) do table.insert(paths, p) end
  if #paths == 0 then table.insert(paths, item.path) end

  vim.ui.input({ prompt = "Delete " .. #paths .. " items? (y/N): " }, function(confirm)
    if confirm and confirm:lower() == "y" then
      for _, p in ipairs(paths) do
        vim.fn.delete(p, vim.fn.isdirectory(p) == 1 and "rf" or "")
      end
      state.selected = {}
      render(true)
    end
  end)
end

local function rename_item()
  local item = get_item()
  if not (item and state.win and vim.api.nvim_win_is_valid(state.win)) then return end
  local line, col = vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(state.win)[2]
  local start_idx = line:find(item.display_name, 1, true)
  if not start_idx then return end
  start_idx = start_idx - 1

  if item.parts and #item.parts > 1 then
    local current_offset, target_part_idx = start_idx, 1
    for i, part in ipairs(item.parts) do
      local part_end = current_offset + #part
      if col >= current_offset and col <= part_end then
        target_part_idx = i; break
      end
      current_offset = part_end + 1
    end
    local current_p = item.path
    for i = 2, target_part_idx do
      local children = read_dir(current_p)
      if #children == 1 then current_p = children[1].path end
    end
    local old_name = item.parts[target_part_idx]
    vim.ui.input({ prompt = "Rename '" .. old_name .. "' to: ", default = old_name }, function(new_name)
      if not (new_name and new_name ~= "" and new_name ~= old_name) then return end
      local new_full = vim.fn.fnamemodify(current_p, ":h") .. "/" .. new_name
      if os.rename(current_p, new_full) then
        if state.expanded[current_p] then
          state.expanded[current_p] = nil; state.expanded[new_full] = true
        end
        render(true)
      end
    end)
  else
    local old = item.parts and item.parts[1] or vim.fn.fnamemodify(item.path, ":t")
    vim.ui.input({ prompt = "Rename: ", default = old }, function(new)
      if new and new ~= "" and new ~= old then
        local new_full = vim.fn.fnamemodify(item.path, ":h") .. "/" .. new
        if os.rename(item.path, new_full) then
          if state.expanded[item.path] then
            state.expanded[item.path] = nil; state.expanded[new_full] = true
          end
          render(true)
        end
      end
    end)
  end
end

local function copy_recursive(src, dest)
  if vim.fn.isdirectory(src) == 1 then
    vim.fn.mkdir(dest, "p")
    for _, item in ipairs(read_dir(src)) do
      copy_recursive(item.path, dest .. "/" .. item.name)
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

local function copy_item(move)
  local item = get_item()
  if not item then return end
  local paths = {}
  for p in pairs(state.selected) do table.insert(paths, p) end
  if #paths == 0 then table.insert(paths, item.path) end
  state.clipboard = { paths = paths, move = move }
  vim.notify((move and "Cut " or "Copied ") .. #paths .. " items")
end

local function paste_item()
  if not state.clipboard then return end
  local item = get_item()
  local dest = (item and (item.is_dir and item.path or vim.fn.fnamemodify(item.path, ":h"))) or
  (state.root or vim.fn.getcwd())
  for _, src in ipairs(state.clipboard.paths) do
    local target = dest .. "/" .. vim.fn.fnamemodify(src, ":t")
    if state.clipboard.move then
      os.rename(src, target)
    else
      copy_recursive(src, target)
    end
  end
  if state.clipboard.move then state.clipboard = nil end
  state.selected = {}
  render(true)
end

local function setup_buffer()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.buf, "FileTree")
  local bo = vim.bo[state.buf]
  bo.bufhidden, bo.filetype, bo.buftype, bo.swapfile, bo.buflisted = "wipe", "filetree", "nofile", false, false
  local opts = { buffer = state.buf, silent = true, nowait = true }
  local maps = {
    { "<CR>", function() open_file() end },
    { "l",    function() open_file() end },
    { "s",    function() open_file("split") end },
    { "v",    function() open_file("vsplit") end },
    { "t",    function() open_file("tabnew") end },
    { "h",    collapse },
    { "-",    cd_up },
    { "C",    cd_node },
    { "H",    function()
      state.show_hidden = not state.show_hidden; render(true)
    end },
    { "q",    M.close }, { "<Esc>", M.close },
    { "a", create_file }, { "A", create_dir },
    { "d", delete_item }, { "r", rename_item }, { "R", function() render(true) end },
    { "m", toggle_select }, { "M", clear_selection },
    { "y", function() copy_item(false) end }, { "x", function() copy_item(true) end }, { "p", paste_item },
    { "Y", function() copy_path(true) end }, { "gy", function() copy_path(false) end },
    { "?", show_help },
    { ">", function()
      state.width = state.width + 5; vim.cmd("vertical resize " .. state.width)
    end },
    { "<", function()
      state.width = math.max(MIN_WIDTH, state.width - 5); vim.cmd("vertical resize " .. state.width)
    end },
  }
  for _, m in ipairs(maps) do vim.keymap.set("n", m[1], m[2], opts) end
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win); return
  end
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then setup_buffer() end
  state.root = state.root or vim.fn.getcwd()
  vim.cmd("topleft " .. state.width .. "vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  local wo = vim.wo[state.win]
  wo.wrap, wo.cursorline, wo.number, wo.relativenumber, wo.signcolumn, wo.foldcolumn, wo.spell = false, true, false,
      false, "no", "0", false
  render(true)
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    if #vim.api.nvim_list_wins() > 1 then vim.api.nvim_win_close(state.win, true) end
    state.win = nil
  end
end

function M.toggle() if state.win and vim.api.nvim_win_is_valid(state.win) then M.close() else M.open() end end

function M.reveal()
  local current_buf = vim.api.nvim_buf_get_name(0)
  if current_buf == "" or current_buf:find("FileTree") then return end
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then M.open() end
  local root = state.root or vim.fn.getcwd()
  if current_buf:sub(1, #root) == root then
    local curr = current_buf
    while curr and curr ~= root do
      local parent = vim.fn.fnamemodify(curr, ":h")
      if parent == curr then break end
      state.expanded[parent] = true
      curr = parent
    end
  end
  render(false)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    for i, item in ipairs(state.line_to_path) do
      if item.path == current_buf then
        vim.api.nvim_win_set_cursor(state.win, { i + 1, 0 })
        break
      end
    end
  end
end

function M.setup(opts)
  opts = opts or {}
  vim.keymap.set("n", "<leader>e", M.toggle, { desc = "Open file tree" })
  setup_highlights()
  vim.api.nvim_create_autocmd("ColorScheme",
    { callback = function()
      setup_highlights(); if state.buf and vim.api.nvim_buf_is_valid(state.buf) then render(false) end
    end })
  vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
    callback = function()
      if state.win and vim.api.nvim_win_is_valid(state.win) then
        update_git_status(function()
          if state.buf and vim.api.nvim_buf_is_valid(state.buf) then render(false) end
        end)
      end
    end
  })
  vim.api.nvim_create_user_command("FileTree", function() M.toggle() end, {})
  vim.api.nvim_create_user_command("FileTreeFind", function() M.reveal() end, {})
end

return M
