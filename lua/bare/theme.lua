-- tokyonight-night color Palette
local M = {}

local colors = {
  bg = "#1a1b26",
  bg_dark = "#16161e",
  bg_highlight = "#292e42",
  bg_visual = "#283457",
  bg_search = "#3d59a1",
  fg = "#c0caf5",
  fg_dark = "#a9b1d6",
  fg_gutter = "#3b4261",
  blue = "#7aa2f7",
  blue1 = "#2ac3de",
  blue5 = "#89ddff",
  cyan = "#7dcfff",
  green = "#9ece6a",
  magenta = "#bb9af7",
  orange = "#ff9e64",
  red = "#f7768e",
  yellow = "#e0af68",
  comment = "#565f89",
  dark3 = "#545c7e",
  terminal_black = "#414868",
  error = "#db4b4b",
  warning = "#e0af68",
  info = "#0db9d7",
  hint = "#1abc9c",
  none = "NONE",
  black = "#000000",
}

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  local highlights = {
    -- Basic UI
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalNC = { fg = colors.fg, bg = colors.bg },
    Comment = { fg = colors.comment, italic = true },

    -- Syntax
    Constant = { fg = colors.orange },
    String = { fg = colors.green },
    Character = { fg = colors.green },
    Number = { fg = colors.orange },
    Boolean = { fg = colors.orange },
    Float = { fg = colors.orange },
    Identifier = { fg = colors.magenta },
    Function = { fg = colors.blue },
    Statement = { fg = colors.magenta },
    Conditional = { fg = colors.magenta, italic = true },
    Repeat = { fg = colors.magenta, italic = true },
    Label = { fg = colors.magenta },
    Operator = { fg = colors.blue5 },
    Keyword = { fg = colors.cyan, italic = true },
    Exception = { fg = colors.red },
    PreProc = { fg = colors.yellow },
    Include = { fg = colors.magenta },
    Define = { fg = colors.magenta },
    Macro = { fg = colors.magenta },
    PreCondit = { fg = colors.yellow },
    Type = { fg = colors.blue1 },
    StorageClass = { fg = colors.magenta },
    Structure = { fg = colors.magenta },
    Typedef = { fg = colors.magenta },
    Special = { fg = colors.blue1 },
    SpecialChar = { fg = colors.red },
    Tag = { fg = colors.orange },
    Delimiter = { fg = colors.fg_dark },
    SpecialComment = { fg = colors.comment },
    Debug = { fg = colors.red },

    -- UI elements
    LineNr = { fg = colors.fg_gutter },
    CursorLineNr = { fg = colors.orange, bold = true },
    CursorLine = { bg = colors.bg_highlight },
    CursorColumn = { bg = colors.bg_highlight },
    ColorColumn = { bg = colors.black },
    Conceal = { fg = colors.dark3 },
    Cursor = { fg = colors.bg, bg = colors.fg },
    Directory = { fg = colors.blue },
    EndOfBuffer = { fg = colors.bg },
    ErrorMsg = { fg = colors.error },
    Folded = { fg = colors.blue, bg = colors.fg_gutter },
    FoldColumn = { bg = colors.bg, fg = colors.comment },
    SignColumn = { bg = colors.bg, fg = colors.fg_gutter },
    MatchParen = { fg = colors.orange, bold = true },
    NonText = { fg = colors.dark3 },

    -- Status line and tabs
    StatusLine = { fg = colors.fg, bg = colors.bg_dark },
    StatusLineNC = { fg = colors.comment, bg = colors.bg_dark },
    TabLine = { bg = colors.bg_dark, fg = colors.fg_gutter },
    TabLineFill = { bg = colors.black },
    TabLineSel = { fg = colors.black, bg = colors.blue },

    -- Visual mode
    Visual = { bg = colors.bg_visual },
    VisualNOS = { bg = colors.bg_visual },

    -- Search
    Search = { bg = colors.bg_search, fg = colors.fg },
    IncSearch = { bg = colors.orange, fg = colors.black },
    CurSearch = { bg = colors.orange, fg = colors.black },

    -- Pmenu
    Pmenu = { bg = colors.bg_dark, fg = colors.fg },
    PmenuSel = { bg = colors.fg_gutter },
    PmenuSbar = { bg = colors.bg_dark },
    PmenuThumb = { bg = colors.fg_gutter },
    PmenuMatch = { fg = colors.hint, bg = colors.bg_dark },
    PmenuMatchSel = { fg = colors.hint, bg = colors.fg_gutter, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = colors.error },
    DiagnosticWarn = { fg = colors.warning },
    DiagnosticInfo = { fg = colors.info },
    DiagnosticHint = { fg = colors.hint },
    DiagnosticUnderlineError = { undercurl = true, sp = colors.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.warning },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.info },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.hint },

    -- LSP
    LspReferenceText = { bg = colors.fg_gutter },
    LspReferenceRead = { bg = colors.fg_gutter },
    LspReferenceWrite = { bg = colors.fg_gutter },

    -- Special
    Todo = { bg = colors.yellow, fg = colors.bg },
    Underlined = { underline = true },
    Bold = { bold = true, fg = colors.fg },
    Italic = { italic = true, fg = colors.fg },

    -- Git
    diffAdded = { fg = "#449dab" },
    diffChanged = { fg = "#6183bb" },
    diffRemoved = { fg = "#914c54" },
  }

  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
