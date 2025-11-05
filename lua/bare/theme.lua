local M = {}

local colors = {
  -- Catppuccin Mocha colors
  rosewater = "#f5e0dc",
  flamingo = "#f2cdcd",
  pink = "#f5c2e7",
  mauve = "#cba6f7",
  red = "#f38ba8",
  maroon = "#eba0ac",
  peach = "#fab387",
  yellow = "#f9e2af",
  green = "#a6e3a1",
  teal = "#94e2d5",
  sky = "#89dceb",
  sapphire = "#74c7ec",
  blue = "#89b4fa",
  lavender = "#b4befe",
  text = "#cdd6f4",
  subtext1 = "#bac2de",
  subtext0 = "#a6adc8",
  overlay2 = "#9399b2",
  overlay1 = "#7f849c",
  overlay0 = "#6c7086",
  surface2 = "#585b70",
  surface1 = "#45475a",
  surface0 = "#313244",
  base = "#1e1e2e",
  mantle = "#181825",
  crust = "#11111b",
  none = "NONE",
}

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  local highlights = {
    -- Basic UI
    Normal = { fg = colors.text, bg = colors.base },
    NormalNC = { fg = colors.text, bg = colors.base },
    Comment = { fg = colors.surface2, italic = true },

    -- Syntax
    Constant = { fg = colors.peach },
    String = { fg = colors.green },
    Character = { fg = colors.green },
    Number = { fg = colors.peach },
    Boolean = { fg = colors.peach },
    Float = { fg = colors.peach },
    Identifier = { fg = colors.mauve },
    Function = { fg = colors.blue },
    Statement = { fg = colors.mauve },
    Conditional = { fg = colors.mauve, italic = true },
    Repeat = { fg = colors.mauve, italic = true },
    Label = { fg = colors.mauve },
    Operator = { fg = colors.sky },
    Keyword = { fg = colors.sapphire, italic = true },
    Exception = { fg = colors.red },
    PreProc = { fg = colors.yellow },
    Include = { fg = colors.mauve },
    Define = { fg = colors.mauve },
    Macro = { fg = colors.mauve },
    PreCondit = { fg = colors.yellow },
    Type = { fg = colors.sapphire },
    StorageClass = { fg = colors.mauve },
    Structure = { fg = colors.mauve },
    Typedef = { fg = colors.mauve },
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
    NonText = { fg = colors.surface1 },
    NormalFloat = { fg = colors.text, bg = colors.base },
    FloatBorder = { fg = colors.blue, bg = colors.base },

    -- Status line and tabs
    StatusLine = { fg = colors.text, bg = colors.mantle },
    StatusLineNC = { fg = colors.surface2, bg = colors.mantle },
    TabLine = { bg = colors.mantle, fg = colors.overlay0 },
    TabLineFill = { bg = colors.crust },
    TabLineSel = { fg = colors.crust, bg = colors.blue },

    -- Visual mode
    Visual = { bg = colors.surface1 },
    VisualNOS = { bg = colors.surface1 },

    -- Search
    Search = { bg = colors.surface2, fg = colors.text },
    IncSearch = { bg = colors.peach, fg = colors.crust },
    CurSearch = { bg = colors.peach, fg = colors.crust },

    -- Pmenu
    Pmenu = { bg = colors.base, fg = colors.text },
    PmenuSel = { bg = colors.surface0, fg = colors.blue, bold = true, sp = colors.blue },
    PmenuSbar = { bg = colors.base },
    PmenuThumb = { bg = colors.blue },
    PmenuMatch = { fg = colors.peach, bg = colors.none, bold = true, sp = colors.peach },
    PmenuMatchSel = { fg = colors.peach, bg = colors.none, bold = true, sp = colors.peach },
    PmenuBorder = { fg = colors.teal, bg = colors.base },

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
    LspReferenceRead = { bg = colors.overlay0 },
    LspReferenceWrite = { bg = colors.overlay0 },

    -- Special
    Todo = { bg = colors.yellow, fg = colors.base },
    Underlined = { underline = true },
    Bold = { bold = true, fg = colors.text },
    Italic = { italic = true, fg = colors.text },

    -- Git
    diffAdded = { fg = colors.green },
    diffChanged = { fg = colors.yellow },
    diffRemoved = { fg = colors.red },
  }

  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
