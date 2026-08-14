vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_mousemaps = 0
vim.g.netrw_keepdir = 0

local has_icons, icons = pcall(require, "bare.icons")
local ns_id = vim.api.nvim_create_namespace("netrw_icons")

local function apply_icons(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for idx, line in ipairs(lines) do
		if not line:match('^"') and line:match("%S") then
			local col = line:find("[^%s|│├└─┊]")
			if col then
				local name = line:sub(col):gsub("[%*@]$", "")
				local is_dir = name:sub(-1) == "/"
				local icon, hl = "󰈤 ", "FileIconDefault"

				if is_dir then
					icon, hl = " ", "Directory"
				elseif has_icons then
					local fname = vim.fs.basename(name)
					local ft = vim.filetype.match({ filename = fname }) or fname:match("%.([^.]+)$") or fname
					local i, h = icons.get(ft)
					if i then
						icon, hl = i .. " ", h
					end
				end

				pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, idx - 1, col - 1, {
					virt_text = { { icon, hl } },
					virt_text_pos = "inline",
				})
			end
		end
	end
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function(event)
		local opts = { buffer = event.buf, remap = true, silent = true }

		vim.keymap.set("n", "l", "<Plug>NetrwLocalBrowseCheck", opts)
		vim.keymap.set("n", "<CR>", "<Plug>NetrwLocalBrowseCheck", opts)
		vim.keymap.set("n", "h", "<Plug>NetrwLocalBrowseCheck", opts)

		-- Override % to create file in previous window
		vim.keymap.set("n", "%", function()
			local filename = vim.fn.input("New file name: ")
			if filename ~= "" then
				vim.cmd("wincmd p")
				vim.cmd("edit " .. vim.fn.fnameescape(filename))
			end
		end, { buffer = event.buf, silent = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
			buffer = event.buf,
			callback = function()
				apply_icons(event.buf)
			end,
		})

		vim.schedule(function()
			apply_icons(event.buf)
		end)
	end,
})
