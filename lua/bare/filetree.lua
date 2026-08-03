--[[
FileTree Keymaps:
l, <CR>   - Open / expand
h         - Collapse / go to parent
-         - Go to parent directory as root
C         - Set highlighted directory as root
m         - Toggle select / mark mode
M         - Clear selection
a         - New file
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
]]
local M = {}
local state = {
  expanded = {},
  show_hidden = false,
  clipboard = nil,
  selected = {},
  git = {},
  width = 30,
  mark_mode = false,
}
local MIN_WIDTH = 20
local has_icons, icons = pcall(require, "bare.icons")
local folder_icons = {
  expanded  = { icon = " " },
  collapsed = { icon = " " },
}

local function get_icon(name, is_dir, is_expanded)
  if is_dir then
    local icon = (is_expanded and folder_icons.expanded or folder_icons.collapsed).icon
    return icon, "FileTreeFolder" .. (is_expanded and "Expanded" or "Collapsed")
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

local function get_compact_dir(item, cache)
  if not item.is_dir then return item.name, item.path end
  local parts, current = { item.name }, item
  while true do
    local children = read_dir(current.path, cache)
    if #children == 1 and children[1].is_dir then
      current = children[1]
      table.insert(parts, current.name)
    else
      break
    end
  end
  return table.concat(parts, "/"), current.path
end

