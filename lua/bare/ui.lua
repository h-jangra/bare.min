local M = {}

local function content_width(lines)
	local width = 0
	for _, line in ipairs(lines or {}) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end
	return width
end

function M.float(opts)
	opts = opts or {}

	local buf = opts.buf
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		buf = vim.api.nvim_create_buf(false, true)
	end

	local width = opts.width or content_width(opts.lines)
	local height = opts.height or math.floor(vim.o.lines * 0.6)

	if width == 0 then
		width = math.floor(vim.o.columns * 0.8)
	end

	local cfg = {
		relative = opts.relative or "editor",
		style = opts.style or "minimal",
		border = opts.border or "rounded",
		title = opts.title,
		title_pos = opts.title and (opts.title_pos or "center") or nil,
		width = width,
		height = height,
		row = opts.row or math.floor((vim.o.lines - height) / 3),
		col = opts.col or math.floor((vim.o.columns - width) / 2),
		focusable = opts.focusable,
		zindex = opts.zindex,
	}

	if opts.win and vim.api.nvim_win_is_valid(opts.win) then
		vim.api.nvim_win_set_config(opts.win, cfg)
		return buf, opts.win
	end

	return buf, vim.api.nvim_open_win(buf, opts.enter ~= false, cfg)
end

return M
