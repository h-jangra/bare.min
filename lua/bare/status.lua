local M = {}

local modes = {
  n = { letter = "N", hl = "Function" },
  i = { letter = "I", hl = "String" },
  v = { letter = "V", hl = "Statement" },
  V = { letter = "V-L", hl = "Statement" },
  ["\22"] = { letter = "V-B", hl = "Statement" },
  R = { letter = "R", hl = "DiagnosticSignError" },
  c = { letter = "C", hl = "DiagnosticSignWarn" },
  t = { letter = "T", hl = "Constant" },
}

local cache = {}
local current_mode, stl_bg, norm_fg

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return (ok and hl) and hl or {}
end

local function update_mode_hl()
  local mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[mode] or modes.n
  if mode == current_mode then
    return mode_info
  end
  current_mode = mode
  local mode_hl = get_hl(mode_info.hl)
  local mode_color = mode_hl.fg or norm_fg
  vim.api.nvim_set_hl(0, "StlMode", { fg = stl_bg, bg = mode_color, bold = true })
  vim.api.nvim_set_hl(0, "StlModeCap", { fg = mode_color, bg = "NONE" })
  return mode_info
end

local function setup_highlights()
  local stl = get_hl("StatusLine")
  local norm = get_hl("Normal")
  stl_bg = stl.bg or norm.bg or 0x1e1e2e
  norm_fg = norm.fg or 0xcdd6f4

  local func = get_hl("Function")
  local git = get_hl("diffChanged")
  local warn = get_hl("DiagnosticSignWarn")
  local err = get_hl("DiagnosticSignError")

  vim.api.nvim_set_hl(0, "StatusLine", { fg = norm_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = norm_fg, bg = "NONE" })

  vim.api.nvim_set_hl(0, "StlBubble", { fg = norm_fg, bg = stl_bg })
  vim.api.nvim_set_hl(0, "StlBubbleCap", { fg = stl_bg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "StlAccent", { fg = git.fg or func.fg or warn.fg or norm_fg, bg = stl_bg })
  vim.api.nvim_set_hl(0, "StlDiagErr", { fg = err.fg or norm_fg, bg = stl_bg, bold = true })
  vim.api.nvim_set_hl(0, "StlDiagWarn", { fg = warn.fg or norm_fg, bg = stl_bg })

  current_mode = nil
  update_mode_hl()
end

local function get_git_branch(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local dir = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
  local root = vim.fs.root(dir, ".git")
  if not root then return "" end

  local git_dir = root .. "/.git"
  local stat = vim.uv.fs_stat(git_dir)
  if not stat then return "" end

  if stat.type == "file" then
    local f = io.open(git_dir, "r")
    if f then
      local line = f:read("*l")
      f:close()
      local real_dir = line and line:match("^gitdir:%s*(.+)")
      if real_dir then git_dir = real_dir end
    end
  end

  local f = io.open(git_dir .. "/HEAD", "r")
  if not f then return "" end
  local line = f:read("*l")
  f:close()
  if not line then return "" end

  local branch = line:match("ref: refs/heads/(.+)") or line:sub(1, 7)
  return " " .. vim.trim(branch)
end

local function get_lsp_name(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  return clients[1] and clients[1].name or ""
end

local function update_cache(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
  cache[bufnr] = cache[bufnr] or {}
  cache[bufnr].git = get_git_branch(bufnr)
  cache[bufnr].lsp = get_lsp_name(bufnr)
end

local function get_diag_status()
  local count = vim.diagnostic.count(0)
  local err = count[vim.diagnostic.severity.ERROR] or 0
  local warn = count[vim.diagnostic.severity.WARN] or 0
  local str = ""
  if err > 0 then str = str .. " %#StlDiagErr#󰅚 " .. err end
  if warn > 0 then str = str .. " %#StlDiagWarn#󰀦 " .. warn end
  return str
end

function M.statusline()
  local mode_info = modes[vim.api.nvim_get_mode().mode] or modes.n
  local bufnr = vim.api.nvim_get_current_buf()

  if not cache[bufnr] then
    update_cache(bufnr)
  end

  local file = vim.fn.expand("%:~:.")
  if file == "" then
    file = "Untitled"
  elseif vim.bo.buftype == "terminal" then
    file = "Terminal"
  end

  local file_hl = vim.bo.modified and " %#StlAccent#" or " %#StlBubble#"

  local sec_a = "%#StlModeCap#%#StlMode#" .. mode_info.letter .. " %#StlBubble#"
  local sec_b = file_hl .. file

  local buf_cache = cache[bufnr]
  if buf_cache.git ~= "" then
    sec_b = sec_b .. "  %#StlAccent#" .. buf_cache.git .. "%#StlBubble#"
  end

  sec_b = sec_b .. get_diag_status() .. "%#StlBubbleCap#"

  local sec_y = ""
  if buf_cache.lsp ~= "" then
    sec_y = "%#StlBubbleCap#%#StlBubble#%#StlAccent#" .. buf_cache.lsp .. " "
  end

  local sec_z = (buf_cache.lsp ~= "" and "%#StlMode#" or "%#StlModeCap#%#StlMode#") .. "%L%#StlModeCap#"

  return sec_a .. sec_b .. "%=" .. sec_y .. sec_z
end

setup_highlights()

local augroup = vim.api.nvim_create_augroup("StlCache", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = setup_highlights,
})

vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
  group = augroup,
  callback = function(args)
    update_cache(args.buf)
  end,
})

vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = augroup,
  callback = function(args)
    if cache[args.buf] then
      cache[args.buf].lsp = get_lsp_name(args.buf)
    else
      update_cache(args.buf)
    end
    vim.cmd.redrawstatus()
  end,
})

vim.api.nvim_create_autocmd("ModeChanged", {
  group = augroup,
  callback = function()
    update_mode_hl()
    vim.cmd.redrawstatus()
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = augroup,
  callback = function(args)
    cache[args.buf] = nil
  end,
})

vim.o.statusline = "%!v:lua.require('bare.status').statusline()"

return M
