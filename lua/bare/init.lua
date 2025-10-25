vim.loader.enable()

for _, plugin in ipairs({
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin", "getscript", "getscriptPlugin",
  "vimball", "vimballPlugin", "2html_plugin", "logipat", "rrhelper", "spellfile_plugin",
  "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers", -- Comment this if you need netrw
}) do
  vim.g["loaded_" .. plugin] = 1
end

vim.opt.shadafile = ""

require("bare.theme").setup()
require("bare.buffer")
require("bare.status")

vim.schedule(function()
  require("bare.pairs").setup()
  require("bare.md").setup()
end)

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("bare.filetree").setup()
    require("bare.picker")
    -- require("bare.netrw")
    require("bare.fzf").setup()
  end,
  once = true
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  callback = function()
    require("bare.lsp")
    require("bare.cmp")
    require("bare.marks").setup()
    require("bare.surround").setup()
    require("bare.imgPaste")
  end,
  once = true
})

require("bare.preview").setup()
