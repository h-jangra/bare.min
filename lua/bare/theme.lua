local M = {}

local colors = {
  base = "#24283b",
  mantle = "#1f2335",
  crust = "#1d202f",
  text = "#c0caf5",
  subtext1 = "#a9b1d6",
  overlay1 = "#565f89",
  overlay0 = "#3b4261",
  red = "#db4b4b",
  peach = "#ff9e64",
  yellow = "#e0af68",
  green = "#9ece6a",
  teal = "#1abc9c",
  sky = "#7dcfff",
  blue = "#7aa2f7",
  lavender = "#bb9af7",
  mauve = "#9d7cd8",
  surface0 = "#292e42",
  surface1 = "#363d59",
}

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  local highlights = {
    Normal = { fg = colors.text, bg = colors.base },
    NormalFloat = { fg = colors.text, bg = colors.base },
    FloatBorder = { fg = colors.blue, bg = colors.base },

    LineNr = { fg = colors.overlay0 },
    CursorLineNr = { fg = colors.peach, bold = true },
    CursorLine = { bg = colors.surface0 },

    SignColumn = { bg = colors.base, fg = colors.overlay0 },
    StatusLine = { fg = colors.subtext1, bg = colors.mantle },
    StatusLineNC = { fg = colors.overlay0, bg = colors.mantle },

    Search = { fg = colors.crust, bg = colors.yellow, bold = true },
    IncSearch = { fg = colors.crust, bg = colors.peach, bold = true },
    Visual = { bg = colors.surface1 },
    MatchParen = { fg = colors.peach, bg = colors.surface0, bold = true },

    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.peach },
    DiagnosticInfo = { fg = colors.sky },
    DiagnosticHint = { fg = colors.teal },

    Pmenu = { fg = colors.text, bg = colors.mantle },
    PmenuSel = { fg = colors.text, bg = colors.overlay0, bold = true },
    PmenuMatch = { fg = colors.teal, bg = colors.mantle },
    PmenuMatchSel = { fg = colors.teal, bg = colors.overlay0, bold = true },

    Comment = { fg = colors.overlay1, italic = true },
    String = { fg = colors.green },
    Constant = { fg = colors.peach },
    Number = { fg = colors.peach },
    Boolean = { fg = colors.peach, italic = true },
    Function = { fg = colors.blue, italic = true },
    Identifier = { fg = colors.lavender },
    Statement = { fg = colors.mauve, italic = true },
    Keyword = { fg = colors.sky, italic = true },
    Conditional = { fg = colors.mauve, italic = true },
    Operator = { fg = colors.sky },
    Type = { fg = colors.teal },
    Special = { fg = colors.teal },
    Error = { fg = colors.red, bold = true },
  }

  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
