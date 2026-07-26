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
  javascript = { icon = "", color = "#f7df1e" },
  typescript = { icon = "", color = "#3178c6" },
  python = { icon = "", color = "#3776ab" },
  java = { icon = "", color = "#e11f21" },
  c = { icon = "", color = "#a8b9cc" },
  cpp = { icon = "", color = "#00599c" },
  go = { icon = "", color = "#00add8" },
  gomod = { icon = "󰕳", color = "#51a0cf" },
  gosum = { icon = "󰕳", color = "#51a0cf" },
  rust = { icon = "", color = "#ef4c23" },
  html = { icon = "", color = "#e34c26" },
  css = { icon = "", color = "#264de4" },
  sh = { icon = "", color = "#89e051" },
  bash = { icon = "󱆃", color = "#89e051" },
  json = { icon = "", color = "#cbcb41" },
  toml = { icon = "", color = "#9c4221" },
  xml = { icon = "󰗀", color = "#e37933" },
  yaml = { icon = "", color = "#cb171e" },
  markdown = { icon = "", color = "#519aba" },
  vim = { icon = "", color = "#019833" },
  typst = { icon = "", color = "#239dad" },
  dockerfile = { icon = "", color = "#2496ed" },
  sql = { icon = "", color = "#e38c00" },
  png = { icon = "󰈟", color = "#a074c4" },
  jpg = { icon = "", color = "#a074c4" },
  jpeg = { icon = "", color = "#a074c4" },
  gif = { icon = "", color = "#a074c4" },
  svg = { icon = "󰜡", color = "#ffb13b" },
  gitignore = { icon = "", color = "#f54d27" },
  text = { icon = "", color = "#89e051" },
  csv = { icon = "", color = "#50ad47" },
  lock = { icon = "", color = "#bbbbbb" },
  pdf = { icon = "󰈦", color = "#b30b00" },
  zip = { icon = "", color = "#eca517" },
  tar = { icon = "", color = "#eca517" },
  gzip = { icon = "", color = "#eca517" },
  ruby = { icon = "", color = "#cc342d" },
  vue = { icon = "", color = "#41b883" },
  javascriptreact = { icon = "", color = "#61dafb" },
  typescriptreact = { icon = "", color = "#61dafb" },
  scss = { icon = "", color = "#cd6799" },
  sass = { icon = "", color = "#cd6799" },
  log = { icon = "", color = "#51a0cf" },
  default = { icon = "", color = "#a8b9cc" },
}

local aliases = {
  js = "javascript",
  ts = "typescript",
  py = "python",
  md = "markdown",
  yml = "yaml",
  typ = "typst",
  rs = "rust",
  rb = "ruby",
  jsx = "javascriptreact",
  react = "javascriptreact",
  tsx = "typescriptreact",
  txt = "text",
  git = "gitignore",
  mod = "gomod",
  sum = "gosum",
  gz = "gzip",
}

local defined_hls = {}

function M.get(ft)
  local raw_key = ft and ft:lower() or "default"
  local key = aliases[raw_key] or raw_key
  local data = M.icons[key] or M.icons.default

  local hl_name = "FileIcon" .. key:gsub("^%l", string.upper):gsub("[^%w]", "")

  if not defined_hls[hl_name] and data.color then
    vim.api.nvim_set_hl(0, hl_name, { fg = data.color, bold = true })
    defined_hls[hl_name] = true
  end

  return data.icon, hl_name
end

function M.get_icon(ft)
  local icon, _ = M.get(ft)
  return icon
end

function M.get_hl(ft)
  local _, hl = M.get(ft)
  return hl
end

return M
