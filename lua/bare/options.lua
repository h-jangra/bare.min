local opt = vim.opt

opt.cmdheight = 0
opt.laststatus = 3
opt.mouse = "a"
opt.number = true
opt.relativenumber = true
opt.scrolloff = 8
opt.showtabline = 0
opt.signcolumn = "yes:1"
opt.termguicolors = true
opt.wrap = true

opt.shortmess:append("IcFsW")
opt.completeopt = { "menu", "menuone", "noselect" }
opt.winborder = "rounded"

opt.expandtab = true
opt.shiftwidth = 2
opt.smartindent = true
opt.softtabstop = 2
opt.tabstop = 2

opt.incsearch = true

opt.autoread = true
opt.backup = false
opt.swapfile = false
opt.undodir = vim.fs.joinpath(vim.fn.stdpath("data"), "undodir")
opt.undofile = true

opt.mousescroll = "ver:5,hor:0"
opt.synmaxcol = 240
opt.timeoutlen = 300
opt.ttimeoutlen = 10
opt.updatetime = 200
opt.winheight = 1


vim.opt.shadafile = ""

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 150 })
  end,
})
