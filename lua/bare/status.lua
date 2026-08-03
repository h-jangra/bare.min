local modes = {
  n = { letter = "N", color = "#89b4fa" },
  i = { letter = "I", color = "#a6e3a1" },
  v = { letter = "V", color = "#cba6f7" },
  V = { letter = "V-L", color = "#cba6f7" },
  ["\22"] = { letter = "V-B", color = "#cba6f7" },
  R = { letter = "R", color = "#f38ba8" },
  c = { letter = "C", color = "#f9e2af" },
  t = { letter = "T", color = "#fab387" },
}

local function setup_highlights()
  vim.api.nvim_set_hl(0, "StatusLine", { fg = "#c6c6c6", bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = "#c6c6c6", bg = "NONE" })
  vim.api.nvim_set_hl(0, "StlText", { fg = "#cdd6f4", bg = "#292c3c" })
  vim.api.nvim_set_hl(0, "StlGit", { fg = "#f9e2af", bg = "#292c3c" })
  vim.api.nvim_set_hl(0, "StlLsp", { fg = "#89b4fa", bg = "#292c3c", bold = true })
  vim.api.nvim_set_hl(0, "StlFile", { fg = "#94e2d5", bg = "#292c3c" })
  vim.api.nvim_set_hl(0, "StlFileModified", { fg = "#f2cdcd", bg = "#292c3c", bold = true })
  vim.api.nvim_set_hl(0, "StlDiagErr", { fg = "#f38ba8", bg = "#292c3c", bold = true })
  vim.api.nvim_set_hl(0, "StlDiagWarn", { fg = "#f9e2af", bg = "#292c3c" })
  vim.api.nvim_set_hl(0, "StlBubble", { fg = "#cdd6f4", bg = "#292c3c", })
  vim.api.nvim_set_hl(0, "StlBubbleLeft", { fg = "#292c3c", bg = "NONE", })
  vim.api.nvim_set_hl(0, "StlBubbleRight", { fg = "#292c3c", bg = "NONE", })

  for _, m in pairs(modes) do
    local suffix = m.letter:gsub("[^%w_]", "_")
    vim.api.nvim_set_hl(0, "StlMode" .. suffix, { fg = "#292c3c", bg = m.color, bold = true })
    vim.api.nvim_set_hl(0, "StlModeLeft" .. suffix, { fg = m.color, bg = "NONE", })
    vim.api.nvim_set_hl(0, "StlModeRight" .. suffix, { fg = m.color, bg = "#292c3c", })
    vim.api.nvim_set_hl(0, "StlModeEnd" .. suffix, { fg = m.color, bg = "NONE", })
  end
  vim.api.nvim_set_hl(0, "StlModeUnknown", { fg = "#292c3c", bg = "#6c7086", bold = true })
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
