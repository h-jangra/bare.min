local M = {}
local api, fn, fs, uv = vim.api, vim.fn, vim.fs, vim.uv or vim.loop

local bg, fg = "#232634", "#c6d0f5"
local mode_colors = {
  N = "#8caaee",
  I = "#99d1db",
  V = "#ca9ee6",
  R = "#eebebe",
  C = "#e5c890",
  T = "#ea999c",
}

local modes = {
  n = "N",
  i = "I",
  v = "V",
  V = "V",
  ["\22"] = "V",
  s = "S",
  S = "S",
  ["\19"] = "S",
  R = "R",
  c = "C",
  r = "R",
  ["!"] = "!",
  t = "T",
}

local diag_types = {
  { vim.diagnostic.severity.ERROR, "%#StlDiagErr#󰅚 " },
  { vim.diagnostic.severity.WARN, "%#StlDiagWarn#󰀦 " },
  { vim.diagnostic.severity.INFO, "%#StlDiagInfo#󰋼 " },
  { vim.diagnostic.severity.HINT, "%#StlDiagHint#󰌵 " },
}

local function set_hl()
  api.nvim_set_hl(0, "StlBase", { fg = fg, bg = bg })
  api.nvim_set_hl(0, "StlCap", { fg = bg, bg = "NONE" })
  api.nvim_set_hl(0, "StlModified", { fg = "#ef9f76", bg = bg, bold = true })
  api.nvim_set_hl(0, "StlGitBranch", { fg = "#ca9ee6", bg = bg })
  api.nvim_set_hl(0, "StlLsp", { fg = "#81c8be", bg = bg })
  api.nvim_set_hl(0, "StlDiagErr", { fg = "#e78284", bg = bg, bold = true })
  api.nvim_set_hl(0, "StlDiagWarn", { fg = "#e5c890", bg = bg })
  api.nvim_set_hl(0, "StlDiagInfo", { fg = "#85c1dc", bg = bg })
  api.nvim_set_hl(0, "StlDiagHint", { fg = "#99d1db", bg = bg })

  for k, color in pairs(mode_colors) do
    api.nvim_set_hl(0, "StlMode" .. k, { fg = bg, bg = color, bold = true })
    api.nvim_set_hl(0, "StlModeCap" .. k, { fg = color, bg = "NONE" })
  end
end
set_hl()

local cache = {}

local function get_git_branch(bufnr)
  local file = api.nvim_buf_get_name(bufnr)
  local root = fs.root(file ~= "" and fs.dirname(file) or fn.getcwd(), ".git")
  if not root then return "" end

  local git_dir = fs.joinpath(root, ".git")
  local stat = uv.fs_stat(git_dir)
  if not stat then return "" end

  if stat.type == "file" then
    local f = io.open(git_dir, "r")
    if f then
      local line = f:read("*l")
      f:close()
      git_dir = line and line:match("^gitdir:%s*(.+)") or git_dir
      if not fs.isabs(git_dir) then
        git_dir = fs.normalize(fs.joinpath(root, git_dir))
      end
    end
  end

  local f = io.open(fs.joinpath(git_dir, "HEAD"), "r")
  if not f then return "" end
  local line = f:read("*l")
  f:close()
  if not line then return "" end

  local branch = line:match("ref: refs/heads/(.+)") or line:sub(1, 7)
  return branch and (" " .. vim.trim(branch)) or ""
end

local function get_filesize(bufnr)
  local file = api.nvim_buf_get_name(bufnr)
  if file == "" then return "" end
  local stat = uv.fs_stat(file)
  if not stat or not stat.size or stat.size <= 0 then return "" end
  local size, units, i = stat.size, { "B", "K", "M", "G" }, 1
  while size >= 1024 and i < #units do
    size, i = size / 1024, i + 1
  end
  return string.format(i == 1 and "%dB" or "%.1f%s", size, units[i]):gsub("%.0(%a)", "%1")
end

