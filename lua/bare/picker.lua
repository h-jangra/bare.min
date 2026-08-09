vim.opt.wildmenu = true
-- vim.opt.wildmode = 'noselect:lastused,full'
vim.opt.wildmode = 'longest:full,full' -- auto select match
vim.opt.completeopt = "menuone,noselect,popup,fuzzy"
vim.opt.wildoptions = "fuzzy,pum,tagfile"
vim.opt.wildignorecase = true
vim.opt.path:append('**')
vim.opt.wildignore:append({
  "*/.git/*",
  "*/node_modules/*",
  "*/dist/*",
  "*/build/*",
  "*/target/*",
  "*.o",
  "*.a",
  "*.out",
  "*.class",
})

vim.keymap.set('n', '<leader>f', ':find ', { desc = 'Fuzzy Find Files' })
vim.keymap.set('n', '<leader>h', ":tab h ", { desc = 'Open Help File' })

vim.api.nvim_create_autocmd("CmdlineChanged", {
  pattern = ":*",
  callback = function()
    vim.fn.wildmenumode()
    vim.fn.wildtrigger()
  end,
})
