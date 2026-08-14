local M = {}

M.config = { blur = true }

local colors = {
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

function M.setup(opts)
	if opts then
		M.config = vim.tbl_deep_extend("force", M.config, opts)
	end

	vim.cmd("hi clear")
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end

	local blur = M.config.blur
	local bg_base = blur and colors.none or colors.base
	local bg_mantle = blur and colors.none or colors.mantle
	local bg_crust = blur and colors.none or colors.crust

	local highlights = {
		-- Basic UI
		Normal = { fg = colors.text, bg = bg_base },
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
		LineNr = { fg = colors.overlay0, bg = colors.none },
		CursorLineNr = { fg = colors.peach, bold = true, bg = colors.none },
		CursorLine = { bg = colors.surface0 },
		CursorColumn = { bg = colors.surface0 },
		ColorColumn = { bg = colors.crust },
		Conceal = { fg = colors.surface1 },
		Cursor = { fg = colors.base, bg = colors.text },
		Directory = { fg = colors.blue },
		EndOfBuffer = { fg = colors.base, bg = bg_base },
		ErrorMsg = { fg = colors.red },
		Folded = { fg = colors.blue, bg = colors.overlay0 },
		FoldColumn = { bg = bg_base, fg = colors.surface2 },
		SignColumn = { bg = bg_base, fg = colors.overlay0 },
		MatchParen = { fg = colors.peach, bold = true },
		NonText = { fg = colors.crust },
		NormalFloat = { fg = colors.text, bg = bg_base },
		FloatBorder = { fg = colors.blue, bg = bg_base },
		NotifyFloat = { fg = colors.text, bg = colors.mantle },
		NotifyFloatBorder = { fg = colors.blue, bg = colors.mantle },

		-- Status line and tabs
		StatusLine = { fg = colors.text, bg = bg_mantle },
		StatusLineNC = { fg = colors.surface2, bg = bg_mantle },
		TabLine = { bg = bg_mantle, fg = colors.overlay0 },
		TabLineFill = { bg = bg_crust },
		TabLineSel = { fg = colors.crust, bg = colors.blue },

		-- Visual mode & Search
		Visual = { bg = colors.surface1 },
		Search = { bg = colors.surface2, fg = colors.text },
		IncSearch = { bg = colors.peach, fg = colors.crust },
		CurSearch = { link = "IncSearch" },

		-- Pmenu
		Pmenu = { bg = bg_base, fg = colors.text },
		PmenuSel = { bg = colors.surface0, fg = colors.blue, bold = true, sp = colors.blue },
		PmenuSbar = { bg = bg_base },
		PmenuThumb = { bg = colors.blue },
		PmenuMatch = { fg = colors.peach, bold = true, sp = colors.peach },
		PmenuMatchSel = { link = "PmenuMatch" },
		PmenuBorder = { fg = colors.teal, bg = bg_base },
		PmenuShadow = { fg = colors.teal, bg = bg_base },

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

	for group, hl_opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, hl_opts)
	end
end

function M.toggle_blur()
	M.config.blur = not M.config.blur
	M.setup()
end

return M
