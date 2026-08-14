local ui = require("bare.ui")

local M = {
	config = { width = 0.9, height = 0.9, border = "rounded" },
	state = { win = nil, buf = nil },
}

function M.setup(cfg)
	M.config = vim.tbl_deep_extend("force", M.config, cfg or {})
end

function M.open(cmd, title)
	if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
		vim.api.nvim_win_close(M.state.win, true)
		M.state.win = nil
		return
	end

	local is_cmd = type(cmd) == "string" and cmd ~= ""
	local is_new = is_cmd or not (M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf))

	if is_new then
		M.state.buf = vim.api.nvim_create_buf(false, true)
	end

	local _, win = ui.float({
		buf = M.state.buf,
		width = math.floor(vim.o.columns * M.config.width),
		height = math.floor(vim.o.lines * M.config.height),
		border = M.config.border,
		title = title or " Terminal ",
	})

	M.state.win = win
	if is_new then
		vim.keymap.set("t", "<Esc>", "<C-\\><C-n>:Floaterm<CR>", { buffer = M.state.buf, silent = true })
		vim.fn.termopen(is_cmd and cmd or vim.o.shell)
	end
	vim.cmd.startinsert()
end

vim.api.nvim_create_user_command("Floaterm", function(o)
	M.open(o.args)
end, { nargs = "?", desc = "Open floating terminal" })
vim.keymap.set("n", "<leader>t", M.open, { desc = "Toggle floating terminal" })

return M
