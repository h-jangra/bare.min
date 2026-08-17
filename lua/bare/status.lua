local M = {}
local api, fn, fs = vim.api, vim.fn, vim.fs

local mode_colors = {
  N = "#88C0D0",
  I = "#ECEFF4",
  V = "#8FBCBB",
  R = "#a3be8c",
  C = "#b48ead",
  T = "#8FBCBB",
}

local modes = {
  n = "N",
  i = "I",
  v = "V",
  V = "V-L",
  ["\22"] = "V-B",
  R = "R",
  s = "S",
  c = "C",
  r = "R",
  t = "T",
}

local function set_hl()
  local bg = "#3B4252"
  local hl = api.nvim_set_hl
  hl(0, "StlBase", { fg = "#E5E9F0", bg = bg })
  hl(0, "StlModified", { fg = "#a3be8c", bg = bg, bold = true })
  hl(0, "StlGitBranch", { fg = "#88C0D0", bg = bg })
  hl(0, "StlLsp", { fg = "#8FBCBB", bg = bg })
  hl(0, "StlDiagErr", { fg = "#BF616A", bg = bg, bold = true })
  hl(0, "StlDiagWarn", { fg = "#EBCB8B", bg = bg })
  hl(0, "StlDiagInfo", { fg = "#88C0D0", bg = bg })
  hl(0, "StlDiagHint", { fg = "#8FBCBB", bg = bg })
  for m, color in pairs(mode_colors) do
    hl(0, "StlMode" .. m, { fg = bg, bg = color, bold = true })
  end
end
set_hl()

local function update_git_branch(buf)
  buf = (buf and buf ~= 0) and buf or api.nvim_get_current_buf()
  local file = api.nvim_buf_get_name(buf)
  local root = fs.root(file ~= "" and fs.dirname(file) or fn.getcwd(), ".git")
  if not root then
    vim.b[buf].git_branch = ""
    return
  end
  local path = fs.joinpath(root, ".git")
  local f = io.open(path, "r")
  if f then
    local line = f:read("*l")
    f:close()
    local gitdir = line and line:match("^gitdir:%s*(.+)")
    if gitdir then
      path = fs.isabs(gitdir) and gitdir or fs.normalize(fs.joinpath(root, gitdir))
    end
  end
  local hf = io.open(fs.joinpath(path, "HEAD"), "r")
  if not hf then
    vim.b[buf].git_branch = ""
    return
  end
  local line = hf:read("*l")
  hf:close()
  local branch = line and (line:match("ref: refs/heads/(.+)") or line:sub(1, 7))
  vim.b[buf].git_branch = branch and (" " .. branch) or ""
end

local function git_branch()
  if vim.b.git_branch == nil then update_git_branch(0) end
  return vim.b.git_branch or ""
end

local function lsp_names()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return "" end
  local names = {}
  for i, c in ipairs(clients) do names[i] = c.name end
  return table.concat(names, ", ")
end

local function get_diags()
  local c = vim.diagnostic.count(0)
  local parts = {}
  if (c[1] or 0) > 0 then parts[#parts + 1] = "%#StlDiagErr#󰅚 " .. c[1] end
  if (c[2] or 0) > 0 then parts[#parts + 1] = "%#StlDiagWarn#󰀦 " .. c[2] end
  if (c[3] or 0) > 0 then parts[#parts + 1] = "%#StlDiagInfo#󰋼 " .. c[3] end
  if (c[4] or 0) > 0 then parts[#parts + 1] = "%#StlDiagHint#󰌵 " .. c[4] end
  return table.concat(parts, " ")
end

local function get_search()
  if vim.v.hlsearch ~= 1 or fn.getreg("/") == "" then return "" end
  local ok, res = pcall(fn.searchcount, { maxcount = 999, timeout = 30 })
  return (ok and res and res.total and res.total > 0) and (res.current .. "/" .. res.total) or ""
end

function M.statusline()
  local mode_raw = api.nvim_get_mode().mode
  local mode = modes[mode_raw] or modes[mode_raw:sub(1, 1)] or "N"
  local hl = "StlMode" .. (mode_colors[mode] and mode or "N")

  local file = fn.expand("%:~:.")
  file = file == "" and "Untitled" or (vim.bo.buftype == "terminal" and "Terminal" or file)
  local file_hl = vim.bo.modified and "%#StlModified#" or "%#StlBase#"

  -- Left: Mode | File | Git | Diags
  local left = { string.format("%%#%s# %s %%#StlBase#", hl, mode), file_hl .. file }
  local git = git_branch()
  if git ~= "" then left[#left + 1] = "%#StlGitBranch#" .. git end
  local diags = get_diags()
  if diags ~= "" then left[#left + 1] = diags end

  -- Right: Macro | Search | LSP | Line count
  local right = {}
  local reg = fn.reg_recording()
  if reg ~= "" then right[#right + 1] = " %#StlDiagWarn#" .. reg end
  local s = get_search()
  if s ~= "" then right[#right + 1] = " %#StlBase#" .. s end
  local lsp = lsp_names()
  if lsp ~= "" then right[#right + 1] = " %#StlLsp#" .. lsp end

  local right_str = #right > 0
      and string.format("%%#StlBase#%s %%#%s# %%L ", table.concat(right, " "), hl)
      or string.format("%%#%s# %%L ", hl)

  return table.concat(left, " ") .. " %#StatusLine# %=" .. right_str
end

local grp = api.nvim_create_augroup("StlEvents", { clear = true })
local function redraw() vim.cmd.redrawstatus() end

api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged" }, {
  group = grp,
  callback = function(ev) update_git_branch(ev.buf) end,
})
api.nvim_create_autocmd({ "DiagnosticChanged", "LspAttach", "LspDetach", "RecordingEnter", "RecordingLeave" }, {
  group = grp,
  callback = redraw,
})
api.nvim_create_autocmd("ColorScheme", { group = grp, callback = set_hl })

vim.o.statusline = "%!v:lua.require('bare.status').statusline()"

return M
