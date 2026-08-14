local ui = require("bare.ui")
local M = {}
local ns = vim.api.nvim_create_namespace("bare_hints")

local builtin = {
  -- g commands
  ["gd"] = "Definition",
  ["gD"] = "Declaration",
  ["gy"] = "Type definition",
  ["gi"] = "Implementation",
  ["gr"] = "References",
  ["gl"] = "Line diagnostics",
  ["gg"] = "First line",
  ["gx"] = "Open file/URL",
  ["gc"] = "Comment",
  ["gcc"] = "Line comment",
  -- z commands
  ["zz"] = "Center cursor",
  ["zt"] = "Top cursor",
  ["zb"] = "Bottom cursor",
  ["za"] = "Toggle fold",
  ["zo"] = "Open fold",
  ["zc"] = "Close fold",
  ["zR"] = "Open all folds",
  ["zM"] = "Close all folds",
  -- Window commands
  ["<C-w>h"] = "Focus left",
  ["<C-w>j"] = "Focus down",
  ["<C-w>k"] = "Focus up",
  ["<C-w>l"] = "Focus right",
  ["<C-w>s"] = "Split horiz",
  ["<C-w>v"] = "Split vert",
  ["<C-w>c"] = "Close window",
  ["<C-w>o"] = "Close others",
  ["<C-w>q"] = "Quit window",
  ["<C-w>="] = "Equalize sizes",
  -- Navigation
  ["[d"] = "Prev diagnostic",
  ["]d"] = "Next diagnostic",
  ["[e"] = "Prev error",
  ["]e"] = "Next error",
  ["[w"] = "Prev warning",
  ["]w"] = "Next warning",
  ["[h"] = "Prev git hunk",
  ["]h"] = "Next git hunk",
  ["[b"] = "Prev buffer",
  ["]b"] = "Next buffer",
}

local default_triggers = { "<leader>", "g", "z", "<C-w>", "]", "[" }
local state = { win = nil, buf = nil, timer = nil, is_running = false }

local function term(s)
  return vim.api.nvim_replace_termcodes(s:gsub("<[lL]eader>", vim.g.mapleader or " "), true, true, true)
end

local function next_key(str, from)
  local rest = str:sub(from + 1)
  if rest == "" then return "" end
  if rest:byte(1) == 128 and #rest >= 3 then
    return rest:sub(1, 3)
  end
  return rest:match("^[%z\1-\127\194-\244][\128-\191]*") or rest:sub(1, 1)
end

local function key_name(k)
  if k == " " or k == term("<Space>") then return "<Space>" end
  if k == "\r" or k == "\n" then return "<CR>" end
  if k == "\t" then return "<Tab>" end
  local t = vim.fn.keytrans(k)
  return t ~= "" and t or k
end

