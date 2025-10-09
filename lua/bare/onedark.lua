local M = {}

-- Color palette
local colors = {
	bg = "#282c34",
	bg_dark = "#21252b",
	bg_light = "#2c313c",
	fg = "#abb2bf",
	fg_dark = "#5c6370",

	red = "#e06c75",
	green = "#98c379",
	yellow = "#e5c07b",
	blue = "#61afef",
	purple = "#c678dd",
	cyan = "#56b6c2",
	orange = "#d19a66",

	gray = "#3e4452",
	gray_light = "#5c6370",

	-- UI colors
	cursor_line = "#2c323c",
	selection = "#3e4451",
	visual = "#3e4451",
	search = "#528bff",
	match_paren = "#5c6370",
}

-- Apply highlights
function M.setup()
	vim.cmd("hi clear")
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end

	vim.o.background = "dark"
	vim.g.colors_name = "onedark"

	local highlights = {
		-- UI Elements
		Normal = { fg = colors.fg, bg = colors.bg },
		NormalFloat = { fg = colors.fg, bg = colors.bg_dark },
		FloatBorder = { fg = colors.gray_light, bg = colors.bg_dark },
		CursorLine = { bg = colors.cursor_line },
		CursorLineNr = { fg = colors.yellow, bold = true },
		LineNr = { fg = colors.gray_light },
		SignColumn = { bg = colors.bg },
		VertSplit = { fg = colors.gray },
		StatusLine = { fg = colors.fg, bg = colors.bg_light },
		StatusLineNC = { fg = colors.gray_light, bg = colors.bg_light },
		TabLine = { fg = colors.gray_light, bg = colors.bg_light },
		TabLineFill = { bg = colors.bg_light },
		TabLineSel = { fg = colors.fg, bg = colors.bg },

		-- Search & Selection
		Visual = { bg = colors.visual },
		Search = { fg = colors.bg, bg = colors.yellow },
		IncSearch = { fg = colors.bg, bg = colors.orange },
		MatchParen = { fg = colors.cyan, bold = true, underline = true },

		-- Pmenu (completion menu)
		Pmenu = { fg = colors.fg, bg = colors.bg_light },
		PmenuSel = { fg = colors.bg, bg = colors.blue },
		PmenuSbar = { bg = colors.gray },
		PmenuThumb = { bg = colors.fg_dark },

		-- Syntax Groups
		Comment = { fg = colors.gray_light, italic = true },
		Constant = { fg = colors.cyan },
		String = { fg = colors.green },
		Character = { fg = colors.green },
		Number = { fg = colors.orange },
		Boolean = { fg = colors.orange },
		Float = { fg = colors.orange },

		Identifier = { fg = colors.red },
		Function = { fg = colors.blue },

		Statement = { fg = colors.purple },
		Conditional = { fg = colors.purple },
		Repeat = { fg = colors.purple },
		Label = { fg = colors.purple },
		Operator = { fg = colors.cyan },
		Keyword = { fg = colors.red },
		Exception = { fg = colors.purple },

		PreProc = { fg = colors.yellow },
		Include = { fg = colors.purple },
		Define = { fg = colors.purple },
		Macro = { fg = colors.purple },
		PreCondit = { fg = colors.yellow },

		Type = { fg = colors.yellow },
		StorageClass = { fg = colors.yellow },
		Structure = { fg = colors.yellow },
		Typedef = { fg = colors.yellow },

		Special = { fg = colors.blue },
		SpecialChar = { fg = colors.orange },
		Tag = { fg = colors.red },
		Delimiter = { fg = colors.fg },
		SpecialComment = { fg = colors.gray_light },
		Debug = { fg = colors.red },

		Underlined = { underline = true },
		Ignore = { fg = colors.gray },
		Error = { fg = colors.red, bold = true },
		Todo = { fg = colors.purple, bold = true },

		-- Diagnostics
		DiagnosticError = { fg = colors.red },
		DiagnosticWarn = { fg = colors.yellow },
		DiagnosticInfo = { fg = colors.blue },
		DiagnosticHint = { fg = colors.cyan },

		-- LSP
		["@variable"] = { fg = colors.red },
		["@variable.builtin"] = { fg = colors.red },
		["@parameter"] = { fg = colors.red },
		["@field"] = { fg = colors.red },
		["@property"] = { fg = colors.red },

		["@function"] = { fg = colors.blue },
		["@function.builtin"] = { fg = colors.cyan },
		["@method"] = { fg = colors.blue },
		["@constructor"] = { fg = colors.yellow },

		["@keyword"] = { fg = colors.purple },
		["@keyword.function"] = { fg = colors.purple },
		["@keyword.return"] = { fg = colors.purple },
		["@conditional"] = { fg = colors.purple },
		["@repeat"] = { fg = colors.purple },

		["@string"] = { fg = colors.green },
		["@number"] = { fg = colors.orange },
		["@boolean"] = { fg = colors.orange },
		["@constant"] = { fg = colors.cyan },
		["@constant.builtin"] = { fg = colors.orange },

		["@type"] = { fg = colors.yellow },
		["@type.builtin"] = { fg = colors.yellow },

		["@comment"] = { fg = colors.gray_light, italic = true },
		["@punctuation.bracket"] = { fg = colors.fg },
		["@punctuation.delimiter"] = { fg = colors.fg },

		-- Git
		DiffAdd = { fg = colors.green },
		DiffChange = { fg = colors.yellow },
		DiffDelete = { fg = colors.red },
		DiffText = { fg = colors.blue },

		GitSignsAdd = { fg = colors.green },
		GitSignsChange = { fg = colors.yellow },
		GitSignsDelete = { fg = colors.red },
	}

	-- Apply highlights
	for group, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

M.setup()

return M
