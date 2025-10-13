local modes = {
  n     = { bg = "#1e1e2e", fg = "#89b4fa", name = "N" },
  i     = { bg = "#1e1e2e", fg = "#a6e3a1", name = "I" },
  v     = { bg = "#1e1e2e", fg = "#cba6f7", name = "V" },
  V     = { bg = "#1e1e2e", fg = "#cba6f7", name = "V-L" },
  [""] = { bg = "#1e1e2e", fg = "#cba6f7", name = "V-B" },
  R     = { bg = "#1e1e2e", fg = "#f38ba8", name = "R" },
  c     = { bg = "#1e1e2e", fg = "#f9e2af", name = "C" },
  t     = { bg = "#1e1e2e", fg = "#fab387", name = "T" },
}

local sep = { left = "", right = "" }

-- Set highlight group
local function set_hl(name, fg, bg, bold)
  local cmd = string.format("highlight %s guifg=%s guibg=%s", name, fg, bg)
  if bold then cmd = cmd .. " gui=bold" end
  vim.cmd(cmd)
end

-- Build statusline
_G.status_line = function()
  local mode_code = vim.api.nvim_get_mode().mode
  local mode = modes[mode_code] or { fg = "#1e1e2e", bg = "#6c7086", name = mode_code:upper() }

  -- Set dynamic highlights
  set_hl("StlMode", mode.fg, mode.bg, true)
  set_hl("StlModeAlt", mode.bg, "#313244")
  set_hl("StlNormal", "#cdd6f4", "#313244")
  set_hl("StlModified", "#f38ba8", "#313244", true)
  set_hl("StlGit", "#f9e2af", "#313244")
  set_hl("StlSize", "#a6e3a1", "#313244")
  set_hl("StlLsp", "#f38ba8", "#313244", true)

  -- File info
  local filename = vim.fn.fnamemodify(vim.fn.expand('%'), ':~:.')
  if filename == "" then filename = "[No Name]" end

  local file_hl = vim.bo.modified and "StlModified" or "StlNormal"
  if vim.bo.modified then filename = filename .. " ●" end

  -- LSP status indicator
  local function lsp_status()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if vim.tbl_isempty(clients) then
      return ""
    end

    -- Count diagnostics for the current buffer
    local function count_diag(severity)
      return #vim.diagnostic.get(0, { severity = severity })
    end

    local errors = count_diag(vim.diagnostic.severity.ERROR)
    local warnings = count_diag(vim.diagnostic.severity.WARN)

    local status_parts = {}

    if errors > 0 then
      table.insert(status_parts, string.format(" %d", errors))
    end
    if warnings > 0 then
      table.insert(status_parts, string.format(" %d", warnings))
    end

    -- Add LSP client names
    local names = vim.tbl_map(function(c) return c.name end, clients)
    table.insert(status_parts, table.concat(names, ", "))

    return "%#StlLsp# " .. table.concat(status_parts, " ")
  end

  -- Git branch
  local git = ""
  local branch = vim.fn.system("git branch --show-current 2>/dev/null")
  if branch and branch ~= "" then git = " " .. branch:gsub("\n", "") end

  -- File size
  local function get_file_size()
    local size = vim.fn.getfsize(vim.fn.expand('%:p'))
    if size <= 0 then return "0B" end
    local units = { "B", "KB", "MB", "GB" }
    local i = 1
    while size >= 1024 and i < 4 do
      size = size / 1024
      i = i + 1
    end
    return string.format(i == 1 and "%d%s" or "%.1f%s", size, units[i])
  end

  -- Position
  local line, col, total = vim.fn.line('.'), vim.fn.col('.'), vim.fn.line('$')
  local size = get_file_size()

  return table.concat({
    "%#StlMode#", " " .. mode.name .. " ",
    "%#StlModeAlt#", sep.right .. " ",
    "%#" .. file_hl .. "#", filename .. " ",
    git ~= "" and "%#StlGit#" .. git .. " " or "",
    "%=", -- right align
    lsp_status(),
    "%#StlNormal#", " " .. line .. ":" .. col .. " ",
    "%#StlSize#", " " .. size .. " ",
    "%#StlModeAlt#", sep.left,
    "%#StlMode#", " " .. total .. " ",
  })
end

vim.o.statusline = "%!v:lua.status_line()"
vim.api.nvim_create_autocmd("ModeChanged", {
  callback = function() vim.cmd("redrawstatus") end,
})
