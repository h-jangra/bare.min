vim.loader.enable()

vim.opt.shadafile = ""

require('vim._core.ui2').enable({})
require("bare.theme").setup()
require("bare.options")
require("bare.keymaps")
require("bare.notify").setup()

vim.schedule(function()
  require("bare.buffer")
  require("bare.status")
  require("bare.git").setup()
  require("bare.pairs").setup()
  require("bare.preview").setup()
  require("bare.cmp")
  require("bare.netrw")
  --
  require("bare.marks").setup()
  require("bare.surround").setup()
  require("bare.lsp")
  -- require("bare.lsp_install")
  require("bare.picker")
  require("bare.floaterm")
  require("bare.imgPaste").setup()
end)

vim.keymap.set('n', '<leader>e', require("bare.filetree").toggle, { desc = "Open file tree" })
vim.keymap.set('n', '<leader><leader>', require("bare.fzf").files, { desc = "Open fzf files" })
vim.keymap.set('n', '<leader>fg', require("bare.fzf").grep, { desc = "Open fzf grep" })
