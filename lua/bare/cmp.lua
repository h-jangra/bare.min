vim.opt.updatetime = 300
vim.o.omnifunc = "syntaxcomplete#Complete"
vim.opt.completeopt = { "menu", "menuone", "noselect", "preview" }
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

-- <C-Space> triggers signature help only when inside a function
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<C-e>", true, false, true),
      "n",
      true
    )
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  local before_cursor = line:sub(1, col)

  local open_count = select(2, before_cursor:gsub("%(", ""))
  local close_count = select(2, before_cursor:gsub("%)", ""))

  if open_count > close_count then
    vim.lsp.buf.signature_help()
  end
end, { desc = "Show function signature (only inside function calls)" })
