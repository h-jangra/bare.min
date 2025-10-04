local icons = require("icons")

local modes = {
  n     = { fg = "#1e1e2e", bg = "#89b4fa", name = "NORMAL" },
  i     = { fg = "#1e1e2e", bg = "#a6e3a1", name = "INSERT" },
  v     = { fg = "#1e1e2e", bg = "#cba6f7", name = "VISUAL" },
  V     = { fg = "#1e1e2e", bg = "#cba6f7", name = "V-LINE" },
  [""] = { fg = "#1e1e2e", bg = "#cba6f7", name = "V-BLOCK" },
  R     = { fg = "#1e1e2e", bg = "#f38ba8", name = "REPLACE" },
  c     = { fg = "#1e1e2e", bg = "#f9e2af", name = "COMMAND" },
  t     = { fg = "#1e1e2e", bg = "#fab387", name = "TERMINAL" },
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
  set_hl("StlModified", "#f38ba8", "#313244", true) -- Modified file color
  set_hl("StlGit", "#f9e2af", "#313244")
  set_hl("StlSize", "#313244", "#cdd6f4")

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
