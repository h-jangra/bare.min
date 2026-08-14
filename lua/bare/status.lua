local M = {}

local api, fn = vim.api, vim.fn
local bg = "#232634"
local fg = "#c6d0f5"

local mode_colors = {
	N = "#8caaee",
	I = "#99d1db",
	V = "#ca9ee6",
	R = "#eebebe",
	C = "#e5c890",
	T = "#ea999c",
}

local function set_hl()
	api.nvim_set_hl(0, "StlBubble", { fg = fg, bg = bg })
	api.nvim_set_hl(0, "StlBubbleCap", { fg = bg, bg = "NONE" })
	api.nvim_set_hl(0, "StlAccent", { fg = "#81c8be", bg = bg })
	api.nvim_set_hl(0, "StlDiagErr", { fg = "#e78284", bg = bg, bold = true })
	api.nvim_set_hl(0, "StlDiagWarn", { fg = "#e5c890", bg = bg })

	for letter, color in pairs(mode_colors) do
		api.nvim_set_hl(0, "StlMode" .. letter, { fg = bg, bg = color, bold = true })
		api.nvim_set_hl(0, "StlCap" .. letter, { fg = color, bg = "NONE" })
	end
end

set_hl()

local modes = {
	n = "N",
	i = "I",
	v = "V",
	V = "V",
	["\22"] = "V",
	R = "R",
	c = "C",
	t = "T",
}

local cache = {}

local function get_git_branch(bufnr)
	local file = api.nvim_buf_get_name(bufnr)
	local dir = file ~= "" and vim.fs.dirname(file) or fn.getcwd()
	local root = vim.fs.root(dir, ".git")
	if not root then
		return ""
	end

	local git_dir = vim.fs.joinpath(root, ".git")
	local stat = vim.uv.fs_stat(git_dir)
	if not stat then
		return ""
	end

	if stat.type == "file" then
		local f = io.open(git_dir, "r")
		if f then
			local line = f:read("*l")
			f:close()
			local real_dir = line and line:match("^gitdir:%s*(.+)")
			if real_dir then
				git_dir = real_dir
			end
		end
	end

	local head_file = vim.fs.joinpath(git_dir, "HEAD")
	local f = io.open(head_file, "r")
	if not f then
		return ""
	end
	local line = f:read("*l")
	f:close()
	if not line then
		return ""
	end

	local branch = line:match("ref: refs/heads/(.+)") or line:sub(1, 7)
	return " " .. vim.trim(branch)
end

local function get_filesize(bufnr)
	local file = api.nvim_buf_get_name(bufnr or 0)
	local size = file ~= "" and fn.getfsize(file) or -1
	if size <= 0 then
		return ""
	end
	local units = { "B", "K", "M", "G" }
	local i = 1
	while size >= 1024 and i < #units do
		size = size / 1024
		i = i + 1
	end
	if i == 1 then
		return size .. "B"
	end
	return (string.format("%.1f%s", size, units[i]):gsub("%.0(%a)", "%1"))
end

local function get_lsp_name(bufnr)
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if #clients == 0 then
		return ""
	end
	local names = {}
	for i, client in ipairs(clients) do
		names[i] = client.name
	end
	return table.concat(names, ",")
end

local function update_cache(bufnr)
	bufnr = (bufnr and bufnr ~= 0) and bufnr or api.nvim_get_current_buf()
	if not api.nvim_buf_is_valid(bufnr) then
		return
	end
	local c = cache[bufnr] or {}
	c.git = get_git_branch(bufnr)
	c.size = get_filesize(bufnr)
	c.lsp = get_lsp_name(bufnr)
	cache[bufnr] = c
end

local function update_size(bufnr)
	bufnr = (bufnr and bufnr ~= 0) and bufnr or api.nvim_get_current_buf()
	if cache[bufnr] then
		cache[bufnr].size = get_filesize(bufnr)
	end
end