local function build_tree(path, depth, lines, map, extmarks, cache, is_last_table)
  depth, lines, map, extmarks, cache, is_last_table = depth or 0, lines or {}, map or {}, extmarks or {}, cache or {},
      is_last_table or {}
  local items = read_dir(path, cache)

  for idx, item in ipairs(items) do
    local is_last = (idx == #items)
    is_last_table[depth] = is_last

    local indent_str, guide_extmarks = "", {}
    for d = 0, depth - 1 do
      local start_col = #indent_str
      if is_last_table[d] then
        indent_str = indent_str .. "   "
      else
        indent_str = indent_str .. " │ "
        table.insert(guide_extmarks, { col = start_col + 1, len = 3 })
      end
    end

    local is_expanded, is_selected, is_hidden = state.expanded[item.path], state.selected[item.path],
        item.name:sub(1, 1) == "."
    local icon, icon_hl = get_icon(item.name, item.is_dir, is_expanded)

    local is_cut = false
    if state.clipboard and state.clipboard.move and state.clipboard.paths then
      for _, p in ipairs(state.clipboard.paths) do
        if item.path == p or item.path:sub(1, #p + 1) == p .. "/" then
          is_cut = true; break
        end
      end
    end
    if is_cut or is_hidden then icon_hl = "FileTreeHidden" end

    local connector_start = #indent_str
    local connector_str = is_selected and (is_last and " ┗╸" or " ┣╸") or (is_last and " └╴" or " ├╴")
    indent_str = indent_str .. connector_str
    if not is_selected then
      table.insert(guide_extmarks, { col = connector_start + 1, len = #connector_str - 1 })
    end

    local git = state.git[item.path]
    local git_hl = (git and not is_cut) and
        ((git == "M" and "FileTreeGitModified") or (git == "?" and "FileTreeGitUntracked")) or nil

    local display_name, final_path = get_compact_dir(item, cache)
    table.insert(lines, indent_str .. icon .. display_name)
    table.insert(map, { path = item.path, is_dir = item.is_dir, display_name = display_name })

    local line_idx = #lines - 1
    for _, g in ipairs(guide_extmarks) do
      table.insert(extmarks, { line = line_idx, col = g.col, end_col = g.col + g.len, hl = "FileTreeIndentGuide" })
    end

    if is_selected then
      table.insert(extmarks,
        { line = line_idx, col = connector_start + 1, end_col = connector_start + #connector_str, hl = "FileTreeSelected" })
    end

    local icon_col = #indent_str
    table.insert(extmarks, { line = line_idx, col = icon_col, end_col = icon_col + #icon, hl = git_hl or icon_hl })

    local text_col = icon_col + #icon
    local text_hl = (is_cut or is_hidden) and "FileTreeHidden" or git_hl or
        (item.is_dir and (is_expanded and "FileTreeFolderExpanded" or "FileTreeFolderCollapsed"))
    if text_hl then
      table.insert(extmarks, { line = line_idx, col = text_col, end_col = text_col + #display_name, hl = text_hl })
    end

    if item.is_dir and is_expanded then
      build_tree(final_path, depth + 1, lines, map, extmarks, cache, is_last_table)
    end
  end
  return lines, map, extmarks
end

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return (ok and hl) and hl or {}
end

local function setup_highlights()
  local dir, fn, norm, nontext, comment = get_hl("Directory"), get_hl("Function"), get_hl("Normal"), get_hl("NonText"),
      get_hl("Comment")
  local changed, untracked, warn, stmt, title = get_hl("diffChanged"), get_hl("DiagnosticSignInfo"),
      get_hl("DiagnosticSignWarn"), get_hl("Statement"), get_hl("Title")

  local dir_color = dir.fg or fn.fg or norm.fg
  local hidden_color = comment.fg or nontext.fg
  local guide_color = nontext.fg or comment.fg
  local selected_color = stmt.fg or title.fg or warn.fg

  vim.api.nvim_set_hl(0, "FileTreeRoot", { fg = dir_color, bold = true })
  vim.api.nvim_set_hl(0, "FileTreeIndentGuide", { fg = guide_color })
  vim.api.nvim_set_hl(0, "FileTreeFolderExpanded", { fg = dir_color, bold = true })
  vim.api.nvim_set_hl(0, "FileTreeFolderCollapsed", { fg = dir_color, bold = true })
  vim.api.nvim_set_hl(0, "FileTreeGitModified", { fg = changed.fg or warn.fg, bold = true })
  vim.api.nvim_set_hl(0, "FileTreeGitUntracked", { fg = untracked.fg or fn.fg, bold = true })
  vim.api.nvim_set_hl(0, "FileTreeHidden", { fg = hidden_color, italic = true })
  vim.api.nvim_set_hl(0, "FileTreeSelected", { fg = selected_color, bold = true })
end

local function get_item()
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then return end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  return row > 1 and state.line_to_path[row - 1]
end

local function current_dir()
  local item = get_item()
  return (item and (item.is_dir and item.path or vim.fn.fnamemodify(item.path, ":h"))) or (state.root or vim.fn.getcwd())
end

local function selected_paths(item)
  local paths = {}
  for p in pairs(state.selected) do table.insert(paths, p) end
  if #paths == 0 and item then table.insert(paths, item.path) end
  return paths
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
        if file:sub(1, 1) == '"' and file:sub(-1) == '"' then file = file:sub(2, -2) end
        if status:match("M") then
          git[root .. "/" .. file] = "M"
        elseif status:match("%?%?") or status:match("U") then
          git[root .. "/" .. file] = "?"
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
  local root_path = state.root or vim.fn.getcwd()
  local root_name = vim.fn.fnamemodify(root_path, ":t")
  if root_name == "" then root_name = root_path end
  local root_base = "  " .. root_name
  local root_text = root_base .. (state.mark_mode and " 󰃀" or "")
  table.insert(lines, 1, root_text)

  state.line_to_path = map
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("filetree")
  vim.api.nvim_buf_set_extmark(state.buf, ns, 0, 0, { end_row = 0, end_col = #root_base, hl_group = "FileTreeRoot" })
  if state.mark_mode then
    vim.api.nvim_buf_set_extmark(state.buf, ns, 0, #root_base,
      { end_row = 0, end_col = #root_text, hl_group = "FileTreeSelected" })
  end

  for _, m in ipairs(extmarks) do
    if m.hl then
      vim.api.nvim_buf_set_extmark(state.buf, ns, m.line + 1, m.col,
        { end_row = m.line + 1, end_col = m.end_col, hl_group = m.hl })
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

local function ensure_editor_options(win)
  if win and vim.api.nvim_win_is_valid(win) then
    local wo = vim.wo[win]
    wo.number, wo.relativenumber, wo.signcolumn, wo.wrap = true, true, "yes:1", false
  end
  return win
end

local function get_target_win()
  local function is_valid(w)
    return w and w > 0 and w ~= state.win and vim.api.nvim_win_is_valid(w)
        and vim.api.nvim_win_get_config(w).relative == ""
        and vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= "filetree"
        and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ""
  end
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  local target = is_valid(prev) and prev or nil
  if not target then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if is_valid(w) then
        target = w; break
      end
    end
  end
  if not target and state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    vim.cmd("rightbelow vsplit")
    target = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(state.win, state.width)
  end
  return ensure_editor_options(target or vim.api.nvim_get_current_win())
end

local function open_file()
  local item = get_item()
  if not item then return end
  if item.is_dir then
    state.expanded[item.path] = not state.expanded[item.path]
    render(true)
  else
    local target_win = get_target_win()
    vim.api.nvim_set_current_win(target_win)
    vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    ensure_editor_options(vim.api.nvim_get_current_win())
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

local function move_cursor(dir)
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then return end
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local total = vim.api.nvim_buf_line_count(state.buf)
  local target = math.max(2, math.min(total, cursor[1] + dir))
  vim.api.nvim_win_set_cursor(state.win, { target, cursor[2] })
  if state.mark_mode then
    local item = get_item()
    if item then
      state.selected[item.path] = not state.selected[item.path] or nil
      render(false)
    end
  end
end

local function exit_mark_mode()
  if state.mark_mode then
    state.mark_mode = false; render(false)
  end
end

local function handle_esc()
  if state.mark_mode then exit_mark_mode() else M.close() end
end

local function toggle_select()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("normal! \27")
    local start_line, end_line = vim.fn.line("'<"), vim.fn.line("'>")
    if start_line > end_line then start_line, end_line = end_line, start_line end
    for line = start_line, end_line do
      local item = state.line_to_path[line - 1]
      if item then state.selected[item.path] = not state.selected[item.path] or nil end
    end
    render(false)
  else
    state.mark_mode = not state.mark_mode
    local item = get_item()
    if item then state.selected[item.path] = not state.selected[item.path] or nil end
    render(false)
  end
end

local function change_root(dir)
  if dir then
    state.root = dir; render(true)
  end
end

local function copy_path(rel)
  local item = get_item()
  if not item then return end
  local paths = selected_paths(item)
  local formatted = {}
  for _, p in ipairs(paths) do table.insert(formatted, rel and vim.fn.fnamemodify(p, ":.") or p) end
  vim.fn.setreg("+", table.concat(formatted, "\n"))
  if #paths == 1 then
    vim.notify("Copied path: " .. formatted[1])
  else
    local names = {}
    for _, p in ipairs(paths) do table.insert(names, vim.fn.fnamemodify(p, ":t")) end
    vim.notify("Copied " .. #paths .. " paths: " .. table.concat(names, ", "))
  end
end

local function create_entry(is_dir)
  local parent = current_dir()
  local prompt = is_dir and "New directory: " or "New file: "
  vim.ui.input({ prompt = prompt }, function(name)
    if not (name and name ~= "") then return end
    local path = parent .. "/" .. name
    if is_dir then
      vim.fn.mkdir(path, "p")
      state.expanded[parent] = true
      render(true)
    else
      vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
      local f = io.open(path, "w")
      if f then f:close() end
      state.expanded[parent] = true
      render(true)
      vim.schedule(function() open_file() end)
    end
  end)
end

local function delete_item()
  local item = get_item()
  if not item then return end
  local paths = selected_paths(item)
  vim.ui.input({ prompt = "Delete " .. #paths .. " items? (y/N): " }, function(confirm)
    if confirm and confirm:lower() == "y" then
      for _, p in ipairs(paths) do vim.fn.delete(p, vim.fn.isdirectory(p) == 1 and "rf" or "") end
      state.selected = {}
      render(true)
    end
  end)
end

local function rename_item()
  local item = get_item()
  if not item then return end
  local old_name = vim.fn.fnamemodify(item.path, ":t")
  vim.ui.input({ prompt = "Rename: ", default = old_name }, function(new_name)
    if not (new_name and new_name ~= "" and new_name ~= old_name) then return end
    local new_path = vim.fn.fnamemodify(item.path, ":h") .. "/" .. new_name
    if os.rename(item.path, new_path) then
      state.expanded[new_path] = state.expanded[item.path]
      state.expanded[item.path] = nil
      render(true)
    end
  end)
end

local function copy_recursive(src, dest)
  if vim.fn.isdirectory(src) == 1 then
    vim.fn.mkdir(dest, "p")
    for _, item in ipairs(read_dir(src)) do copy_recursive(item.path, dest .. "/" .. item.name) end
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

local clipboard = {}

function clipboard.copy(move)
  local item = get_item()
  if not item then return end
  local paths = selected_paths(item)
  state.clipboard = { paths = paths, move = move }
  state.mark_mode = false
  local names = {}
  for _, p in ipairs(paths) do table.insert(names, vim.fn.fnamemodify(p, ":t")) end
  local action = move and "Cut" or "Copied"
  vim.notify((#paths == 1) and (action .. ": " .. names[1]) or
    (action .. " " .. #paths .. " items: " .. table.concat(names, ", ")))
  render(false)
end

function clipboard.paste()
  if not state.clipboard then return end
  local dest = current_dir()
  local names = {}
  for _, src in ipairs(state.clipboard.paths) do
    local name = vim.fn.fnamemodify(src, ":t")
    table.insert(names, name)
    local target = dest .. "/" .. name
    if state.clipboard.move then os.rename(src, target) else copy_recursive(src, target) end
  end
  if state.clipboard.move then state.clipboard = nil end
  state.selected = {}
  render(true)
  vim.notify((#names == 1) and ("Pasted: " .. names[1]) or
    ("Pasted " .. #names .. " items: " .. table.concat(names, ", ")))
end

local function resize(delta)
  state.width = math.max(MIN_WIDTH, state.width + delta)
  vim.cmd("vertical resize " .. state.width)
end

local function setup_buffer()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.buf, "FileTree")
  local bo = vim.bo[state.buf]
  bo.bufhidden, bo.filetype, bo.buftype, bo.swapfile, bo.buflisted = "hide", "filetree", "nofile", false, false
  local opts = { buffer = state.buf, silent = true, nowait = true }
  local maps = {
    { "<CR>",          open_file },
    { "l",             open_file },
    { "<2-LeftMouse>", open_file },
    { "h",             collapse },
    { "-",             function() change_root(vim.fn.fnamemodify(state.root or vim.fn.getcwd(), ":h")) end },
    { "C", function()
      local item = get_item(); if item and item.is_dir then change_root(item.path) end
    end },
    { "j",      function() move_cursor(1) end },
    { "<Down>", function() move_cursor(1) end },
    { "k",      function() move_cursor(-1) end },
    { "<Up>",   function() move_cursor(-1) end },
    { "H", function()
      state.show_hidden = not state.show_hidden; render(true)
    end },
    { "q",     M.close },
    { "<Esc>", handle_esc },
    { "a",     function() create_entry(false) end },
    { "A",     function() create_entry(true) end },
    { "d",     delete_item },
    { "r",     rename_item },
    { "R",     function() render(true) end },
    { "m",     toggle_select,                     mode = { "n", "v" } },
    { "M", function()
      state.selected = {}; state.mark_mode = false; render(false)
    end },
    { "y",  function() clipboard.copy(false) end },
    { "x",  function() clipboard.copy(true) end },
    { "p",  clipboard.paste },
    { "Y",  function() copy_path(true) end },
    { "gy", function() copy_path(false) end },
    { ">",  function() resize(5) end },
    { "<",  function() resize(-5) end },
  }
  for _, m in ipairs(maps) do vim.keymap.set(m.mode or "n", m[1], m[2], opts) end
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
  state.mark_mode = false
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
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      setup_highlights(); if state.buf and vim.api.nvim_buf_is_valid(state.buf) then render(false) end
    end
  })
  vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
    callback = function()
      if state.win and vim.api.nvim_win_is_valid(state.win) then
        update_git_status(function()
          if state.buf and vim.api.nvim_buf_is_valid(state.buf) then render(false) end
        end)
      end
    end
  })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter" }, {
    nested = true,
    callback = function(ev)
      local win = vim.api.nvim_get_current_win()
      local buf = ev.buf
      if not (state.win and vim.api.nvim_win_is_valid(state.win)) then return end
      if win ~= state.win then return end

      if state.buf and vim.api.nvim_buf_is_valid(state.buf) and buf ~= state.buf then
        local bo = vim.bo[buf]
        if bo.filetype ~= "filetree" and bo.buftype == "" then
          vim.api.nvim_win_set_buf(state.win, state.buf)
          local target_win = get_target_win()
          vim.api.nvim_set_current_win(target_win)
          vim.api.nvim_win_set_buf(target_win, buf)
          ensure_editor_options(target_win)
        end
      end
    end,
  })
  vim.api.nvim_create_user_command("FileTree", function() M.toggle() end, {})
  vim.api.nvim_create_user_command("FileTreeFind", function() M.reveal() end, {})
end

M.setup()

return M
