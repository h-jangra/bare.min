local M = {}

vim.g.bare_theme = vim.g.bare_theme or "frappe"

local frappe = {
  rosewater = "#f2d5cf",
  flamingo = "#eebebe",
  pink = "#f4b8e4",
  mauve = "#ca9ee6",
  red = "#e78284",
  maroon = "#ea999c",
  peach = "#ef9f76",
  yellow = "#e5c890",
  green = "#a6d189",
  teal = "#81c8be",
  sky = "#99d1db",
  sapphire = "#85c1dc",
  blue = "#8caaee",
  lavender = "#babbf1",
  text = "#c6d0f5",
  subtext1 = "#b5bfe2",
  subtext0 = "#a5adce",
  overlay2 = "#949cbb",
  overlay1 = "#838ba7",
  overlay0 = "#737994",
  surface2 = "#626880",
  surface1 = "#51576d",
  surface0 = "#414559",
  base = "#303446",
  mantle = "#292c3c",
  crust = "#232634",
  none = "NONE",
}

local mocha = {
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

local nord = {
  rosewater = "#e5e9f0",
  flamingo = "#d08770",
  pink = "#b48ead",
  mauve = "#b48ead",
  red = "#bf616a",
  maroon = "#d08770",
  peach = "#d08770",
  yellow = "#ebcb8b",
  green = "#a3be8c",
  teal = "#8fbcbb",
  sky = "#88c0d0",
  sapphire = "#81a1c1",
  blue = "#5e81ac",
  lavender = "#81a1c1",
  text = "#eceff4",
  subtext1 = "#e5e9f0",
  subtext0 = "#d8dee9",
  overlay2 = "#8fbcbb",
  overlay1 = "#7886a0",
  overlay0 = "#616e88",
  surface2 = "#4c566a",
  surface1 = "#434c5e",
  surface0 = "#3b4252",
  base = "#2e3440",
  mantle = "#2b303c",
  crust = "#242933",
  none = "NONE",
}

local tokyonight = {
  rosewater = "#a9b1d6",
  flamingo = "#ff9e64",
  pink = "#f7768e",
  mauve = "#bb9af7",
  red = "#f7768e",
  maroon = "#ff9e64",
  peach = "#ff9e64",
  yellow = "#e0af68",
  green = "#9ece6a",
  teal = "#73daca",
  sky = "#b4f9f8",
  sapphire = "#2ac3de",
  blue = "#7aa2f7",
  lavender = "#7aa2f7",
  text = "#c0caf5",
  subtext1 = "#a9b1d6",
  subtext0 = "#9aa5ce",
  overlay2 = "#7dcfff",
  overlay1 = "#737aa2",
  overlay0 = "#565f89",
  surface2 = "#414868",
  surface1 = "#2f3549",
  surface0 = "#24283b",
  base = "#1a1b26",
  mantle = "#16161e",
  crust = "#13141c",
  none = "NONE",
}

local gruvbox = {
  rosewater = "#d5c4a1",
  flamingo = "#fe8019",
  pink = "#d3869b",
  mauve = "#d3869b",
  red = "#fb4934",
  maroon = "#fe8019",
  peach = "#fe8019",
  yellow = "#fabd2f",
  green = "#b8bb26",
  teal = "#8ec07c",
  sky = "#83a598",
  sapphire = "#83a598",
  blue = "#458588",
  lavender = "#83a598",
  text = "#ebdbb2",
  subtext1 = "#d5c4a1",
  subtext0 = "#bdae93",
  overlay2 = "#a89984",
  overlay1 = "#928374",
  overlay0 = "#7c6f64",
  surface2 = "#665c54",
  surface1 = "#504945",
  surface0 = "#3c3836",
  base = "#282828",
  mantle = "#1d2021",
  crust = "#141617",
  none = "NONE",
}

local kanagawa = {
  rosewater = "#dcd7ba",
  flamingo = "#ffa066",
  pink = "#d27e99",
  mauve = "#957fb8",
  red = "#c34043",
  maroon = "#e82424",
  peach = "#ffa066",
  yellow = "#e6c384",
  green = "#98bb6c",
  teal = "#7aa89f",
  sky = "#7e9cd8",
  sapphire = "#7e9cd8",
  blue = "#7e9cd8",
  lavender = "#938aa9",
  text = "#dcd7ba",
  subtext1 = "#c8c093",
  subtext0 = "#a3d4d5",
  overlay2 = "#7e9cd8",
  overlay1 = "#8a8980",
  overlay0 = "#727169",
  surface2 = "#54546d",
  surface1 = "#363646",
  surface0 = "#2a2a37",
  base = "#1f1f28",
  mantle = "#16161d",
  crust = "#121217",
  none = "NONE",
}

local palettes = {
  frappe = frappe,
  mocha = mocha,
  nord = nord,
  tokyonight = tokyonight,
  gruvbox = gruvbox,
  kanagawa = kanagawa,
}

function M.setup()
  local colors = palettes[vim.g.bare_theme or "frappe"] or frappe

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
    Conditional = { fg = colors.mauve },
    Repeat = { fg = colors.mauve },
    Label = { fg = colors.mauve },
    Operator = { fg = colors.sky },
    Keyword = { fg = colors.sapphire },
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
    PmenuShadow = { fg = colors.teal, bg = colors.base },

    -- Diagnostics
    DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.sapphire },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.teal },

    DiagnosticVirtualTextError = { fg = colors.red, bg = colors.none },
    DiagnosticVirtualTextWarn = { fg = colors.yellow, bg = colors.none },
    DiagnosticVirtualTextInfo = { fg = colors.sapphire, bg = colors.none },
    DiagnosticVirtualTextHint = { fg = colors.teal, bg = colors.none },

    DiagnosticSignError = { fg = colors.red },
    DiagnosticSignWarn = { fg = colors.yellow },
    DiagnosticSignInfo = { fg = colors.sapphire },
    DiagnosticSignHint = { fg = colors.teal },

    -- LSP
    LspReferenceText = { bg = colors.overlay0 },
    LspReferenceRead = { bg = colors.overlay0 },
    LspReferenceWrite = { bg = colors.overlay0 },
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
