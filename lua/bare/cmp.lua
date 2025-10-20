vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

local function has_lsp()
  return #vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() }) > 0
end

-- Manual completion
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e>"
  end
  if has_lsp() then
    return "<C-x><C-o>"
  end
  return ""
end, { expr = true })

-- Auto-completion
local timer = nil
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if vim.fn.pumvisible() == 1 or not has_lsp() then return end

    if timer and not timer:is_closing() then
      timer:close()
    end

    timer = vim.defer_fn(function()
      if vim.fn.pumvisible() == 0 and has_lsp() then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true), "n", false)
      end
      timer = nil
    end, 100)
  end,
})

vim.keymap.set("i", "<Down>", [[pumvisible() ? "<C-n>" : "<Down>"]], { expr = true })
vim.keymap.set("i", "<Up>", [[pumvisible() ? "<C-p>" : "<Up>"]], { expr = true })
vim.keymap.set("i", "<CR>", [[pumvisible() ? "<C-y>" : "<CR>"]], { expr = true })
