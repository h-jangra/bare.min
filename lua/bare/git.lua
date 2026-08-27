local M = {}
local ui = require("bare.ui")

local api = vim.api
local DEBOUNCE_MS, MAX_LINES, SIGN_PRIORITY = 120, 10000, 10

M.SIGNS = {
	Add = { text = "▎", sym = "+", fg = "#a6d189", hl = "BareGitAdd" },
	Change = { text = "▎", sym = "~", fg = "#85c1dc", hl = "BareGitChange" },
	Delete = { text = "", sym = "-", fg = "#e78284", hl = "BareGitDelete" },
	Untracked = { text = "▎", sym = "?", fg = "#81c8be", hl = "BareGitUntracked" },
	Renamed = { text = "▎", sym = "→", fg = "#ca9ee6", hl = "BareGitRenamed" },
	Ignored = { text = "▎", sym = "!", fg = "#626880", hl = "BareGitIgnored" },
}

local ns = api.nvim_create_namespace("bare_git")
local bufs = {}

local function resolve_buf(buf)
	return (buf and buf ~= 0) and buf or api.nvim_get_current_buf()
end

local function hunk_line(h)
	return (h.new_count == 0) and math.max(1, h.new_start) or h.new_start
end

local function get_buf(buf)
	bufs[buf] = bufs[buf] or { ver = 0, hunks = {} }
	return bufs[buf]
end

local function get_info(buf)
	buf = resolve_buf(buf)
	if not api.nvim_buf_is_valid(buf) then
		return nil
	end
	local file = api.nvim_buf_get_name(buf)
	if file == "" or vim.bo[buf].buftype ~= "" then
		return nil
	end
	local ok, root = pcall(vim.fs.root, file, ".git")
	if not ok or not root then
		return nil
	end
	local rel = vim.fs.relpath(root, file)
	if not rel then
		return nil
	end
	return { buf = buf, file = file, root = root, rel = rel }
end

function M.set_hl()
	for name, s in pairs(M.SIGNS) do
		api.nvim_set_hl(0, s.hl, { fg = s.fg, bold = (name ~= "Ignored"), italic = (name == "Ignored") })
	end
	api.nvim_set_hl(0, "BareFilesDir", { default = true, link = "Directory" })
	api.nvim_set_hl(0, "BareFilesFile", { default = true, link = "Normal" })
	api.nvim_set_hl(0, "BareFilesHidden", { default = true, link = "Comment" })
end

M.set_hl()

local function parse_status_output(stdout, root)
	local map = {}
	for line in stdout:gmatch("[^\r\n]+") do
		local x, y = line:sub(1, 1), line:sub(2, 2)
		local p = line:sub(4):match(" %-> (.+)$") or line:sub(4)
		local full = vim.fs.normalize(vim.fs.joinpath(root, (p:gsub('^"', ""):gsub('"$', ""))))

		local sym, hl, status = "~", "BareGitChange", "modified"
		if x == "?" or y == "?" then
			sym, hl, status = "?", "BareGitUntracked", "untracked"
		elseif x == "A" or y == "A" then
			sym, hl, status = "+", "BareGitAdd", "added"
		elseif x == "D" or y == "D" then
			sym, hl, status = "-", "BareGitDelete", "deleted"
		elseif x == "R" or y == "R" then
			sym, hl, status = "→", "BareGitRenamed", "renamed"
		elseif x == "U" or y == "U" then
			sym, hl, status = "U", "BareGitDelete", "conflict"
		end

		map[full] = { sym = sym, hl = hl, status = status }

		local cur = full
		while cur and #cur > #root do
			cur = vim.fs.dirname(cur)
			if cur and cur ~= root and not map[cur] then
				map[cur] = { sym = "•", hl = "BareGitChange", status = "modified_child" }
			end
		end
	end
	return map
end

function M.status(dir)
	dir = dir and vim.fs.normalize(dir) or vim.fn.getcwd()
	local ok, root = pcall(vim.fs.root, dir, ".git")
	if not ok or not root then
		return {}
	end

	local res = vim.system({ "git", "-C", root, "status", "--porcelain=v1", "-uall" }, { text = true }):wait()
	if res.code ~= 0 or not res.stdout or res.stdout == "" then
		return {}
	end
	return parse_status_output(res.stdout, root)
end