local function format_title(q)
  local leader = term("<leader>")
  local s = ""
  local i = 0
  if q:sub(1, #leader) == leader then
    s = "<leader>"
    i = #leader
  end
  while i < #q do
    local k = next_key(q, i)
    if k == "" then break end
    s = s .. key_name(k)
    i = i + #k
  end
  return s
end

local function pop_key(q, root_len)
  local i = 0
  local last_pos = 0
  while i < #q do
    last_pos = i
    local k = next_key(q, i)
    if k == "" then break end
    i = i + #k
  end
  if last_pos >= root_len then
    return q:sub(1, last_pos)
  end
  return q:sub(1, root_len)
end

local function get_mappings(mode)
  local maps = {}
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    if m.desc and m.desc ~= "" then maps[term(m.lhs)] = { desc = m.desc, map = m } end
  end
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    local lhs = term(m.lhs)
    if not maps[lhs] and m.desc and m.desc ~= "" then maps[lhs] = { desc = m.desc, map = m } end
  end
  for k, desc in pairs(builtin) do
    local lhs = term(k)
    if not maps[lhs] then maps[lhs] = { desc = desc } end
  end
  return maps
end

local function collect_clues(query, maps)
  local next_keys, sub_counts = {}, {}

  for lhs, info in pairs(maps) do
    if lhs:sub(1, #query) == query and #lhs > #query then
      local next_k = next_key(lhs, #query)
      if next_k ~= "" then
        next_keys[next_k] = next_keys[next_k] or info
        sub_counts[next_k] = (sub_counts[next_k] or 0) + 1
      end
    end
  end

  local clues = {}
  for k, info in pairs(next_keys) do
    local full_k = query .. k
    local is_grp = (sub_counts[k] or 0) > 1 or not maps[full_k]
    local desc = is_grp and ("+" .. (maps[full_k] and maps[full_k].desc or key_name(k))) or info.desc
    table.insert(clues, { key = key_name(k), raw = k, desc = desc, is_group = is_grp })
  end
  table.sort(clues, function(a, b) return a.key < b.key end)
  return clues
end

local function close()
  if state.timer then
    pcall(function()
      state.timer:stop(); state.timer:close()
    end); state.timer = nil
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then pcall(vim.api.nvim_win_close, state.win, true) end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then pcall(vim.api.nvim_buf_delete, state.buf, { force = true }) end
  state.win, state.buf, state.is_running = nil, nil, false
  vim.cmd("redraw")
end

local function render(query, maps)
  local clues = collect_clues(query, maps)
  if #clues == 0 then return close() end

  local max_k = 0
  for _, it in ipairs(clues) do
    max_k = math.max(max_k, #it.key)
  end

  local lines, hls = {}, {}
  for i, it in ipairs(clues) do
    local line = string.format(" %-" .. max_k .. "s  %s", it.key, it.desc)
    table.insert(lines, line)
    table.insert(hls, { i - 1, 1, 1 + #it.key, "Special" })
    table.insert(hls, { i - 1, 1 + max_k + 2, #line, it.is_group and "Directory" or "Normal" })
  end

  local height = math.min(vim.o.lines - 4, #lines)
  local buf, win = ui.float({
    buf = state.buf,
    win = state.win,
    lines = lines,
    height = height,
    row = math.max(1, vim.o.lines - height - 3),
    col = math.max(1, vim.o.columns - 2),
    title = string.format(" %s ", format_title(query)),
    enter = false,
    focusable = false,
  })
  state.buf, state.win = buf, win

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable, vim.bo[buf].buftype = false, "nofile"
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
  end
  vim.cmd("redraw")
end

local function execute(query, maps)
  local item = maps[query]
  if item and item.map then
    local m = item.map
    if type(m.callback) == "function" then
      m.callback()
    elseif m.rhs and m.rhs ~= "" then
      local cmd = m.rhs:match("^<[cC][mM][dD]>(.*)<[cC][rR]>$") or m.rhs:match("^:(.*)<[cC][rR]>$")
      if cmd and not m.expr then
        vim.cmd(cmd)
      else
        vim.api.nvim_feedkeys(term(m.rhs), m.noremap == 1 and "n" or "m", false)
      end
    end
  else
    vim.api.nvim_feedkeys(query, "n", false)
  end
end

function M.query(trigger, mode)
  if state.is_running then return end
  mode = mode or vim.api.nvim_get_mode().mode:sub(1, 1)
  local maps = get_mappings(mode)
  local query = term(trigger)
  local clues = collect_clues(query, maps)
  if #clues == 0 then return vim.api.nvim_feedkeys(query, "n", false) end

  state.is_running = true
  state.timer = vim.uv.new_timer()
  state.timer:start(180, 0, vim.schedule_wrap(function()
    if state.is_running and not (state.win and vim.api.nvim_win_is_valid(state.win)) then
      render(query, maps)
    end
  end))

  while state.is_running do
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or char == "" or char == "\27" or char == "\3" then
      close(); break
    end
    if state.timer then
      pcall(function()
        state.timer:stop(); state.timer:close()
      end)
      state.timer = nil
    end

    if char == "\127" or char == "\8" or char == term("<BS>") then
      if #query > #term(trigger) then
        query = pop_key(query, #term(trigger))
        render(query, maps)
      else
        close(); break
      end
    else
      local next_q = query .. char
      local next_clues = collect_clues(next_q, maps)
      if #next_clues == 0 then
        close()
        execute(next_q, maps)
        break
      else
        query = next_q
        render(query, maps)
      end
    end
  end
end

function M.setup(opts)
  local triggers = (opts and opts.triggers) or default_triggers
  for _, trig in ipairs(triggers) do
    for _, mode in ipairs({ "n", "x" }) do
      vim.keymap.set(mode, trig, function() M.query(trig, mode) end, { noremap = true, silent = true, desc = "Hints" })
    end
  end
  vim.api.nvim_create_user_command("Hints", function() M.query("<leader>", "n") end, { desc = "Key hints" })
end

return M
