vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

-- Ctrl-Space to show signature help or trigger completion
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e>"
  end
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)
  if select(2, before:gsub("%(", "")) > select(2, before:gsub("%)", "")) then
    vim.lsp.buf.signature_help()
    return ""
  end
  return "<C-x><C-o>"
end, { expr = true })

-- Auto-trigger completion on typing
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if vim.fn.pumvisible() == 1 then
      return
    end
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, col)
    if before:match("[%w_]$") or before:match("%.$") then
      vim.schedule(function()
        if vim.fn.pumvisible() == 0 then
          local keys = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end
      end)
    end
  end,
})

-- Up/Down arrows navigate completion menu
vim.keymap.set("i", "<Down>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<Down>"
  end
end, { expr = true })

vim.keymap.set("i", "<Up>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<Up>"
  end
end, { expr = true })

-- Enter to select completion
vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  else
    return "<CR>"
  end
end, { expr = true })