local function get_lsp(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then return "" end
  local names = {}
  for i, c in ipairs(clients) do names[i] = c.name end
  return table.concat(names, ", ")
end

local function update_cache(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(bufnr) then return end
  cache[bufnr] = {
    git = get_git_branch(bufnr),
    size = get_filesize(bufnr),
    lsp = get_lsp(bufnr),
  }
end

local function get_diags(bufnr)
  local counts = vim.diagnostic.count(bufnr)
  local out = {}
  for _, d in ipairs(diag_types) do
    local n = counts[d[1]]
    if n and n > 0 then
      out[#out + 1] = d[2] .. n
    end
  end
  return table.concat(out, " ")
end

local function get_search()
  if vim.v.hlsearch ~= 1 or fn.getreg("/") == "" then return "" end
  local ok, res = pcall(fn.searchcount, { maxcount = 999, timeout = 50 })
  return (ok and res and res.total and res.total > 0) and string.format("%d/%d", res.current, res.total) or ""
end

function M.statusline()
  local mode_raw = api.nvim_get_mode().mode
  local mode = modes[mode_raw] or modes[mode_raw:sub(1, 1)] or "N"
  local bufnr = api.nvim_get_current_buf()
  local c = cache[bufnr]
  if not c then
    update_cache(bufnr)
    c = cache[bufnr] or {}
  end

  local file = fn.expand("%:~:.")
  file = file == "" and "Untitled" or (vim.bo.buftype == "terminal" and "Terminal" or file)
  local file_hl = vim.bo.modified and "%#StlModified#" or "%#StlBase#"

  -- Left: Mode pill | File | Git | Diags
  local left_parts = { file_hl .. file }
  if c.git and c.git ~= "" then
    left_parts[#left_parts + 1] = "%#StlGitBranch#" .. c.git
  end
  local diags = get_diags(bufnr)
  if diags ~= "" then
    left_parts[#left_parts + 1] = diags
  end

  local left = string.format("%%#StlModeCap%s#%%#StlMode%s#%s %%#StlBase# %s %%#StlCap#",
    mode, mode, mode, table.concat(left_parts, " "))

  -- Right: Macro | Search | LSP / Progress | Size | Line count
  local right_parts = {}
  local reg = fn.reg_recording()
  if reg ~= "" then
    right_parts[#right_parts + 1] = "%#StlDiagWarn#󰑋 " .. reg
  end
  local s = get_search()
  if s ~= "" then
    right_parts[#right_parts + 1] = "%#StlBase#" .. s
  end
  local prog = (vim.ui.progress_status and vim.ui.progress_status())
      or (vim.lsp.status and vim.lsp.status())
      or ""
  if prog ~= "" then
    right_parts[#right_parts + 1] = "%#StlLsp#" .. prog
  elseif c.lsp and c.lsp ~= "" then
    right_parts[#right_parts + 1] = "%#StlLsp#" .. c.lsp
  end
  if c.size and c.size ~= "" then
    right_parts[#right_parts + 1] = "%#StlBase#" .. c.size
  end

  local right = ""
  if #right_parts > 0 then
    right = string.format("%%#StlCap#%%#StlBase#%s %%#StlMode%s# %%L%%#StlModeCap%s#",
      table.concat(right_parts, " "), mode, mode)
  else
    right = string.format("%%#StlModeCap%s#%%#StlMode%s#%%L%%#StlModeCap%s#",
      mode, mode, mode)
  end

  return left .. "%=" .. right
end

local grp = api.nvim_create_augroup("StlEvents", { clear = true })
local function redraw()
  vim.cmd.redrawstatus()
end

api.nvim_create_autocmd({ "BufEnter", "DirChanged", "BufWritePost", "BufReadPost" }, {
  group = grp,
  callback = function(a) update_cache(a.buf) end,
})
api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = grp,
  callback = function(a)
    if cache[a.buf] then cache[a.buf].lsp = get_lsp(a.buf) end
    redraw()
  end,
})
api.nvim_create_autocmd({ "DiagnosticChanged", "LspProgress", "RecordingEnter", "RecordingLeave" }, {
  group = grp,
  callback = redraw,
})
api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  group = grp,
  callback = function()
    if vim.v.hlsearch == 1 then redraw() end
  end,
})
api.nvim_create_autocmd("BufWipeout", {
  group = grp,
  callback = function(a) cache[a.buf] = nil end,
})
api.nvim_create_autocmd("ColorScheme", { group = grp, callback = set_hl })

vim.o.statusline = "%!v:lua.require('bare.status').statusline()"

return M