function M.status_async(dir, cb)
	dir = dir and vim.fs.normalize(dir) or vim.fn.getcwd()
	local ok, root = pcall(vim.fs.root, dir, ".git")
	if not ok or not root then
		if cb then
			cb({})
		end
		return
	end

	vim.system({ "git", "-C", root, "status", "--porcelain=v1", "-uall" }, { text = true }, function(res)
		vim.schedule(function()
			if res.code ~= 0 or not res.stdout or res.stdout == "" then
				if cb then
					cb({})
				end
				return
			end
			if cb then
				cb(parse_status_output(res.stdout, root))
			end
		end)
	end)
end

M.get_status = M.status

local function clear(buf)
	if api.nvim_buf_is_valid(buf) then
		api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	end
end

local function parse_hunks(diff_str)
	local hunks = {}
	local current = nil
	for line in (diff_str or ""):gmatch("[^\r\n]+") do
		local os, oc, ns_start, nc = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
		if os then
			if current then
				table.insert(hunks, current)
			end
			current = {
				old_start = tonumber(os),
				old_count = tonumber(oc) or 1,
				new_start = tonumber(ns_start),
				new_count = tonumber(nc) or 1,
				header = line:match("^(@@ .- @@)") or line,
				lines = {},
				removed = {},
			}
		elseif current then
			table.insert(current.lines, line)
			if line:sub(1, 1) == "-" then
				table.insert(current.removed, line:sub(2))
			end
		end
	end
	if current then
		table.insert(hunks, current)
	end
	return hunks
end

local function apply_hunks(buf, hunks)
	local total = api.nvim_buf_line_count(buf)
	for _, h in ipairs(hunks) do
		local sign, count, start = M.SIGNS.Change, math.max(h.old_count, h.new_count), h.new_start
		if h.new_count == 0 then
			sign, count, start = M.SIGNS.Delete, 1, math.max(h.new_start, 1)
		elseif h.old_count == 0 then
			sign, count = M.SIGNS.Add, h.new_count
		end

		for i = 0, count - 1 do
			local lnum = start + i - 1
			if lnum >= 0 and lnum < total then
				api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
					sign_text = sign.text,
					sign_hl_group = sign.hl,
					priority = SIGN_PRIORITY,
				})
			end
		end
	end
end

local function find_hunk(buf, lnum)
	local b = bufs[buf]
	if not b or not b.hunks or #b.hunks == 0 then
		return nil
	end
	lnum = lnum or api.nvim_win_get_cursor(0)[1]
	local adjacent = nil
	for _, h in ipairs(b.hunks) do
		local s = hunk_line(h)
		local e = (h.new_count == 0) and s or (s + h.new_count - 1)
		if
			(h.new_count == 0 and (lnum == h.new_start or lnum == h.new_start + 1 or (h.new_start == 0 and lnum == 1)))
			or (h.new_count > 0 and lnum >= s and lnum <= e)
		then
			return h
		end
		if not adjacent and (math.abs(lnum - s) <= 1 or math.abs(lnum - e) <= 1) then
			adjacent = h
		end
	end
	return adjacent
end

function M.update(buf, cb)
	buf = resolve_buf(buf)
	if not api.nvim_buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) then
		return
	end

	local info = get_info(buf)
	if not info or api.nvim_buf_line_count(buf) > MAX_LINES then
		clear(buf)
		if cb then
			cb({})
		end
		return
	end

	local b = get_buf(buf)
	b.ver = b.ver + 1
	local ver = b.ver

	vim.system(
		{ "git", "-C", info.root, "diff", "--no-ext-diff", "--unified=0", "--", info.rel },
		{ text = true },
		function(res)
			vim.schedule(function()
				if not bufs[buf] or not api.nvim_buf_is_valid(buf) or ver ~= b.ver then
					return
				end
				local diff = res.stdout or ""
				b.hunks = parse_hunks(diff)
				clear(buf)
				if diff ~= "" then
					apply_hunks(buf, b.hunks)
				end
				if cb then
					cb(b.hunks)
				end
			end)
		end
	)
end

function M.revert_hunk(buf, lnum)
	buf = resolve_buf(buf)
	lnum = lnum or api.nvim_win_get_cursor(0)[1]
	local hunk = find_hunk(buf, lnum)
	if not hunk then
		vim.notify("No git hunk at cursor", vim.log.levels.WARN)
		return
	end

	if hunk.new_count == 0 then
		local idx = math.max(0, hunk.new_start)
		api.nvim_buf_set_lines(buf, idx, idx, false, hunk.removed)
	elseif hunk.old_count == 0 then
		local s = math.max(0, hunk.new_start - 1)
		local e = hunk.new_start + hunk.new_count - 1
		api.nvim_buf_set_lines(buf, s, e, false, {})
	else
		local s = math.max(0, hunk.new_start - 1)
		local e = hunk.new_start + hunk.new_count - 1
		api.nvim_buf_set_lines(buf, s, e, false, hunk.removed)
	end

	vim.notify("Reverted hunk at line " .. lnum, vim.log.levels.INFO)
	M.update(buf)
