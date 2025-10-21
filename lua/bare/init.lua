vim.loader.enable()

for _, plugin in ipairs({
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
}) do
  vim.g["loaded_" .. plugin] = 1
end

vim.opt.shadafile = "NONE"
vim.defer_fn(function()
  vim.opt.shadafile = ""
  vim.cmd("rshada!")
end, 100)

require("bare.theme").setup()
require("bare.buffer")
require("bare.status")

vim.schedule(function()
  require("bare.pairs").setup()
  require("bare.md").setup()
end)

vim.defer_fn(function()
  require("bare.cmp")
  require("bare.lsp")
end, 20)

vim.defer_fn(function()
  require("bare.fzf").setup()
  require("bare.filetree").setup()
  require("bare.marks").setup()
  require("bare.surround").setup()
end, 50)

vim.defer_fn(function()
  require("bare.liveserver").setup()
  -- require("bare.netrw")
end, 100)
