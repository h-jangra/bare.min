--[[
Usage:
local icons = require("bare.icons")
local icon, hl = icons.get(vim.bo.filetype)
-- In statusline: %#HighlightGroup#icon%*
-- In UI: vim.api.nvim_echo({{icon, hl}}, false, {})
]]

local M = {}

M.icons = {
  lua = { icon = "", color = "#51a0cf" },
  js = { icon = "", color = "#f7df1e" },
  javascript = { icon = "", color = "#f7df1e" },
  ts = { icon = "", color = "#3178c6" },
  typescript = { icon = "", color = "#3178c6" },
  py = { icon = "", color = "#3776ab" },
  python = { icon = "", color = "#3776ab" },
  java = { icon = "", color = "#e11f21" },
  c = { icon = "", color = "#a8b9cc" },
  cpp = { icon = "", color = "#00599c" },
  go = { icon = "", color = "#00add8" },
  rs = { icon = "", color = "#ef4c23" },
  rust = { icon = "", color = "#ef4c23" },
  html = { icon = "", color = "#e34c26" },
  css = { icon = "", color = "#264de4" },
  sh = { icon = "", color = "#89e051" },
  json = { icon = "", color = "#cbcb41" },
  toml = { icon = "", color = "#9c4221" },
  xml = { icon = "󰗀", color = "#e37933" },
  yaml = { icon = "", color = "#cb171e" },
  yml = { icon = "", color = "#cb171e" },
  md = { icon = "", color = "#519aba" },
  markdown = { icon = "", color = "#519aba" },
  vim = { icon = "", color = "#019833" },
  typst = { icon = "", color = "#239dad" },
  typ = { icon = "", color = "#239dad" },
  dockerfile = { icon = "", color = "#2496ed" },
  sql = { icon = "", color = "#e38c00" },
  png = { icon = "󰈟", color = "#a074c4" },
  jpg = { icon = "", color = "#a074c4" },
  jpeg = { icon = "", color = "#a074c4" },
  gif = { icon = "", color = "#a074c4" },
  svg = { icon = "󰜡", color = "#ffb13b" },
  zsh = { icon = "", color = "#89e051" },
  fish = { icon = "󰈺", color = "#4aae47" },
  bash = { icon = "󱆃", color = "#89e051" },
  gitignore = { icon = "", color = "#f54d27" },
  git = { icon = "", color = "#f54d27" },
  txt = { icon = "", color = "#89e051" },
  csv = { icon = "", color = "#50ad47" },
  lock = { icon = "", color = "#bbbbbb" },
  pdf = { icon = "󰈦", color = "#b30b00" },
  zip = { icon = "", color = "#eca517" },
  tar = { icon = "", color = "#eca517" },
  gz = { icon = "", color = "#eca517" },
  rb = { icon = "", color = "#cc342d" },
  ruby = { icon = "", color = "#cc342d" },
  php = { icon = "", color = "#8993be" },
  swift = { icon = "", color = "#f05138" },
  kt = { icon = "", color = "#7f52ff" },
  kotlin = { icon = "", color = "#7f52ff" },
  dart = { icon = "", color = "#0175c2" },
  vue = { icon = "", color = "#41b883" },
  react = { icon = "", color = "#61dafb" },
  jsx = { icon = "", color = "#61dafb" },
  tsx = { icon = "", color = "#61dafb" },
  scss = { icon = "", color = "#cd6799" },
  sass = { icon = "", color = "#cd6799" },
  less = { icon = "", color = "#1d365d" },
  r = { icon = "󰟔", color = "#2266ba" },
  default = { icon = "󰈤", color = "#6d8086" },
}

local hl_cache = {}

local function setup_highlights()
  for ft, data in pairs(M.icons) do
    local hl_name = "FileIcon" .. ft:gsub("^%l", string.upper):gsub("[^%w]", "")

    vim.api.nvim_set_hl(0, hl_name, { fg = data.color, bold = true })

    hl_cache[ft] = hl_name
  end
end

setup_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    setup_highlights()
  end,
})

function M.get(ft)
  local data = M.icons[ft] or M.icons.default
  local hl = hl_cache[ft] or hl_cache.default
  return data.icon, hl
end

function M.get_icon(ft)
  local data = M.icons[ft] or M.icons.default
  return data.icon
end

function M.get_hl(ft)
  return hl_cache[ft] or hl_cache.default
end

function M.get_colored(ft)
  local icon, hl = M.get(ft)
  return string.format("%%#%s#%s%%*", hl, icon)
end

function M.get_color(ft)
  local data = M.icons[ft] or M.icons.default
  return data.color
end

function M.add(ft, icon, color)
  M.icons[ft] = { icon = icon, color = color }

  local hl_name = "FileIcon" .. ft:gsub("^%l", string.upper):gsub("[^%w]", "")
  vim.api.nvim_set_hl(0, hl_name, { fg = color, bold = true })
  hl_cache[ft] = hl_name
end

return M
