vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

-- Ctrl-Space to show signature help
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e>"
  end
  
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)
  
  -- Check if inside function parameters
  if select(2, before:gsub("%(", "")) > select(2, before:gsub("%)", "")) then
    vim.lsp.buf.signature_help()
    return ""
  end
  
  return "<C-x><C-o>"
end, { expr = true })

-- Auto-trigger completion on typing
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    -- Don't trigger if completion menu is already visible
    if vim.fn.pumvisible() == 1 then
      return
    end
    
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, col)
    
    -- Trigger on identifier characters or after dot
    if before:match("[%w_]$") or before:match("%.$") then
      vim.schedule(function()
        if vim.fn.pumvisible() == 0 then
          -- Use feedkeys to trigger omni completion
          local keys = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end
      end)
    end
  end,
})
