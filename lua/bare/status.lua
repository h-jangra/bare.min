local icons = require("bare.icons")

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
  set_hl("StlSize", "#f38ba8", "#313244")

  -- File info
  local filename = vim.fn.expand('%:t')
  if filename == "" then filename = "[No Name]" end

  local file_hl = vim.bo.modified and "StlModified" or "StlNormal"
  if vim.bo.modified then filename = filename .. " ●" end

  local icon = icons.get(vim.bo.filetype) or ""

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
    "%#" .. file_hl .. "#", icon .. " " .. filename .. " ",
    git ~= "" and "%#StlGit#" .. git .. " " or "",
    "%=", -- right align
    "%#StlNormal#", " " .. line .. ":" .. col .. " ",
    "%#StlSize#", " " .. size .. " ",
    "%#StlModeAlt#", sep.left,
    "%#StlMode#", " " .. total .. " ",
  })
end

-- Set statusline
vim.o.statusline = "%!v:lua.status_line()"

-- Refresh on mode change
vim.api.nvim_create_autocmd("ModeChanged", {
  callback = function() vim.cmd("redrawstatus") end,
})