end

function M.preview_hunk(buf, lnum)
	buf = resolve_buf(buf)
	lnum = lnum or api.nvim_win_get_cursor(0)[1]
	local hunk = find_hunk(buf, lnum)
	if not hunk or not hunk.lines or #hunk.lines == 0 then
		vim.notify("No git hunk at cursor", vim.log.levels.INFO)
		return
	end

	local lines = vim.list_extend({ hunk.header }, hunk.lines)
	local width = 32
	for _, l in ipairs(lines) do
		width = math.max(width, #l + 4)
	end

	local pbuf, win = ui.float({
		lines = lines,
		relative = "cursor",
		row = 1,
		col = 0,
		width = math.min(width, math.floor(vim.o.columns * 0.8)),
		height = math.min(#lines, 20),
		title = " Hunk Preview ",
		title_pos = "center",
		enter = false,
	})

	vim.bo[pbuf].filetype, vim.bo[pbuf].buftype = "diff", "nofile"
	vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)

	local augroup = api.nvim_create_augroup("BareGitPreview_" .. win, { clear = true })
	api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
		group = augroup,
		once = true,
		callback = function()
			if api.nvim_win_is_valid(win) then
				api.nvim_win_close(win, true)
			end
		end,
	})
end

function M.next_hunk(buf)
	buf = resolve_buf(buf)
	local b = bufs[buf]
	if not b or not b.hunks or #b.hunks == 0 then
		return
	end
	local cur = api.nvim_win_get_cursor(0)[1]
	for _, h in ipairs(b.hunks) do
		local target = hunk_line(h)
		if target > cur then
			api.nvim_win_set_cursor(0, { target, 0 })
			return
		end
	end
	api.nvim_win_set_cursor(0, { hunk_line(b.hunks[1]), 0 })
end

function M.prev_hunk(buf)
	buf = resolve_buf(buf)
	local b = bufs[buf]
	if not b or not b.hunks or #b.hunks == 0 then
		return
	end
	local cur = api.nvim_win_get_cursor(0)[1]
	for i = #b.hunks, 1, -1 do
		local h = b.hunks[i]
		local target = hunk_line(h)
		if target < cur then
			api.nvim_win_set_cursor(0, { target, 0 })
			return
		end
	end
	api.nvim_win_set_cursor(0, { hunk_line(b.hunks[#b.hunks]), 0 })
end

function M.revert_file(buf)
	local info = get_info(buf)
	if not info then
		return
	end
	if vim.fn.confirm("Revert all changes in " .. info.rel .. "?", "&Yes\n&No", 2) ~= 1 then
		return
	end

	vim.system({ "git", "-C", info.root, "checkout", "--", info.rel }, { text = true }, function(res)
		vim.schedule(function()
			if res.code == 0 then
				if api.nvim_buf_is_valid(info.buf) then
					vim.cmd("checktime " .. info.buf)
				end
				vim.notify("Reverted " .. info.rel, vim.log.levels.INFO)
				M.update(info.buf)
			else
				vim.notify("Failed to revert: " .. (res.stderr or ""), vim.log.levels.ERROR)
			end
		end)
	end)
end

function M.setup()
	M.set_hl()
	local group = api.nvim_create_augroup("BareGit", { clear = true })

	api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufReadPost", "BufWritePost", "TextChanged" }, {
		group = group,
		callback = function(args)
			local b = get_buf(args.buf)
			b.timer = b.timer or vim.uv.new_timer()
			b.timer:stop()
			b.timer:start(DEBOUNCE_MS, 0, function()
				vim.schedule(function()
					M.update(args.buf)
				end)
			end)
		end,
	})

	api.nvim_create_autocmd({ "BufDelete", "BufUnload", "BufWipeout" }, {
		group = group,
		callback = function(args)
			local b = bufs[args.buf]
			if b then
				if b.timer then
					b.timer:stop()
					b.timer:close()
				end
				bufs[args.buf] = nil
			end
		end,
	})

	api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.set_hl })

	for _, b in ipairs(api.nvim_list_bufs()) do
		if api.nvim_buf_is_loaded(b) then
			M.update(b)
		end
	end
end

return M
