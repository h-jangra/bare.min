local opt = vim.opt

opt.cmdheight = 0
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes:1"
opt.scrolloff = 8
opt.wrap = false
opt.mouse = "a"
opt.termguicolors = true
opt.laststatus = 3
opt.showtabline = 0

opt.shortmess:append("IcFsW")
opt.completeopt = { "menu", "menuone", "noselect" }
opt.winborder = "rounded"

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

opt.incsearch = true

opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undodir"
opt.swapfile = false
opt.backup = false
opt.autoread = true

opt.synmaxcol = 240
opt.lazyredraw = true
opt.updatetime = 200
opt.timeoutlen = 300
opt.ttimeoutlen = 10
opt.mousescroll = "ver:5,hor:0"
opt.winheight = 1

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 150 })
  end,
})

vim.diagnostic.config({
  virtual_text = { current_line = true },
})

local function enable_blur()
  local groups = {
    "Normal", "NormalNC", "SignColumn", "FoldColumn", "EndOfBuffer",
    "LineNr", "CursorLineNr", "StatusLine", "StatusLineNC",
    "TabLine", "TabLineFill", "NormalFloat", "FloatBorder",
    "Pmenu", "PmenuSbar", "PmenuBorder", "PmenuShadow",
  }

  for _, group in ipairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
    if ok then
      hl.bg = "NONE"
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = enable_blur, })

enable_blur()
