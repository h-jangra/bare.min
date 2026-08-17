vim.keymap.set("n", "<leader>r", function()
  local file = vim.fn.expand("%:p")

  vim.cmd("Floaterm nim r --hints:off --verbosity:0 " .. file)
end)
