-- Keymaps:
-- <CR>/l: open | h: back | -: parent | C: enter dir
-- j/k: move | H: hidden | q: close | a/A: create
-- d: delete | r: rename | u: undo | R: refresh
-- m: mark | M: clear | y: copy | x: cut | p: paste
-- </Esc>: cancel | </>: resize

local M = {}
local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("filetree")
local MIN_WIDTH = 20

local state = {
  expanded = {},
  show_hidden = false,
  clipboard = nil,
  selected = {},
  git = {},
  width = 30,
  undo = {},
  buf = nil,
  win = nil,
  line_to_path = {},
  root = nil,
}

local sel = { anchor = nil, base = nil }
local has_icons, icons = pcall(require, "bare.icons")

local function win()
  return state.win and vim.api.nvim_win_is_valid(state.win) and state.win
end

local function buf()
  return state.buf and vim.api.nvim_buf_is_valid(state.buf) and state.buf
end

local function root()
  return state.root or vim.fn.getcwd()
end

local function item()
  local w = win()
  if not w then return end
  local row = vim.api.nvim_win_get_cursor(w)[1]
  return state.line_to_path[row - 1]
end

local function current_dir()
  local it = item()
  return (it and (it.is_dir and it.path or vim.fs.dirname(it.path))) or root()
end

local function paths(x)
  local ps = vim.tbl_keys(state.selected)
  return #ps > 0 and ps or (x and { x.path } or {})
end

local function set_cursor_to_path(path)
  local w = win()
  if not w or not path then return end
  if path == root() then return vim.api.nvim_win_set_cursor(w, { 1, 0 }) end
  for i, it in ipairs(state.line_to_path) do
    if it.path == path then return vim.api.nvim_win_set_cursor(w, { i + 1, 0 }) end
  end
end

