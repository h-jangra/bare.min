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
-- vim.opt.wildmode = 'longest:full,full' -- use this if you want to auto select
vim.opt.wildmode = 'noselect:lastused,full'
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

-- Minimal
vim.cmd([[
  highlight Pmenu           guifg=#f8f8f2 guibg=#2d2e3a gui=NONE
  highlight PmenuSel        guifg=#ffffff guibg=#44475a gui=Bold
  highlight PmenuBorder     guifg=#383a46 guibg=#2d2e3a gui=NONE
  highlight PmenuSbar       guibg=#24252e gui=NONE
  highlight PmenuThumb      guibg=#44475a gui=NONE

  highlight PmenuKind       guifg=#8be9fd guibg=#2d2e3a gui=NONE
  highlight PmenuExtra      guifg=#6272a4 guibg=#2d2e3a gui=Italic
  highlight PmenuMatch      guifg=#50fa7b guibg=NONE    gui=Bold

  highlight PmenuKindSel    guifg=#8be9fd guibg=#44475a gui=Bold
  highlight PmenuExtraSel   guifg=#b3b8d1 guibg=#44475a gui=Italic
  highlight PmenuMatchSel   guifg=#50fa7b guibg=#44475a gui=Bold
]])
