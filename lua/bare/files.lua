-- Keymaps:
-- <CR>/l: open | h/-: parent | :w/<C-s>: save changes
-- v/<C-v>: vsplit | s/<C-x>: split | <C-t>: tabedit
-- y/yy: yank | p/P: paste | g./H: toggle hidden
-- R: refresh | ~: go to cwd | q/<Esc>: close

local M = {}

local api, fn, fs, uv = vim.api, vim.fn, vim.fs, vim.uv or vim.loop
local ns_icons = api.nvim_create_namespace("bare_files_icons")
local ns_hl = api.nvim_create_namespace("bare_files_hl")
local has_icons, icons = pcall(require, "bare.icons")
local git = require("bare.git")

local config = { width = 32, show_hidden = false }
local state = { entries = {}, id_to_entry = {}, next_id = 1 }

local function valid_win(win)
	return win and api.nvim_win_is_valid(win)
end
local function valid_buf(buf)
	return buf and api.nvim_buf_is_valid(buf)
end

local function is_valid_target(win)
	if not valid_win(win) or win == state.win then
		return false
	end
	local b = api.nvim_win_get_buf(win)
	return vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "files"
end

local function clean_name(name)
	return (name:gsub("/+$", ""))
end

local function full_path(name)
	return state.current_dir and fs.normalize(fs.joinpath(state.current_dir, name)) or name
end

local function current_line(buf, win)
	local cursor = api.nvim_win_get_cursor(win or state.win or 0)
	return vim.trim(api.nvim_buf_get_lines(buf or state.buf, cursor[1] - 1, cursor[1], false)[1] or "")
end

local function get_visual_lines(buf)
	local v = fn.getpos("v")[2]
	local c = fn.getpos(".")[2]
	local s_row, e_row = math.min(v, c), math.max(v, c)
	return api.nvim_buf_get_lines(buf or state.buf, s_row - 1, e_row, false)
end

local function get_name_stem(name)
	local clean = clean_name(name)
	if clean:sub(1, 1) == "." and not clean:sub(2):find("%.") then
		return clean, ""
	end
	local dot = clean:match("^.*()%.")
	if dot and dot > 1 then
		return clean:sub(1, dot - 1), clean:sub(dot)
	end
	return clean, ""
end

local function confirm_unsaved(action)
	if not (valid_buf(state.buf) and vim.bo[state.buf].modified) then
		return true
	end
	local choice = fn.confirm("Unsaved changes. Save before " .. action .. "?", "&Save\n&Discard\n&Cancel", 1)
	if choice == 1 then
		M.save()
		return true
	elseif choice == 2 then
		M.render(state.current_dir)
		return true
	end
	return false
end

local function setup_hl()
	if git.set_hl then
		git.set_hl()
	end
	api.nvim_set_hl(0, "BareFilesDir", { default = true, link = "Directory" })
	api.nvim_set_hl(0, "BareFilesFile", { default = true, link = "Normal" })
	api.nvim_set_hl(0, "BareFilesHidden", { default = true, link = "Comment" })
end

local function get_file_icon(name, is_dir)
	if is_dir then
		return " ", "Directory"
	end
	if has_icons then
		local fname = clean_name(name)
		local ft = vim.filetype.match({ filename = fname }) or fname:match("%.([^.]+)$") or fname
		local icon, hl = icons.get(ft)
		if icon and icon ~= "" then
			return icon .. " ", hl
		end
	end
	return " ", "FileIconDefault"
end

local function scan_dir(dir, show_hidden)
	local handle = uv.fs_scandir(dir)
	if not handle then
		return {}
	end
	local dirs, files = {}, {}
	while true do
		local name, type = uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if show_hidden or name:sub(1, 1) ~= "." then
			local is_dir = type == "directory"
			table.insert(is_dir and dirs or files, {
				name = name,
				is_dir = is_dir,
				path = fs.normalize(fs.joinpath(dir, name)),
			})
		end
	end
	local sort_fn = function(a, b)
		return a.name:lower() < b.name:lower()
	end
	table.sort(dirs, sort_fn)
	table.sort(files, sort_fn)
	return vim.list_extend(dirs, files)