local function update_lsp(bufnr)
	bufnr = (bufnr and bufnr ~= 0) and bufnr or api.nvim_get_current_buf()
	if cache[bufnr] then
		cache[bufnr].lsp = get_lsp_name(bufnr)
	end
end

local function get_diag_status()
	local count = vim.diagnostic.count(0)
	local err = count[vim.diagnostic.severity.ERROR] or 0
	local warn = count[vim.diagnostic.severity.WARN] or 0
	local str = ""
	if err > 0 then
		str = str .. " %#StlDiagErr#󰅚 " .. err
	end
	if warn > 0 then
		str = str .. " %#StlDiagWarn#󰀦 " .. warn
	end
	return str
end

local function get_search_count()
	if vim.v.hlsearch ~= 1 or fn.getreg("/") == "" then
		return ""
	end
	local ok, res = pcall(fn.searchcount, { maxcount = 999, timeout = 50 })
	return (ok and res and res.total and res.total > 0) and string.format("%d/%d", res.current, res.total) or ""
end

local function get_macro()
	local reg = fn.reg_recording()
	return reg ~= "" and ("󰑋" .. reg) or ""
end

function M.statusline()
	local letter = modes[api.nvim_get_mode().mode] or "N"
	local bufnr = api.nvim_get_current_buf()
	local c = cache[bufnr]
	if not c then
		update_cache(bufnr)
		c = cache[bufnr] or {}
	end

	local file = fn.expand("%:~:.")
	file = file == "" and "Untitled" or (vim.bo.buftype == "terminal" and "Terminal" or file)
	local file_hl = vim.bo.modified and "%#StlAccent# " or "%#StlBubble# "

	local git = c.git or ""
	local hl = "StlMode" .. letter
	local cap = "StlCap" .. letter

	local left = "%#" .. cap .. "#%#" .. hl .. "#" .. letter .. " " .. file_hl .. file
	if git ~= "" then
		left = left .. " %#StlAccent#" .. git
	end
	left = left .. get_diag_status() .. "%#StlBubbleCap#"

	local macro, search, lsp, size = get_macro(), get_search_count(), (c.lsp or ""), (c.size or "")
	local right_parts = {}
	if macro ~= "" then
		table.insert(right_parts, "%#StlDiagWarn#" .. macro)
	end
	if search ~= "" then
		table.insert(right_parts, "%#StlBubble#" .. search)
	end
	if lsp ~= "" then
		table.insert(right_parts, "%#StlAccent#" .. lsp)
	end
	if size ~= "" then
		table.insert(right_parts, "%#StlBubble#" .. size)
	end

	local right = ""
	if #right_parts > 0 then
		right = "%#StlBubbleCap#" .. table.concat(right_parts, " ") .. " %#" .. hl .. "# %L%#" .. cap .. "#"
	else
		right = "%#" .. cap .. "#%#" .. hl .. "#%L%#" .. cap .. "#"
	end

	return left .. "%=" .. right
end

local augroup = api.nvim_create_augroup("StlCache", { clear = true })
local function redraw()
	vim.cmd.redrawstatus()
end

api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
	group = augroup,
	callback = function(args)
		update_cache(args.buf)
	end,
})
api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
	group = augroup,
	callback = function(args)
		update_size(args.buf)
	end,
})
api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
	group = augroup,
	callback = function(args)
		update_lsp(args.buf)
		redraw()
	end,
})
api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, { group = augroup, callback = redraw })
api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	group = augroup,
	callback = function()
		if vim.v.hlsearch == 1 then
			redraw()
		end
	end,
})
api.nvim_create_autocmd("BufWipeout", {
	group = augroup,
	callback = function(args)
		cache[args.buf] = nil
	end,
})
api.nvim_create_autocmd("ColorScheme", { group = augroup, callback = set_hl })

vim.o.statusline = "%!v:lua.require('bare.status').statusline()"

return M
