-- Uncomment this to disable .git folder but it will slow down nvim
-- function _G.GlobFindFiles(cmd)
--   local files = vim.fn.globpath(vim.fn.getcwd(), '**/*', true, true)
--   local filtered = {}
--   for _, f in ipairs(files) do
--     if vim.fn.isdirectory(f) == 0 and not f:match('%.git[/\\]') then
--       table.insert(filtered, vim.fn.fnamemodify(f, ':.'))
--     end
--   end
--   return #cmd == 0 and filtered or vim.fn.matchfuzzy(filtered, cmd)
-- end
--
-- vim.o.findfunc = 'v:lua.GlobFindFiles'

vim.opt.wildmenu = true
-- vim.opt.wildmode = 'noselect:lastused,full'
vim.opt.wildmode = 'longest:full,full' -- use this if you want to auto select
vim.opt.wildoptions = 'pum'
vim.opt.wildignorecase = true
vim.opt.path:append('**')

vim.keymap.set('n', '<leader>f', ':find ', { desc = 'Fuzzy Find Files' })

vim.api.nvim_create_autocmd("CmdlineChanged", {
  pattern = ":*",
  callback = function()
    vim.fn.wildmenumode()
    vim.fn["wildtrigger"]()
  end,
})
