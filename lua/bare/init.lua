-- load onedark first otherwise bufferline colors wont work
require("bare.onedark")
require("bare.buffer")
require("bare.status")
require("bare.cmp")
require("bare.fzf").setup()
require("bare.netrw")
require("bare.filetree").setup()

vim.defer_fn(function()
  require("bare.liveserver").setup()
  require("bare.marks").setup()
  require("bare.surround").setup()
  require("bare.pairs").setup()
end, 50)


vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  once = true,
  callback = function()
    require("bare.lsp")
  end,
})
