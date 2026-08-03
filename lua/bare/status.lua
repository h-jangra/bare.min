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

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return (ok and hl) and hl or {}
end

local function get_stl_bg()
  local tab = get_hl("TabLine")
  if tab.bg and tab.bg ~= 0 then return tab.bg end
  local stl = get_hl("StatusLine")
  if stl.bg and stl.bg ~= 0 then return stl.bg end
  local float = get_hl("NormalFloat")
  if float.bg and float.bg ~= 0 then return float.bg end
  local cur = get_hl("CursorLine")
  if cur.bg and cur.bg ~= 0 then return cur.bg end
  return get_hl("Normal").bg or 0x1e1e2e
end

local function contrast_fg(bg_color, dark_fg, light_fg)
  if not bg_color or bg_color == 0 then return light_fg end
  local r = bit.rshift(bit.band(bg_color, 0xFF0000), 16)
  local g = bit.rshift(bit.band(bg_color, 0x00FF00), 8)
  local b = bit.band(bg_color, 0x0000FF)
  local lum = (r * 299 + g * 587 + b * 114) / 1000
  return lum > 135 and dark_fg or light_fg
end

local function setup_highlights()
  local stl_bg = get_stl_bg()
  local norm = get_hl("Normal")
  local norm_fg = norm.fg or 0xcdd6f4

  local func = get_hl("Function")
  local git = get_hl("diffChanged")
  local warn = get_hl("DiagnosticSignWarn")
  local err = get_hl("DiagnosticSignError")
  local hint = get_hl("DiagnosticSignHint")
  local mod = get_hl("DiagnosticSignWarn")
  local comment = get_hl("Comment")

  vim.api.nvim_set_hl(0, "StatusLine", { fg = norm_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = norm_fg, bg = "NONE" })

  vim.api.nvim_set_hl(0, "StlText", { fg = norm_fg, bg = stl_bg })
  vim.api.nvim_set_hl(0, "StlGit", { fg = git.fg or warn.fg or norm_fg, bg = stl_bg })
  vim.api.nvim_set_hl(0, "StlLsp", { fg = func.fg or norm_fg, bg = stl_bg, bold = true })
  vim.api.nvim_set_hl(0, "StlFile", { fg = hint.fg or func.fg or norm_fg, bg = stl_bg })
  vim.api.nvim_set_hl(0, "StlFileModified", { fg = mod.fg or warn.fg or norm_fg, bg = stl_bg, bold = true })
  vim.api.nvim_set_hl(0, "StlDiagErr", { fg = err.fg or norm_fg, bg = stl_bg, bold = true })
  vim.api.nvim_set_hl(0, "StlDiagWarn", { fg = warn.fg or norm_fg, bg = stl_bg })
  vim.api.nvim_set_hl(0, "StlBubble", { fg = norm_fg, bg = stl_bg })
  vim.api.nvim_set_hl(0, "StlBubbleLeft", { fg = stl_bg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "StlBubbleRight", { fg = stl_bg, bg = "NONE" })

  for _, m in pairs(modes) do
    local suffix = m.letter:gsub("[^%w_]", "_")
    local mode_hl = get_hl(m.hl)
    local mode_color = mode_hl.fg or norm_fg
    local mode_text = contrast_fg(mode_color, stl_bg, norm_fg)

    vim.api.nvim_set_hl(0, "StlMode" .. suffix, { fg = mode_text, bg = mode_color, bold = true })
    vim.api.nvim_set_hl(0, "StlModeLeft" .. suffix, { fg = mode_color, bg = "NONE" })
    vim.api.nvim_set_hl(0, "StlModeRight" .. suffix, { fg = mode_color, bg = stl_bg })
    vim.api.nvim_set_hl(0, "StlModeEnd" .. suffix, { fg = mode_color, bg = "NONE" })
  end

  local unknown_color = comment.fg or norm_fg
  local unknown_text = contrast_fg(unknown_color, stl_bg, norm_fg)
  vim.api.nvim_set_hl(0, "StlModeUnknown", { fg = unknown_text, bg = unknown_color, bold = true })
end

setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })

local function get_git_branch()
  local file = vim.api.nvim_buf_get_name(0)
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

local function get_diag_status()
  local count = vim.diagnostic.count(0)
  local err = count[vim.diagnostic.severity.ERROR] or 0
  local warn = count[vim.diagnostic.severity.WARN] or 0
  local str = ""
  if err > 0 then str = str .. " %#StlDiagErr#󰅚 " .. err end
  if warn > 0 then str = str .. " %#StlDiagWarn#󰀦 " .. warn end
  return str
end

local function get_lsp_names()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return "" end
  local names = {}
  for _, c in ipairs(clients) do
    table.insert(names, c.name)
  end
  return "%#StlLsp#" .. table.concat(names, ", ")
end

local function get_file_size()
  local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
  if size <= 0 then
    return ""
  end

  local units = { "B", "K", "M", "G" }
  local i = 1
  while size >= 1024 and i < #units do
    size = size / 1024
    i = i + 1
  end

  return (" %%#StlFile#%.1f%s"):format(size, units[i])
end

_G.status_line = function()
  local mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[mode] or modes.n
  local hl_suffix = mode_info.letter:gsub("[^%w_]", "_")

  local file = vim.fn.expand("%:~:.")
  if file == "" then
    file = "[No Name]"
  elseif vim.bo.buftype == "terminal" then
    file = file:find("fzf") and "FZF" or "Floaterm"
  end
  local file_hl = vim.bo.modified and "%#StlFileModified#" or "%#StlText#"

  local sec_a =
      "%#StlModeLeft" .. hl_suffix .. "#" ..
      "%#StlMode" .. hl_suffix .. "# " .. mode_info.letter .. " " ..
      "%#StlModeRight" .. hl_suffix .. "#"

  local sec_b =
      "%#StlBubble#" ..
      file_hl ..
      file

  local git = get_git_branch()
  if git ~= "" then
    sec_b = sec_b .. "  %#StlGit#" .. git .. "%#StlBubble#"
  end

  sec_b = sec_b .. get_diag_status() .. " " .. "%#StlBubbleRight#"

  local sec_y = ""

  local lsp = get_lsp_names()
  if lsp ~= "" then sec_y = sec_y .. lsp end

  local size = get_file_size()
  if size ~= "" then sec_y = sec_y .. size end

  if sec_y ~= "" then
    sec_y = "%#StlBubbleLeft#" .. "%#StlBubble# " .. sec_y .. " %#StlBubbleRight#"
  end

  local sec_z =
      "%#StlModeLeft" .. hl_suffix .. "#" ..
      "%#StlModeRight" .. hl_suffix .. "# %l " ..
      "%#StlMode" .. hl_suffix .. "# %L" ..
      "%#StlModeEnd" .. hl_suffix .. "#"

  return table.concat({ sec_a, " ", sec_b, "%=", sec_y, sec_z, })
end

vim.o.statusline = "%!v:lua.status_line()"

vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  callback = function() vim.cmd("redrawstatus") end,
})
