local opt          = vim.opt

opt.cmdheight      = 0
opt.laststatus     = 3
opt.mouse          = "a"
opt.number         = true
opt.relativenumber = true
opt.scrolloff      = 8
opt.showtabline    = 0
opt.signcolumn     = "yes:1"
opt.termguicolors  = true
opt.wrap           = true

opt.shortmess:append("IcFsW")
opt.completeopt    = { "menu", "menuone", "noselect" }
opt.winborder      = "rounded"

opt.expandtab      = true
opt.shiftwidth     = 2
opt.smartindent    = true
opt.softtabstop    = 2
opt.tabstop        = 2

opt.incsearch      = true

opt.autoread       = true
opt.backup         = false
opt.swapfile       = false
opt.undodir        = vim.fs.joinpath(vim.fn.stdpath("data"), "undodir")
opt.undofile       = true

opt.lazyredraw     = true
opt.mousescroll    = "ver:5,hor:0"
opt.synmaxcol      = 240
opt.timeoutlen     = 300
opt.ttimeoutlen    = 10
opt.updatetime     = 200
opt.winheight      = 1

opt.foldexpr       = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel      = 99
opt.foldlevelstart = 99
opt.foldmethod     = "expr"

vim.loader.enable()
vim.opt.shadafile = ""

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank { higroup = "Visual", timeout = 150 }
  end,
})

local function enable_blur()
  for _, g in ipairs({
    "Normal", "NormalNC", "SignColumn", "FoldColumn", "EndOfBuffer",
    "LineNr", "CursorLineNr", "StatusLine", "StatusLineNC",
    "TabLine", "TabLineFill", "NormalFloat", "FloatBorder",
    "Pmenu", "PmenuSbar", "PmenuBorder", "PmenuShadow",
  }) do
    local hl = vim.api.nvim_get_hl(0, { name = g })
    hl.bg = "NONE"
    vim.api.nvim_set_hl(0, g, hl)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = enable_blur, })
enable_blur()
