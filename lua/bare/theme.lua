local M = {}

-- Minimal Catppuccin-inspired palette (Mocha variant)
local colors = {
  -- Base
  base = "#1e1e2e",
  mantle = "#181825",
  crust = "#11111b",

  -- Text
  text = "#cdd6f4",
  subtext1 = "#bac2de",
  subtext0 = "#a6adc8",

  -- Accents (minimal set)
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

  -- UI
  surface0 = "#313244",
  surface1 = "#45475a",
  overlay0 = "#6c7086",
  overlay1 = "#7f849c"
}

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.o.background = "dark"
  vim.g.colors_name = "catppuccin_minimal"

  local highlights = {
    -- Core UI
    Normal = { fg = colors.text, bg = colors.base },
    NormalFloat = { fg = colors.text, bg = colors.mantle },
    FloatBorder = { fg = colors.overlay0, bg = colors.mantle },

    -- Line numbers
    LineNr = { fg = colors.overlay0 },
    CursorLineNr = { fg = colors.lavender, bold = true },
    CursorLine = { bg = colors.surface0 },

    -- Status and tabs
    StatusLine = { fg = colors.text, bg = colors.surface0 },
    StatusLineNC = { fg = colors.overlay0, bg = colors.surface0 },
    TabLine = { fg = colors.overlay0, bg = colors.surface0 },
    TabLineSel = { fg = colors.lavender, bg = colors.base, bold = true },

    -- Visual elements
    Visual = { bg = colors.surface1 },
    Search = { fg = colors.base, bg = colors.yellow },
    IncSearch = { fg = colors.base, bg = colors.peach },
    MatchParen = { fg = colors.green, bold = true },

    -- Completion
    Pmenu = { bg = colors.mantle },
    PmenuSel = { bg = colors.surface0, bold = true },
    PmenuThumb = { bg = colors.overlay0 },

    -- Syntax - minimal Catppuccin style
    Comment = { fg = colors.overlay0, italic = true },

    -- Strings and values
    String = { fg = colors.green },
    Character = { fg = colors.green },
    Number = { fg = colors.peach },
    Boolean = { fg = colors.peach },
    Float = { fg = colors.peach },

    -- Functions
    Function = { fg = colors.blue },
    Identifier = { fg = colors.text },

    -- Keywords and control flow
    Keyword = { fg = colors.mauve },
    Statement = { fg = colors.mauve },
    Conditional = { fg = colors.mauve },
    Repeat = { fg = colors.mauve },
    Operator = { fg = colors.sky },

    -- Types
    Type = { fg = colors.blue },
    StorageClass = { fg = colors.mauve },

    -- Special
    Special = { fg = colors.yellow },
    Tag = { fg = colors.peach },
    Delimiter = { fg = colors.subtext0 },

    -- Errors and todos
    Error = { fg = colors.red },
    Todo = { fg = colors.mauve, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.blue },
    DiagnosticHint = { fg = colors.teal },

    -- Minimal tree-sitter (Catppuccin style)
    ["@function"] = { fg = colors.blue },
    ["@function.builtin"] = { fg = colors.lavender },
    ["@method"] = { fg = colors.blue },
    ["@constructor"] = { fg = colors.sapphire },

    ["@variable"] = { fg = colors.text },
    ["@variable.builtin"] = { fg = colors.peach },
    ["@parameter"] = { fg = colors.maroon },
    ["@field"] = { fg = colors.lavender },
    ["@property"] = { fg = colors.lavender },

    ["@keyword"] = { fg = colors.mauve },
    ["@keyword.function"] = { fg = colors.mauve },
    ["@conditional"] = { fg = colors.mauve },
    ["@repeat"] = { fg = colors.mauve },

    ["@string"] = { fg = colors.green },
    ["@string.escape"] = { fg = colors.teal },
    ["@number"] = { fg = colors.peach },
    ["@boolean"] = { fg = colors.peach },
    ["@constant"] = { fg = colors.yellow },
    ["@constant.builtin"] = { fg = colors.peach },

    ["@type"] = { fg = colors.blue },
    ["@type.builtin"] = { fg = colors.sapphire },

    ["@comment"] = { fg = colors.overlay0, italic = true },
    ["@punctuation.delimiter"] = { fg = colors.subtext0 },
    ["@punctuation.bracket"] = { fg = colors.subtext0 },

    -- Git
    DiffAdd = { fg = colors.green },
    DiffChange = { fg = colors.yellow },
    DiffDelete = { fg = colors.red },

    GitSignsAdd = { fg = colors.green },
    GitSignsChange = { fg = colors.yellow },
    GitSignsDelete = { fg = colors.red },

    -- UI extras
    VertSplit = { fg = colors.surface0 },
    WinSeparator = { fg = colors.surface0 },
    Folded = { fg = colors.overlay0, bg = colors.mantle },
    SignColumn = { bg = colors.base },
  }

  -- Apply highlights
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
