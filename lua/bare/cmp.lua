vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

vim.opt.completeopt = { "menu", "menuone", "noselect", "preview" }
vim.opt.updatetime = 300

vim.diagnostic.config({ float = { border = "rounded" } })

-- Optional: automatically trigger completion as you type
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if vim.fn.pumvisible() == 1 then return end
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local char_before = col > 0 and line:sub(col, col) or ""
    if char_before:match("[%w_]") then
      vim.schedule(function()
        if vim.api.nvim_get_mode().mode == "i" then
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true),
            "n",
            true
          )
        end
      end)
    end
  end,
})

-- <C-Space> triggers signature help and closes completion menu
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    -- Close completion menu first
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<C-e>", true, false, true),
      "n",
      true
    )
  end
  -- Then show signature help
  vim.lsp.buf.signature_help()
end, { desc = "Show function signature (closes completion menu)" })
