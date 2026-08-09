local M = {}

local function entry(icon, color)
  return { icon = icon, color = color }
end

local icons = {
  lua = entry("", "#51a0cf"),
  javascript = entry("", "#f7df1e"),
  typescript = entry("", "#3178c6"),
  python = entry("", "#3776ab"),
  java = entry("", "#e11f21"),
  c = entry("", "#a8b9cc"),
  cpp = entry("", "#00599c"),
  go = entry("", "#00add8"),
  gomod = entry("󰕳", "#51a0cf"),
  gosum = entry("󰕳", "#51a0cf"),
  rust = entry("", "#ef4c23"),
  html = entry("", "#e34c26"),
  css = entry("", "#264de4"),
  sh = entry("", "#89e051"),
  bash = entry("󱆃", "#89e051"),
  json = entry("", "#cbcb41"),
  toml = entry("", "#9c4221"),
  xml = entry("󰗀", "#e37933"),
  yaml = entry("", "#cb171e"),
  markdown = entry("", "#519aba"),
  vim = entry("", "#019833"),
  typst = entry("", "#239dad"),
  dockerfile = entry("", "#2496ed"),
  sql = entry("", "#e38c00"),
  png = entry("󰈟", "#a074c4"),
  jpg = entry("", "#a074c4"),
  jpeg = entry("", "#a074c4"),
  gif = entry("", "#a074c4"),
  mp4 = entry("", "#a074c4"),
  svg = entry("󰜡", "#ffb13b"),
  gitignore = entry("", "#f54d27"),
  text = entry("", "#89e051"),
  csv = entry("", "#50ad47"),
  lock = entry("", "#bbbbbb"),
  pdf = entry("󰈦", "#b30b00"),
  zip = entry("", "#eca517"),
  tar = entry("", "#eca517"),
  gzip = entry("", "#eca517"),
  ruby = entry("", "#cc342d"),
  vue = entry("", "#41b883"),
  javascriptreact = entry("", "#61dafb"),
  typescriptreact = entry("", "#61dafb"),
  scss = entry("", "#cd6799"),
  sass = entry("", "#cd6799"),
  log = entry("", "#51a0cf"),
  qml = entry("", "#51a0cf"),
  default = entry("", "#a8b9cc"),
}

-- Precompute highlight
for key, data in pairs(icons) do
  data.hl = "FileIcon" .. key:gsub("^%l", string.upper):gsub("[^%w]", "")
end

-- Aliases reference
for alias, target in pairs({
  js = "javascript", ts = "typescript", py = "python", md = "markdown", yml = "yaml",
  typ = "typst", rs = "rust", rb = "ruby", jsx = "javascriptreact", react = "javascriptreact",
  tsx = "typescriptreact", txt = "text", git = "gitignore", mod = "gomod", sum = "gosum", gz = "gzip",
}) do
  icons[alias] = icons[target]
end

M.icons = icons

local hl_cache = {}
local defined_hls = {}

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function() defined_hls = {} end,
})

function M.get(ft)
  local key = ft and ft:lower() or "default"
  local data = icons[key]
  local hl

  if data then
    hl = data.hl
  else
    data = icons.default
    hl = hl_cache[key]
    if not hl then
      hl = "FileIcon" .. key:gsub("^%l", string.upper):gsub("[^%w]", "")
      hl_cache[key] = hl
    end
  end

  if not defined_hls[hl] and data.color then
    vim.api.nvim_set_hl(0, hl, { fg = data.color, bold = true })
    defined_hls[hl] = true
  end

  return data.icon, hl
end

function M.get_icon(ft) return (M.get(ft)) end

function M.get_hl(ft) return select(2, M.get(ft)) end

return M
