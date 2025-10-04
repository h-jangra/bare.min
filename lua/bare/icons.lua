
local M = {}

M.icons = {
  lua = "",
  javascript = "",
  typescript = "",
  python = "",
  java = "",
  c = "",
  cpp = "",
  go = "",
  rust = "",
  html = "",
  css = "",
  sh = "",
  json = "",
  toml = "",
  xml = "",
  yaml = "",
  markdown = "",
  vim = "",
  typst = "",
  dockerfile = "",
  sql = "",

  zsh = "",
  fish = "",
  bash = "",
  gitignore = "",
  txt = "",
  csv = "",
  lock = "",
  pdf = "",
  default = "",
}

-- helper function
function M.get(ft)
  return M.icons[ft] or M.icons.default
end

return M
