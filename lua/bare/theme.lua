local M = {}

local colors = {
  rosewater = "#f2d5cf",
  flamingo  = "#eebebe",
  pink      = "#f4b8e4",
  mauve     = "#ca9ee6",
  red       = "#e78284",
  maroon    = "#ea999c",
  peach     = "#ef9f76",
  yellow    = "#e5c890",
  green     = "#a6d189",
  teal      = "#81c8be",
  sky       = "#99d1db",
  sapphire  = "#85c1dc",
  blue      = "#8caaee",
  lavender  = "#babbf1",
  text      = "#c6d0f5",
  subtext1  = "#b5bfe2",
  subtext0  = "#a5adce",
  overlay2  = "#949cbb",
  overlay1  = "#838ba7",
  overlay0  = "#737994",
  surface2  = "#626880",
  surface1  = "#51576d",
  surface0  = "#414559",
  base      = "#303446",
  mantle    = "#292c3c",
  crust     = "#232634",
  none      = "NONE",
}

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  local highlights = {
    -- Basic UI
    Normal = { fg = colors.text, bg = colors.base },
    NormalNC = { link = "Normal" },
    Comment = { fg = colors.surface2, italic = true },

    -- Syntax
    Constant = { fg = colors.peach },
    String = { fg = colors.green },
    Character = { link = "String" },
    Identifier = { fg = colors.mauve },
    Function = { fg = colors.blue },
    Statement = { fg = colors.mauve },
    Operator = { fg = colors.sky },
    Keyword = { fg = colors.sapphire },
    Exception = { fg = colors.red },
    PreProc = { fg = colors.yellow },
    Include = { fg = colors.mauve },
    Define = { link = "Include" },
    Macro = { link = "Include" },
    Type = { fg = colors.sapphire },
    StorageClass = { fg = colors.mauve },
    Structure = { link = "StorageClass" },
    Typedef = { link = "StorageClass" },
    Special = { fg = colors.sapphire },
    SpecialChar = { fg = colors.red },
    Tag = { fg = colors.peach },
    Delimiter = { fg = colors.subtext0 },
    SpecialComment = { fg = colors.surface2 },
    Debug = { fg = colors.red },

    -- UI elements
    LineNr = { fg = colors.overlay0 },
    CursorLineNr = { fg = colors.peach, bold = true },
    CursorLine = { bg = colors.surface0 },
    CursorColumn = { bg = colors.surface0 },
    ColorColumn = { bg = colors.crust },
    Conceal = { fg = colors.surface1 },
    Cursor = { fg = colors.base, bg = colors.text },
    Directory = { fg = colors.blue },
    EndOfBuffer = { fg = colors.base },
    ErrorMsg = { fg = colors.red },
    Folded = { fg = colors.blue, bg = colors.overlay0 },
    FoldColumn = { bg = colors.base, fg = colors.surface2 },
    SignColumn = { bg = colors.base, fg = colors.overlay0 },
    MatchParen = { fg = colors.peach, bold = true },
    NonText = { fg = colors.crust },
    NormalFloat = { fg = colors.text, bg = colors.base },
    FloatBorder = { fg = colors.blue, bg = colors.base },
    NotifyFloat = { fg = colors.text, bg = colors.mantle },
    NotifyFloatBorder = { fg = colors.blue, bg = colors.mantle },

    -- Status line and tabs
    StatusLine = { fg = colors.text, bg = colors.mantle },
    StatusLineNC = { fg = colors.surface2, bg = colors.mantle },
    TabLine = { bg = colors.mantle, fg = colors.overlay0 },
    TabLineFill = { bg = colors.crust },
    TabLineSel = { fg = colors.crust, bg = colors.blue },

    -- Visual mode & Search
    Visual = { bg = colors.surface1 },
    Search = { bg = colors.surface2, fg = colors.text },
    IncSearch = { bg = colors.peach, fg = colors.crust },
    CurSearch = { link = "IncSearch" },

    -- Pmenu
    Pmenu = { bg = colors.base, fg = colors.text },
    PmenuSel = { bg = colors.surface0, fg = colors.blue, bold = true, sp = colors.blue },
    PmenuSbar = { bg = colors.base },
    PmenuThumb = { bg = colors.blue },
    PmenuMatch = { fg = colors.peach, bold = true, sp = colors.peach },
    PmenuMatchSel = { link = "PmenuMatch" },
    PmenuBorder = { fg = colors.teal, bg = colors.base },
    PmenuShadow = { fg = colors.teal, bg = colors.base },

    -- Diagnostics
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.sapphire },
    DiagnosticHint = { fg = colors.teal },
    DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.sapphire },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.teal },

    -- LSP
    LspReferenceText = { bg = colors.overlay0 },
    LspGhostText = { fg = colors.surface2, italic = true },

    -- Special
    Todo = { bg = colors.yellow, fg = colors.base },
    Underlined = { underline = true },
    Bold = { bold = true, fg = colors.text },
    Italic = { italic = true, fg = colors.text },

    -- Git
    diffAdded = { fg = colors.green },
    diffChanged = { fg = colors.yellow },
    diffRemoved = { fg = colors.red },

    WinSeparator = { fg = colors.surface1 },
    FloatTitle = { fg = colors.blue, bold = true },
  }

  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
