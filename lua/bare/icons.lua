local M = {}

M.icons = {
  lua = "",
  js = "",
  ts = "",
  py = "",
  java = "",
  c = "",
  cpp = "",
  go = "",
  rs = "",
  html = "",
  css = "",
  sh = "",
  json = "",
  toml = "",
  xml = "",
  yaml = "",
  md = "",
  vim = "",
  typ = "",
  dockerfile = "",
  sql = "",

  png = "󰸭",
  jpg = "󰈥",
  zsh = "",
  fish = "",
  bash = "",
  gitignore = "",
  txt = "",
  csv = "𝄜",
  lock = "",
  pdf = "",
  default = "🗎",
}

function M.get(ft)
  return M.icons[ft] or M.icons.default
end

return M
