vim.loader.enable()

-- Disable unused plugins
for _, plugin in ipairs({
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin", "getscript", "getscriptPlugin",
  "vimball", "vimballPlugin", "2html_plugin", "logipat", "rrhelper", "spellfile_plugin",
  "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
}) do
  vim.g["loaded_" .. plugin] = 1
end

vim.opt.shadafile = ""

require("bare.theme").setup()
require("bare.buffer")
require("bare.options")
require("bare.keymaps")
require("bare.status")

vim.schedule(function()
  require("bare.pairs").setup()
  require("bare.md").setup()
end)

require("bare.preview").setup()

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "html,typst,markdown",
--   callback = function() require("bare.preview").setup() end
-- })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  callback = function()
    require("bare.marks").setup()
    require("bare.surround").setup()
    require("bare.lsp")
    require("bare.cmp")
    require("bare.picker")

    vim.defer_fn(function()
      require("bare.floaterm")
      require("bare.imgPaste")
    end, 150)
  end,
  once = true
})

vim.keymap.set('n', '<leader>e', require("bare.filetree").toggle, { desc = "Open file tree" })
vim.keymap.set('n', '<leader><leader>', require("bare.fzf").files, { desc = "Open fzf files" })
vim.keymap.set('n', '<leader>fg', require("bare.fzf").grep, { desc = "Open fzf grep" })