local function is_cut(path)
  local cb = state.clipboard
  if not (cb and cb.move) then return false end
  for _, p in ipairs(cb.paths) do
    if path == p or path:sub(1, #p + 1) == p .. "/" then return true end
  end
  return false
end

local function get_icon(name, is_dir, is_expanded)
  if is_dir then
    return is_expanded and " " or " ", "FileTreeFolder" .. (is_expanded and "Expanded" or "Collapsed")
  end
  if has_icons then
    local ft = vim.filetype.match({ filename = name }) or name:match("%.([^.]+)$")
    local icon, hl = icons.get(ft)
    if icon and icon ~= "" then return icon .. " ", hl end
  end
  return "󰈤 ", "FileIconDefault"
end

local function setup_highlights()
  local function fg(n)
    local hl = vim.api.nvim_get_hl(0, { name = n, link = false })
    return hl and hl.fg
  end
  local dir_fg = fg("Directory") or fg("Function") or fg("Normal")
  local hls = {
    FileTreeRoot = { fg = dir_fg, bold = true },
    FileTreeIndentGuide = { fg = fg("NonText") or fg("Comment") },
    FileTreeFolderExpanded = { fg = dir_fg, bold = true },
    FileTreeFolderCollapsed = { fg = dir_fg, bold = true },
    FileTreeGitModified = { fg = fg("diffChanged") or fg("DiagnosticSignWarn"), bold = true },
    FileTreeGitUntracked = { fg = fg("DiagnosticSignInfo") or fg("Function"), bold = true },
    FileTreeHidden = { fg = fg("Comment") or fg("NonText"), italic = true },
    FileTreeSelected = { fg = fg("Statement") or fg("Title") or fg("DiagnosticSignWarn"), bold = true },
  }
  for name, def in pairs(hls) do vim.api.nvim_set_hl(0, name, def) end
end

local function read_dir(path, cache)
  if cache and cache[path] then return cache[path] end
  local items, ok, dir = {}, pcall(vim.fs.dir, path)
  if ok and dir then
    for name, type in dir do
      if state.show_hidden or name:sub(1, 1) ~= "." then
        items[#items + 1] = { name = name, path = vim.fs.joinpath(path, name), is_dir = (type == "directory") }
      end
    end
    table.sort(items, function(a, b)
      if a.is_dir ~= b.is_dir then
        return a.is_dir
      end
      local name_a = a.name:lower()
      local name_b = b.name:lower()
      if name_a ~= name_b then
        return name_a < name_b
      end
      return a.name < b.name
    end)
  end
  if cache then cache[path] = items end
  return items
end

local function get_compact_dir(it, cache)
  if not it.is_dir then return it.name, it.path end
  local parts, cur = { it.name }, it
  while true do
    local children = read_dir(cur.path, cache)
    if #children == 1 and children[1].is_dir then
      cur = children[1]
      parts[#parts + 1] = cur.name
    else
      break
    end
  end
  return table.concat(parts, "/"), cur.path
end

local function mark(ctx, line, col, end_col, hl)
  if hl then ctx.extmarks[#ctx.extmarks + 1] = { line = line, col = col, end_col = end_col, hl = hl } end
end

local function build_tree(path, depth, ctx)
  depth, ctx = depth or 0, ctx or { lines = {}, map = {}, extmarks = {}, cache = {}, last = {} }
  local items = read_dir(path, ctx.cache)

  for idx, it in ipairs(items) do
    local is_last, line_idx = (idx == #items), #ctx.lines
    ctx.last[depth] = is_last

    local indent = ""
    for d = 0, depth - 1 do
      local sc = #indent
      indent = indent .. (ctx.last[d] and "   " or " │ ")
      if not ctx.last[d] then mark(ctx, line_idx, sc + 1, sc + 4, "FileTreeIndentGuide") end
    end

    local is_exp, is_sel, cut = state.expanded[it.path], state.selected[it.path], is_cut(it.path)
    local hidden = cut or it.name:sub(1, 1) == "."
    local icon, icon_hl = get_icon(it.name, it.is_dir, is_exp)

    local conn_start = #indent
    local conn = is_sel and (is_last and " ┗╸" or " ┣╸") or (is_last and " └╴" or " ├╴")
    indent = indent .. conn
    mark(ctx, line_idx, conn_start + 1, conn_start + #conn, is_sel and "FileTreeSelected" or "FileTreeIndentGuide")

    local git = state.git[it.path]
    local git_hl = (git and not cut) and (git == "M" and "FileTreeGitModified" or "FileTreeGitUntracked")

    local name, final_path = get_compact_dir(it, ctx.cache)
    ctx.lines[#ctx.lines + 1] = indent .. icon .. name
    ctx.map[#ctx.map + 1] = it

    local icon_col = #indent
    mark(ctx, line_idx, icon_col, icon_col + #icon, hidden and "FileTreeHidden" or git_hl or icon_hl)

    local text_hl = hidden and "FileTreeHidden" or git_hl or
        (it.is_dir and ("FileTreeFolder" .. (is_exp and "Expanded" or "Collapsed")))
    mark(ctx, line_idx, icon_col + #icon, icon_col + #icon + #name, text_hl)

    if it.is_dir and is_exp then build_tree(final_path, depth + 1, ctx) end
  end
  return ctx
end

local function refresh_git(cb)
  local r = root()
  if not vim.fs.root(r, ".git") then
    state.git = {}
    if cb then cb() end
    return
  end
  vim.system({ "git", "-C", r, "status", "--porcelain" }, { text = true }, function(obj)
    local git = {}
    if obj.code == 0 and obj.stdout then
      for line in obj.stdout:gmatch("[^\r\n]+") do
        local status, file = line:sub(1, 2), line:sub(4)
        if file:sub(1, 1) == '"' then file = file:sub(2, -2) end
        if status:match("M") then
          git[vim.fs.joinpath(r, file)] = "M"
        elseif status:match("%?%?") or status:match("U") then
          git[vim.fs.joinpath(r, file)] = "?"
        end
      end
    end
    vim.schedule(function()
      state.git = git
      if cb then cb() else if buf() then render(false) end end
    end)
  end)
end

function render(update_git)
  local b, w = buf(), win()
  if not b then return end

  local cur_path
  if w then
    local row = vim.api.nvim_win_get_cursor(w)[1]
    cur_path = row == 1 and root() or (state.line_to_path[row - 1] and state.line_to_path[row - 1].path)
  end

  local r = root()
  local r_name = vim.fs.basename(r)
  local r_text = "  " .. (r_name and r_name ~= "" and r_name or r)
  local ctx = build_tree(r)
  table.insert(ctx.lines, 1, r_text)
  state.line_to_path = ctx.map

  vim.bo[b].modifiable = true
  vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
  vim.api.nvim_buf_set_lines(b, 0, -1, false, ctx.lines)
  vim.api.nvim_buf_set_extmark(b, ns, 0, 0, { end_row = 0, end_col = #r_text, hl_group = "FileTreeRoot" })
  for _, m in ipairs(ctx.extmarks) do
    vim.api.nvim_buf_set_extmark(b, ns, m.line + 1, m.col, { end_row = m.line + 1, end_col = m.end_col, hl_group = m.hl })
  end
  vim.bo[b].modifiable = false

  if cur_path then set_cursor_to_path(cur_path) end
  if update_git then refresh_git() end
end

local function ensure_editor_options(w)
  if w and vim.api.nvim_win_is_valid(w) then
    local wo = vim.wo[w]
    wo.number, wo.relativenumber, wo.signcolumn, wo.wrap = true, true, "yes:1", false
  end
  return w
end

local function is_valid_target(w)
  return w and vim.api.nvim_win_is_valid(w) and w > 0 and w ~= state.win
      and vim.api.nvim_win_get_config(w).relative == ""
      and vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= "filetree"
      and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ""
end

local function find_target_win()
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if is_valid_target(prev) then return prev end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_valid_target(w) then return w end
  end
end

local function create_target_win()
  if win() then
    vim.api.nvim_set_current_win(state.win)
    vim.cmd("rightbelow vsplit")
    local target = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(state.win, state.width)
    return target
  end
  return vim.api.nvim_get_current_win()
end

local function get_target_win()
  return find_target_win() or create_target_win()
end

local function open_file()
  local it = item()
  if not it then return end
  if it.is_dir then
    state.expanded[it.path] = not state.expanded[it.path]
    render(true)
  else
    local target = get_target_win()
    vim.api.nvim_set_current_win(target)
    vim.cmd("edit " .. vim.fn.fnameescape(it.path))
    ensure_editor_options(target)
  end
end

local function change_root(dir)
  if dir and dir ~= "" then
    local prev = root()
    state.root = dir
    render(true)
    set_cursor_to_path(prev)
  end
end

local function collapse()
  local w = win()
  if not w then return end
  if vim.api.nvim_win_get_cursor(w)[1] == 1 then
    local parent = vim.fs.dirname(root())
    if parent ~= root() then change_root(parent) end
    return
  end
  local it = item()
  if not it then return end
  if it.is_dir and state.expanded[it.path] then
    state.expanded[it.path] = false
    render(true)
  else
    local curr, r = it.path, root()
    while curr ~= r do
      local parent = vim.fs.dirname(curr)
      if parent == curr then break end
      if state.expanded[parent] then
        state.expanded[parent] = false
        render(true)
        set_cursor_to_path(parent)
        return
      end
      curr = parent
    end
    set_cursor_to_path(r)
  end
end

local function move_cursor(dir, shift)
  local w = win()
  if not w then return end
  local cursor = vim.api.nvim_win_get_cursor(w)
  local target_row = math.max(1, math.min(vim.api.nvim_buf_line_count(state.buf), cursor[1] + dir))

  if not shift then
    sel.anchor, sel.base = nil, nil
    vim.api.nvim_win_set_cursor(w, { target_row, cursor[2] })
    return
  end
  if target_row == cursor[1] then return end

  if not sel.anchor then
    sel.anchor = cursor[1]
    sel.base = vim.deepcopy(state.selected)
  end

  vim.api.nvim_win_set_cursor(w, { target_row, cursor[2] })
  state.selected = vim.deepcopy(sel.base)
  for r = math.min(sel.anchor, target_row), math.max(sel.anchor, target_row) do
    if r > 1 and state.line_to_path[r - 1] then
      state.selected[state.line_to_path[r - 1].path] = true
    end
  end
  render(false)
end

local function handle_esc()
  sel.anchor, sel.base = nil, nil
  if next(state.selected) then
    state.selected = {}
    render(false)
  else
    M.close()
  end
end

local function toggle_file()
  sel.anchor, sel.base = nil, nil
  local it = item()
  if it then state.selected[it.path] = not state.selected[it.path] or nil end
  render(false)
end

local function copy_recursive(src, dest)
  vim.fn.mkdir(vim.fs.dirname(dest), "p")
  local stat = uv.fs_stat(src)
  if stat and stat.type == "directory" then
    return vim.system({ "cp", "-a", src, dest }):wait().code == 0
  end
  return uv.fs_copyfile(src, dest)
end

local function get_trash_dir()
  local dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "filetree_trash")
  vim.fn.mkdir(dir, "p")
  return dir
end

local function create_entry(is_dir)
  local parent = current_dir()
  vim.ui.input({ prompt = is_dir and "New directory: " or "New file: " }, function(name)
    if not (name and name ~= "") then return end
    local path = vim.fs.joinpath(parent, name)
    if is_dir then
      vim.fn.mkdir(path, "p")
    else
      vim.fn.mkdir(vim.fs.dirname(path), "p")
      local f = io.open(path, "w")
      if not f then return end
      f:close()
    end
    table.insert(state.undo, { type = "create", path = path, is_dir = is_dir, name = name })
    state.expanded[parent] = true
    render(true)
    if not is_dir then
      vim.schedule(function()
        set_cursor_to_path(path)
        open_file()
      end)
    end
  end)
end

local function delete_item()
  local ps = paths(item())
  if #ps == 0 then return end
  vim.ui.input({ prompt = "Delete " .. #ps .. " items? (y/N): " }, function(confirm)
    if not (confirm and confirm:lower() == "y") then return end
    local undo_items, trash_base = {}, vim.fs.joinpath(get_trash_dir(), os.time() .. "_" .. math.random(1000, 9999))
    vim.fn.mkdir(trash_base, "p")
    for idx, p in ipairs(ps) do
      local is_dir = (vim.fn.isdirectory(p) == 1)
      local backup = vim.fs.joinpath(trash_base, idx .. "_" .. vim.fs.basename(p))
      if copy_recursive(p, backup) then
        vim.fn.delete(p, is_dir and "rf" or "")
        table.insert(undo_items, { original_path = p, backup_path = backup, is_dir = is_dir })
      end
    end
    if #undo_items > 0 then
      table.insert(state.undo, { type = "delete", items = undo_items, trash_base = trash_base })
    end
    state.selected = {}
    render(true)
  end)
end

local function rename_item()
  local it = item()
  if not it then return end
  local old_name = vim.fs.basename(it.path)
  vim.ui.input({ prompt = "Rename: ", default = old_name }, function(new_name)
    if not (new_name and new_name ~= "" and new_name ~= old_name) then return end
    local old_path = it.path
    local new_path = vim.fs.joinpath(vim.fs.dirname(old_path), new_name)
    if os.rename(old_path, new_path) then
      table.insert(state.undo, {
        type = "rename", old_path = old_path, new_path = new_path, old_name = old_name, new_name = new_name
      })
      state.expanded[new_path] = state.expanded[old_path]
      state.expanded[old_path] = nil
      render(true)
    end
  end)
end

local function copy_or_cut(move)
  local ps = paths(item())
  if #ps == 0 then return end
  state.clipboard, sel.anchor, sel.base = { paths = ps, move = move }, nil, nil
  local names = vim.tbl_map(vim.fs.basename, ps)
  local action = move and "Cut" or "Copied"
  vim.notify(#ps == 1 and (action .. ": " .. names[1]) or
    (action .. " " .. #ps .. " items: " .. table.concat(names, ", ")))
  render(false)
end

local function paste()
  if not state.clipboard then return end
  local dest, names, undo_items, is_move = current_dir(), {}, {}, state.clipboard.move
  for _, src in ipairs(state.clipboard.paths) do
    local name = vim.fs.basename(src)
    local target = vim.fs.joinpath(dest, name)
    local is_dir = (vim.fn.isdirectory(src) == 1)
    if (is_move and os.rename(src, target) or copy_recursive(src, target)) then
      table.insert(names, name)
      table.insert(undo_items, { src = src, target = target, is_dir = is_dir })
    end
  end
  if #undo_items > 0 then
    table.insert(state.undo, { type = is_move and "move" or "copy", items = undo_items })
  end
  if is_move then state.clipboard = nil end
  state.selected = {}
  render(true)
  if #names > 0 then
    vim.notify(#names == 1 and ("Pasted: " .. names[1]) or
      ("Pasted " .. #names .. " items: " .. table.concat(names, ", ")))
  end
end

local function undo_operation()
  local act = table.remove(state.undo)
  if not act then return vim.notify("Nothing to undo", vim.log.levels.WARN) end

  if act.type == "create" then
    if uv.fs_stat(act.path) then
      vim.fn.delete(act.path, act.is_dir and "rf" or "")
      vim.notify("Undid creation: " .. act.name)
    else
      vim.notify("Cannot undo creation (file not found): " .. act.path, vim.log.levels.WARN)
    end
  elseif act.type == "rename" then
    if uv.fs_stat(act.new_path) then
      os.rename(act.new_path, act.old_path)
      state.expanded[act.old_path], state.expanded[act.new_path] = state.expanded[act.new_path], nil
      vim.notify("Undid rename: " .. act.new_name .. " -> " .. act.old_name)
    else
      vim.notify("Cannot undo rename (file not found): " .. act.new_path, vim.log.levels.WARN)
    end
  elseif act.type == "copy" or act.type == "move" then
    local count = 0
    for _, it in ipairs(act.items) do
      if uv.fs_stat(it.target) then
        if act.type == "copy" then vim.fn.delete(it.target, it.is_dir and "rf" or "") else os.rename(it.target, it.src) end
        count = count + 1
      end
    end
    vim.notify("Undid paste (" .. act.type .. ") for " .. count .. " item(s)")
  elseif act.type == "delete" then
    local count = 0
    for _, it in ipairs(act.items) do
      if uv.fs_stat(it.backup_path) then
        vim.fn.mkdir(vim.fs.dirname(it.original_path), "p")
        if copy_recursive(it.backup_path, it.original_path) then
          vim.fn.delete(it.backup_path, it.is_dir and "rf" or "")
          count = count + 1
        end
      end
    end
    if act.trash_base and uv.fs_stat(act.trash_base) then vim.fn.delete(act.trash_base, "rf") end
    vim.notify("Undid deletion of " .. count .. " item(s)")
  end
  render(true)
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
    { { "<CR>", "l", "<2-LeftMouse>" }, open_file },
    { "h",                              collapse },
    { "-",                              function() change_root(vim.fs.dirname(root())) end },
    { "C", function()
      local it = item(); if it and it.is_dir then change_root(it.path) end
    end },
    { { "j", "<Down>" }, function() move_cursor(1) end },
    { { "k", "<Up>" },   function() move_cursor(-1) end },
    { "<S-Down>",        function() move_cursor(1, true) end },
    { "<S-Up>",          function() move_cursor(-1, true) end },
    { "H", function()
      state.show_hidden = not state.show_hidden; render(true)
    end },
    { "q",     M.close },
    { "<Esc>", handle_esc },
    { "a",     function() create_entry(false) end },
    { "A",     function() create_entry(true) end },
    { "d",     delete_item },
    { "r",     rename_item },
    { "u",     undo_operation },
    { "R",     function() render(true) end },
    { "m",     toggle_file },
    { "M", function()
      state.selected, sel.anchor, sel.base = {}, nil, nil; render(false)
    end },
    { "y", function() copy_or_cut(false) end },
    { "x", function() copy_or_cut(true) end },
    { "p", paste },
    { ">", function() resize(5) end },
    { "<", function() resize(-5) end },
  }
  for _, m in ipairs(maps) do
    for _, k in ipairs(type(m[1]) == "table" and m[1] or { m[1] }) do
      vim.keymap.set(m.mode or "n", k, m[2], opts)
    end
  end
end

function M.open()
  if win() then return vim.api.nvim_set_current_win(state.win) end
  if not buf() then setup_buffer() end
  state.root = root()
  vim.cmd("topleft " .. state.width .. "vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  local wo = vim.wo[state.win]
  wo.wrap, wo.cursorline, wo.number, wo.relativenumber, wo.signcolumn, wo.foldcolumn, wo.spell = false, true, false,
      false, "no", "0", false
  render(true)
end

function M.close()
  sel.anchor, sel.base = nil, nil
  if win() then
    if #vim.api.nvim_list_wins() > 1 then vim.api.nvim_win_close(state.win, true) end
    state.win = nil
  end
end

function M.toggle()
  if win() then
    M.close()
  else
    M.reveal()
  end
end

function M.reveal()
  local current_buf = vim.api.nvim_buf_get_name(0)
  if current_buf:find("FileTree") then return end
  if not win() then M.open() end
  if current_buf == "" then return end

  local r = root()
  if current_buf:sub(1, #r) == r then
    local curr = current_buf
    while curr ~= r do
      local parent = vim.fs.dirname(curr)
      if parent == curr then break end
      state.expanded[parent] = true
      curr = parent
    end
  end

  render(false)
  set_cursor_to_path(current_buf)
end

function M.setup()
  setup_highlights()

  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      setup_highlights()
      if buf() then render(false) end
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function()
      if win() then refresh_git() end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter" }, {
    nested = true,
    callback = function(ev)
      local w, b = vim.api.nvim_get_current_win(), ev.buf
      if not win() or w ~= state.win then return end
      if buf() and b ~= state.buf then
        local bo = vim.bo[b]
        if bo.filetype ~= "filetree" and bo.buftype == "" then
          vim.api.nvim_win_set_buf(state.win, state.buf)
          local target_win = get_target_win()
          vim.api.nvim_set_current_win(target_win)
          vim.api.nvim_win_set_buf(target_win, b)
          ensure_editor_options(target_win)
        end
      end
    end,
  })
  vim.api.nvim_create_user_command("FileTree", function() M.toggle() end, {})
  vim.api.nvim_create_user_command("FileTreeFind", function() M.reveal() end, {})
  vim.api.nvim_create_user_command("FileTreeClose", function() M.close() end, {})
end

M.setup()

return M
