local M = {}

local icons = {
	bash = { "", "#89e051" },
	c = { "", "#a8b9cc" },
	conf = { "", "#51a0cf" },
	cpp = { "", "#00599c" },
	css = { "", "#264de4" },
	csv = { "", "#50ad47" },
	default = { "", "#a8b9cc" },
	dockerfile = { "", "#2496ed" },
	gif = { "󰵸", "#a074c4" },
	gitignore = { "", "#f54d27" },
	go = { "", "#00add8" },
	gomod = { "󰕳", "#51a0cf" },
	gosum = { "󰕳", "#51a0cf" },
	gzip = { "", "#eca517" },
	html = { "", "#e34c26" },
	java = { "", "#e11f21" },
	javascript = { "", "#f7df1e" },
	javascriptreact = { "", "#61dafb" },
	jpeg = { "", "#a074c4" },
	jpg = { "󰈥", "#a074c4" },
	json = { "", "#cbcb41" },
	lock = { "", "#bbbbbb" },
	log = { "", "#51a0cf" },
	lua = { "󰢱", "#51a0cf" },
	markdown = { "󰂺", "#519aba" },
	mp4 = { "", "#a074c4" },
	nim = { "", "#ffe953" },
	pdf = { "󰈦", "#b30b00" },
	png = { "󰸭", "#a074c4" },
	python = { "", "#3776ab" },
	qml = { "", "#51a0cf" },
	ruby = { "", "#cc342d" },
	rust = { "", "#ef4c23" },
	sass = { "", "#cd6799" },
	scss = { "", "#cd6799" },
	sh = { "󰯁", "#89e051" },
	sql = { "", "#e38c00" },
	svg = { "󰜡", "#ffb13b" },
	tar = { "", "#eca517" },
	text = { "", "#89e051" },
	toml = { "", "#9c4221" },
	typescript = { "", "#3178c6" },
	typescriptreact = { "", "#61dafb" },
	typst = { "", "#239dad" },
	vim = { "", "#019833" },
	vue = { "", "#41b883" },
	xml = { "󰗀", "#e37933" },
	yaml = { "", "#cb171e" },
	zip = { "", "#eca517" },
}

local cache = {}
local defined = {}

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		defined = {}
	end,
})

function M.get(ft)
	local key = (ft and ft ~= "") and ft:lower() or "default"
	local item = icons[key] or icons.default
	local hl = cache[key]

	if not hl then
		hl = "FileIcon" .. key:gsub("^%l", string.upper):gsub("[^%w]", "")
		cache[key] = hl
	end

	if not defined[hl] then
		vim.api.nvim_set_hl(0, hl, { fg = item[2], bold = true })
		defined[hl] = true
	end

	return item[1], hl
end

function M.get_icon(ft)
	return (M.get(ft))
end

function M.get_hl(ft)
	return select(2, M.get(ft))
end

return M
