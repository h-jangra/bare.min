-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 150 })
  end,
})

-- Floating quickfix & location list
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= "" then return end

    local is_loc = vim.fn.getwininfo(win)[1].loclist == 1
    local title = is_loc and " Location List " or " Quickfix "
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.min(math.max(#(is_loc and vim.fn.getloclist(0) or vim.fn.getqflist()), 3), math.floor(vim.o.lines * 0.5))

    vim.api.nvim_win_set_config(win, {
      relative = "editor",
      row = math.floor((vim.o.lines - height) / 3),
      col = math.floor((vim.o.columns - width) / 2),
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
      title = title,
      title_pos = "center",
    })

    local opts = { buffer = ev.buf, silent = true, nowait = true }
    vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", opts)
    vim.keymap.set("n", "<CR>", "<CR><cmd>pcall(vim.cmd, 'cclose')<cr><cmd>pcall(vim.cmd, 'lclose')<cr>", opts)
  end,
})
