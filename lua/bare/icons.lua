--[[
local icons = require("bare.icons")
local icon = icons.get(vim.bo.filetype) or ""
]]

local M = {}

M.icons = {
  lua = "",
  js = "",
  javascript = "",
  ts = "",
  typescript = "",
  py = "",
  python = "",
  java = "",
  c = "",
  cpp = "",
  go = "",
  rs = "",
  html = "",
  css = "",
  sh = "",
  json = "",
  toml = "",
  xml = "",
  yaml = "",
  md = " ",
  markdown = " ",
  vim = "",
  typst = "",
  typ = "",
  dockerfile = "",
  sql = "",

  png = "󰈟",
  jpg = "",
  zsh = "",
  fish = "󰈺",
  bash = "󱆃",
  gitignore = "",
  txt = "",
  csv = "",
  lock = "",
  pdf = "󰈦",
  default = "󰈤",
}

function M.get(ft)
  return M.icons[ft] or M.icons.default
end

return M