end

local function set_sidebar_win_opts(win)
	local wo = vim.wo[win]
	wo.winfixwidth, wo.number, wo.relativenumber, wo.signcolumn = true, false, false, "no"
	wo.foldcolumn, wo.wrap, wo.cursorline, wo.statuscolumn = "0", false, true, ""
	if state.current_dir then
		local home = fs.normalize(fn.expand("~"))
		local dir = state.current_dir
		local display = dir:sub(1, #home) == home and ("~" .. dir:sub(#home + 1)) or dir
		wo.winbar = "%#Directory#  " .. display .. " "
	end
end

local function reset_edit_win_opts(win)
	if not valid_win(win) then
		return
	end
	local wo = vim.wo[win]
	wo.winfixwidth, wo.number, wo.relativenumber, wo.signcolumn = false, true, true, "yes:1"
	wo.statuscolumn, wo.wrap, wo.cursorline = "", true, true
end

local function update_line_icons()
	if not valid_buf(state.buf) then
		return
	end
	api.nvim_buf_clear_namespace(state.buf, ns_icons, 0, -1)
	api.nvim_buf_clear_namespace(state.buf, ns_hl, 0, -1)
	local lines = api.nvim_buf_get_lines(state.buf, 0, -1, false)
	local orig_by_name = {}
	for _, e in ipairs(state.entries) do
		orig_by_name[e.name] = e
	end
	local git_map = state.current_dir and git.status(state.current_dir) or {}

	for i, line in ipairs(lines) do
		local text = vim.trim(line)
		if text ~= "" then
			local clean = clean_name(text)
			local orig = orig_by_name[clean]
			local full = full_path(clean)
			local is_dir = text:sub(-1) == "/" or (orig and orig.is_dir) or (full and fn.isdirectory(full) == 1)
			local is_hidden = clean:sub(1, 1) == "."
			local icon, icon_hl = get_file_icon(clean, is_dir)
			if is_hidden then
				icon_hl = "BareFilesHidden"
			end
			local git_info = full and git_map[full]
			local text_hl = is_hidden and "BareFilesHidden"
				or (is_dir and "BareFilesDir" or (git_info and git_info.hl or "BareFilesFile"))

			local opts = { virt_text = { { " " .. icon, icon_hl } }, virt_text_pos = "inline", right_gravity = false }
			if orig then
				opts.id = orig.id
			end
			api.nvim_buf_set_extmark(state.buf, ns_icons, i - 1, 0, opts)
			api.nvim_buf_set_extmark(
				state.buf,
				ns_hl,
				i - 1,
				0,
				{ end_row = i - 1, end_col = #line, hl_group = text_hl }
			)
			if git_info then
				api.nvim_buf_set_extmark(
					state.buf,
					ns_hl,
					i - 1,
					0,
					{ virt_text = { { " " .. git_info.sym, git_info.hl } }, virt_text_pos = "eol", hl_mode = "combine" }
				)
			end
		end
	end
end

local function copy_recursive(src, dst)
	local stat = uv.fs_stat(src)
	if not stat then
		return
	end
	if stat.type == "directory" then
		fn.mkdir(dst, "p")
		local handle = uv.fs_scandir(src)
		if handle then
			while true do
				local name = uv.fs_scandir_next(handle)
				if not name then
					break
				end
				copy_recursive(fs.joinpath(src, name), fs.joinpath(dst, name))
			end
		end
	else
		fn.mkdir(fs.dirname(dst), "p")
		uv.fs_copyfile(src, dst)
	end
end

local function confirm_actions(actions)
	local lines = {}
	local function add(header, list, fmt)
		if #list > 0 then
			table.insert(lines, string.format("%s (%d):", header, #list))
			for _, item in ipairs(list) do
				table.insert(lines, fmt(item))
			end
		end
	end
	add("CREATE", actions.creates, function(c)
		return "  + " .. c.name .. (c.src and " (copy)" or "")
	end)
	add("RENAME", actions.renames, function(r)
		return string.format("  ~ %s -> %s", r.old_name, r.new_name)
	end)
	add("DELETE", actions.deletes, function(d)
		return "  - " .. d.name
	end)
	local total = #actions.creates + #actions.renames + #actions.deletes
	return fn.confirm(
		string.format("Apply %d filesystem change%s?\n\n%s", total, total == 1 and "" or "s", table.concat(lines, "\n")),
		"&Yes\n&No",
		1
	) == 1
end

local function make_duplicate_name(name, is_dir, existing)
	local stem, ext = get_name_stem(name)
	local base_stem, num_str = stem:match("^(.-)%s*%((%d+)%)$")
	base_stem = base_stem or stem
	local i = num_str and (tonumber(num_str) + 1) or 1

	while true do
		local candidate = string.format("%s (%d)%s", base_stem, i, ext)
		local candidate_slash = candidate .. "/"
		local disk_path = full_path(candidate)
		local exists_on_disk = disk_path and (uv.fs_stat(disk_path) ~= nil)
		if not existing[candidate] and not existing[candidate_slash] and not exists_on_disk then
			return is_dir and candidate_slash or candidate
		end
		i = i + 1
	end
end

local function get_target_window()
	if is_valid_target(state.target_win) then
		reset_edit_win_opts(state.target_win)
		return state.target_win
	end
	for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
		if is_valid_target(w) then
			state.target_win = w
			reset_edit_win_opts(w)
			return w
		end
	end
	api.nvim_set_current_win(state.win)
	vim.cmd("botright vertical split")
	local target = api.nvim_get_current_win()
	state.target_win = target
	reset_edit_win_opts(target)
	vim.wo[target].winbar = ""
	if valid_win(state.win) then
		pcall(api.nvim_win_set_width, state.win, config.width)
	end
	return target
end

function M.open_file(path, cmd)
	local target = get_target_window()
	api.nvim_set_current_win(target)
	vim.cmd((cmd or "edit") .. " " .. fn.fnameescape(path))
	reset_edit_win_opts(api.nvim_get_current_win())
	if valid_win(state.win) then
		pcall(api.nvim_win_set_width, state.win, config.width)
	end
end

function M.save()
	if not valid_buf(state.buf) then
		return
	end
	local cur_lines = api.nvim_buf_get_lines(state.buf, 0, -1, false)
	local actions = { creates = {}, renames = {}, deletes = {} }
	local orig_by_name, orig_used, line_used = {}, {}, {}
	for _, orig in ipairs(state.entries) do
		orig_by_name[orig.name] = orig
	end

	for i, line in ipairs(cur_lines) do
		local clean = clean_name(vim.trim(line))
		local orig = orig_by_name[clean]
		if clean ~= "" and orig and not orig_used[orig.id] then
			orig_used[orig.id] = true
			line_used[i] = true
		end
	end

	for i, line in ipairs(cur_lines) do
		local text = vim.trim(line)
		if not line_used[i] and text ~= "" and text ~= "." and text ~= ".." then
			local marks = api.nvim_buf_get_extmarks(
				state.buf,
				ns_icons,
				{ i - 1, 0 },
				{ i - 1, -1 },
				{ details = true }
			)
			local orig
			for _, m in ipairs(marks) do
				if m[1] and state.id_to_entry[m[1]] then
					orig = state.id_to_entry[m[1]]
					break
				end
			end
			if orig and not orig_used[orig.id] then
				orig_used[orig.id] = true
				line_used[i] = true
				local clean = clean_name(text)
				local new_path = full_path(clean)
				if new_path ~= orig.path then
					table.insert(actions.renames, {
						old_path = orig.path,
						new_path = new_path,
						old_name = orig.name,
						new_name = clean,
						is_dir = text:sub(-1) == "/" or orig.is_dir,
					})
				end
			end
		end
	end

	local clip_items = (state.clipboard and #state.clipboard > 0 and state.clipboard)
		or (state.clipboard and state.clipboard.name and { state.clipboard })
		or {}

	for i, line in ipairs(cur_lines) do
		if not line_used[i] then
			local text = vim.trim(line)
			if text ~= "" and text ~= "." and text ~= ".." then
				local clean = clean_name(text)
				local pasted = state.pasted and state.pasted[clean]
				local src = pasted and pasted.src
				local is_dir = text:sub(-1) == "/" or (pasted and pasted.is_dir) or false

				if not src and #clip_items > 0 then
					for _, item in ipairs(clip_items) do
						local item_stat = item.path and uv.fs_stat(item.path)
						local item_src = item_stat and item.path or nil
						local item_stem = item.name and get_name_stem(item.name)
						local item_pattern = item_stem and ("^" .. vim.pesc(item_stem) .. "%s*%(")
						if
							item_src
							and (clean == clean_name(item.name) or (item_pattern and clean:match(item_pattern)))
						then
							src = item_src
							if item_stat and item_stat.type == "directory" then
								is_dir = true
							end
							break
						end
					end
				end

				table.insert(actions.creates, {
					path = full_path(clean),
					name = clean,
					is_dir = is_dir,
					src = src,
				})
			end
		end
	end

	for _, orig in ipairs(state.entries) do
		if not orig_used[orig.id] then
			table.insert(actions.deletes, { path = orig.path, name = orig.name, is_dir = orig.is_dir })
		end
	end

	local total = #actions.creates + #actions.renames + #actions.deletes
	if total == 0 then
		vim.bo[state.buf].modified = false
		vim.notify("No changes to sync", vim.log.levels.INFO)
		return
	end
	if not confirm_actions(actions) then
		vim.notify("File operations cancelled", vim.log.levels.WARN)
		return
	end

	for _, d in ipairs(actions.deletes) do
		fn.delete(d.path, "rf")
		for _, b in ipairs(api.nvim_list_bufs()) do
			if api.nvim_buf_is_valid(b) and api.nvim_buf_get_name(b) == d.path then
				api.nvim_buf_delete(b, { force = true })
			end
		end
	end

	for _, r in ipairs(actions.renames) do
		fn.mkdir(fs.dirname(r.new_path), "p")
		local ok = uv.fs_rename(r.old_path, r.new_path) or os.rename(r.old_path, r.new_path)
		if ok then
			for _, b in ipairs(api.nvim_list_bufs()) do
				if api.nvim_buf_is_valid(b) and api.nvim_buf_get_name(b) == r.old_path then
					api.nvim_buf_set_name(b, r.new_path)
					api.nvim_buf_call(b, function()
						vim.cmd("silent! checktime")
					end)
				end
			end
		else
			vim.notify("Rename error on: " .. r.old_name, vim.log.levels.ERROR)
		end
	end

	for _, c in ipairs(actions.creates) do
		if c.src and uv.fs_stat(c.src) then
			copy_recursive(c.src, c.path)
		elseif c.is_dir then
			fn.mkdir(c.path, "p")
		elseif not uv.fs_stat(c.path) then
			fn.mkdir(fs.dirname(c.path), "p")
			local f = io.open(c.path, "w")
			if f then
				f:close()
			end
		end
	end

	state.pasted = nil
	vim.notify(string.format("Applied %d filesystem operation%s", total, total == 1 and "" or "s"), vim.log.levels.INFO)
	M.render(state.current_dir)
end

function M.render(dir, focus_name)
	dir = fs.normalize(dir or state.current_dir or fn.getcwd())
	state.current_dir = dir
	if not valid_buf(state.buf) then
		state.buf = api.nvim_create_buf(false, true)
		local bo = vim.bo[state.buf]
		bo.buftype, bo.filetype, bo.swapfile, bo.buflisted, bo.bufhidden = "acwrite", "files", false, false, "hide"
		api.nvim_create_autocmd("BufWriteCmd", {
			buffer = state.buf,
			callback = function()
				M.save()
				if valid_buf(state.buf) then
					vim.bo[state.buf].modified = false
				end
			end,
		})
		api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { buffer = state.buf, callback = update_line_icons })
		M.setup_buffer_keymaps(state.buf)
	end

	pcall(api.nvim_buf_set_name, state.buf, fn.fnamemodify(dir, ":~"))

	if valid_win(state.win) then
		api.nvim_win_set_buf(state.win, state.buf)
		pcall(api.nvim_win_set_width, state.win, config.width)
		set_sidebar_win_opts(state.win)
	end

	state.entries = scan_dir(dir, config.show_hidden)
	state.id_to_entry = {}
	local lines = {}
	for _, e in ipairs(state.entries) do
		e.id = state.next_id
		state.next_id = state.next_id + 1
		state.id_to_entry[e.id] = e
		table.insert(lines, e.name)
	end
	if #lines == 0 then
		table.insert(lines, "")
	end

	api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	update_line_icons()
	vim.bo[state.buf].modified = false

	if valid_win(state.win) then
		local target_line = 1
		if focus_name then
			local clean = clean_name(focus_name)
			for i, e in ipairs(state.entries) do
				if e.name == clean then
					target_line = i
					break
				end
			end
		end
		pcall(api.nvim_win_set_cursor, state.win, { math.min(target_line, math.max(#lines, 1)), 0 })
	end
end

local function open_entry_path(line, cmd)
	local clean = clean_name(line)
	local full = full_path(clean)
	local is_dir = false
	for _, e in ipairs(state.entries) do
		if e.name == clean then
			is_dir = e.is_dir
			break
		end
	end
	if not is_dir and (line:sub(-1) == "/" or (full and fn.isdirectory(full) == 1)) then
		is_dir = true
	end

	if is_dir then
		M.render(full)
	else
		M.open_file(full, cmd)
	end
end

function M.open_entry(cmd)
	if not valid_buf(state.buf) or not confirm_unsaved("opening") then
		return
	end
	local line = current_line()
	if line ~= "" then
		open_entry_path(line, cmd)
	end
end

function M.parent_dir()
	if not state.current_dir or not confirm_unsaved("navigating") then
		return
	end
	local parent = fs.dirname(state.current_dir)
	if parent and parent ~= state.current_dir then
		M.render(parent, fs.basename(state.current_dir))
	end
end

function M.toggle_hidden()
	config.show_hidden = not config.show_hidden
	M.render(state.current_dir)
end

function M.paste(before)
	if not valid_buf(state.buf) then
		return
	end
	local items = {}
	if state.clipboard and #state.clipboard > 0 then
		items = state.clipboard
	elseif state.clipboard and state.clipboard.name then
		items = { state.clipboard }
	else
		local reg = fn.getreg('"')
		if not reg or reg == "" then
			return
		end
		for _, l in ipairs(vim.split(reg, "\n")) do
			local trimmed = vim.trim(l)
			if trimmed ~= "" then
				local is_dir = trimmed:sub(-1) == "/"
				local src_name = clean_name(trimmed)
				table.insert(items, { path = full_path(src_name), name = src_name, is_dir = is_dir })
			end
		end
	end
	if #items == 0 then
		return
	end

	local existing = {}
	for _, l in ipairs(api.nvim_buf_get_lines(state.buf, 0, -1, false)) do
		local t = vim.trim(l)
		if t ~= "" then
			existing[t] = true
			existing[clean_name(t)] = true
		end
	end
	if state.entries then
		for _, e in ipairs(state.entries) do
			existing[e.name] = true
		end
	end

	state.pasted = state.pasted or {}
	local new_lines = {}

	for _, item in ipairs(items) do
		local clean_src = clean_name(item.name)
		local disk_path = full_path(clean_src)
		local exists = existing[clean_src] or existing[clean_src .. "/"] or (disk_path and uv.fs_stat(disk_path) ~= nil)

		local target_name = exists and make_duplicate_name(item.name, item.is_dir, existing)
			or (item.is_dir and (clean_src .. "/") or clean_src)

		existing[target_name] = true
		existing[clean_name(target_name)] = true

		state.pasted[clean_name(target_name)] = { src = item.path, is_dir = item.is_dir }
		table.insert(new_lines, target_name)
	end

	if #new_lines == 0 then
		return
	end

	local cursor = api.nvim_win_get_cursor(state.win or 0)
	local total = api.nvim_buf_line_count(state.buf)
	local row = math.min(cursor[1], total)
	local lines = api.nvim_buf_get_lines(state.buf, 0, -1, false)

	local new_cursor_row
	if #lines == 1 and lines[1] == "" then
		api.nvim_buf_set_lines(state.buf, 0, 1, false, new_lines)
		new_cursor_row = 1
	elseif before then
		local insert_idx = math.max(0, row - 1)
		api.nvim_buf_set_lines(state.buf, insert_idx, insert_idx, false, new_lines)
		new_cursor_row = insert_idx + 1
	else
		api.nvim_buf_set_lines(state.buf, row, row, false, new_lines)
		new_cursor_row = row + 1
	end

	if valid_win(state.win) then
		pcall(api.nvim_win_set_cursor, state.win, { new_cursor_row, 0 })
	end

	vim.bo[state.buf].modified = true
	update_line_icons()
end

function M.setup_buffer_keymaps(buf)
	local function map(modes, keys, rhs, desc, extra)
		local list = type(keys) == "table" and keys or { keys }
		local opts = vim.tbl_extend("force", { buffer = buf, silent = true, desc = desc }, extra or {})
		for _, k in ipairs(list) do
			vim.keymap.set(modes, k, rhs, opts)
		end
	end

	local function nmap(keys, rhs, desc, extra)
		map("n", keys, rhs, desc, extra)
	end

	local function xmap(keys, rhs, desc, extra)
		map("x", keys, rhs, desc, extra)
	end

	local function yank_entry(cmd, is_visual)
		local lines = is_visual and get_visual_lines(buf) or { current_line(buf) }
		local items = {}
		for _, line in ipairs(lines) do
			local trimmed = vim.trim(line)
			if trimmed ~= "" then
				local clean = clean_name(trimmed)
				local full = full_path(clean)
				local is_dir = trimmed:sub(-1) == "/" or (full and fn.isdirectory(full) == 1)
				table.insert(items, { path = full, name = clean, is_dir = is_dir })
			end
		end
		if #items > 0 then
			state.clipboard = items
			state.clipboard.path = items[1].path
			state.clipboard.name = items[1].name
			state.clipboard.is_dir = items[1].is_dir
		end
		return cmd
	end

	local function open_visual(cmd)
		if not valid_buf(state.buf) or not confirm_unsaved("opening") then
			return
		end
		local lines = get_visual_lines(buf)
		api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		for _, line in ipairs(lines) do
			local text = vim.trim(line)
			if text ~= "" then
				open_entry_path(text, cmd)
			end
		end
	end

	-- Normal mode mappings
	nmap({ "<CR>", "l" }, function()
		M.open_entry("edit")
	end, "Open / Enter")
	nmap({ "h", "-" }, M.parent_dir, "Parent directory")
	nmap({ "v", "<C-v>" }, function()
		M.open_entry("vsplit")
	end, "Open in vertical split")
	nmap({ "s", "<C-x>" }, function()
		M.open_entry("split")
	end, "Open in horizontal split")
	nmap("<C-t>", function()
		M.open_entry("tabedit")
	end, "Open in new tab")
	nmap("<C-s>", M.save, "Save changes")
	map({ "i", "v" }, "<C-s>", function()
		vim.cmd("stopinsert")
		M.save()
	end, "Save changes")

	for _, k in ipairs({ "y", "yy" }) do
		nmap(k, function()
			return yank_entry(k, false)
		end, "Yank entry", { expr = true })
	end
	nmap("p", function()
		M.paste(false)
	end, "Paste after")
	nmap("P", function()
		M.paste(true)
	end, "Paste before")
	nmap({ "g.", "H" }, M.toggle_hidden, "Toggle hidden files")
	nmap("R", function()
		M.render(state.current_dir)
	end, "Refresh")
	nmap("~", function()
		M.render(fn.getcwd())
	end, "Go to cwd")
	nmap({ "q", "<Esc>" }, M.close, "Close sidebar")

	-- Visual mode mappings for multifile ops
	xmap({ "<CR>", "l" }, function()
		open_visual("edit")
	end, "Open selected entries")
	xmap({ "v", "<C-v>" }, function()
		open_visual("vsplit")
	end, "Open selected in vertical splits")
	xmap({ "s", "<C-x>" }, function()
		open_visual("split")
	end, "Open selected in horizontal splits")
	xmap("<C-t>", function()
		open_visual("tabedit")
	end, "Open selected in new tabs")
	for _, k in ipairs({ "y", "Y" }) do
		xmap(k, function()
			return yank_entry("y", true)
		end, "Yank selected entries", { expr = true })
	end
	xmap("p", function()
		M.paste(false)
	end, "Paste after")
	xmap("P", function()
		M.paste(true)
	end, "Paste before")
end

function M.open(dir)
	setup_hl()
	dir = dir and fs.normalize(fn.fnamemodify(dir, ":p")) or nil
	if not dir or dir == "" then
		local cur_file = api.nvim_buf_get_name(0)
		dir = (cur_file ~= "" and vim.bo.buftype == "") and fs.dirname(cur_file) or fn.getcwd()
	end
	local cur_win = api.nvim_get_current_win()
	if (not state.win or cur_win ~= state.win) and vim.bo[api.nvim_win_get_buf(cur_win)].buftype == "" then
		state.target_win = cur_win
	end
	if valid_win(state.win) then
		api.nvim_set_current_win(state.win)
		if dir ~= state.current_dir then
			M.render(dir)
		end
		return
	end
	vim.cmd("topleft vertical " .. config.width .. "split")
	state.win = api.nvim_get_current_win()
	M.render(dir)
end

function M.close()
	if not valid_win(state.win) then
		return
	end
	local wins = api.nvim_tabpage_list_wins(0)
	if #wins > 1 then
		pcall(api.nvim_win_close, state.win, true)
	else
		local new_buf = api.nvim_create_buf(true, false)
		api.nvim_win_set_buf(state.win, new_buf)
	end
	state.win = nil
	if valid_win(state.target_win) then
		pcall(api.nvim_set_current_win, state.target_win)
	end
end

function M.toggle(dir)
	if valid_win(state.win) then
		M.close()
	else
		M.open(dir)
	end
end

function M.setup(opts)
	if opts then
		config = vim.tbl_deep_extend("force", config, opts)
	end
	setup_hl()
	local grp = api.nvim_create_augroup("BareFiles", { clear = true })

	api.nvim_create_autocmd("WinEnter", {
		group = grp,
		callback = function()
			local win = api.nvim_get_current_win()
			if is_valid_target(win) then
				state.target_win = win
			end
		end,
	})

	api.nvim_create_autocmd("BufEnter", {
		group = grp,
		callback = function(args)
			local cur_win = api.nvim_get_current_win()
			if state.win and cur_win == state.win and args.buf ~= state.buf then
				local bt, ft = vim.bo[args.buf].buftype, vim.bo[args.buf].filetype
				if bt == "" and ft ~= "files" then
					vim.schedule(function()
						if not api.nvim_buf_is_valid(args.buf) then
							return
						end
						if valid_win(state.win) and valid_buf(state.buf) then
							api.nvim_win_set_buf(state.win, state.buf)
							pcall(api.nvim_win_set_width, state.win, config.width)
						end
						local target = get_target_window()
						api.nvim_set_current_win(target)
						api.nvim_win_set_buf(target, args.buf)
						reset_edit_win_opts(target)
					end)
				end
			end
		end,
	})

	api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
		group = grp,
		callback = function()
			if valid_buf(state.buf) and not vim.bo[state.buf].modified and valid_win(state.win) then
				M.render(state.current_dir)
			end
		end,
	})

	api.nvim_create_autocmd("ColorScheme", { group = grp, callback = setup_hl })
end

return M
