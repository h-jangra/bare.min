vim.opt.completeopt = { "menu", "menuone", "noselect" }

local lsp_attached = false

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    lsp_attached = true
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  callback = function()
    -- Check if any buffers still have LSP attached
    local has_attached_lsp = false
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.b[buf].lsp_attached then
        has_attached_lsp = true
        break
      end
    end
    lsp_attached = has_attached_lsp
  end,
})

-- Ctrl-Space to show signature help or trigger completion
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e>"
  end

  -- Only trigger if LSP is available
  if not lsp_attached then
    return ""
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)

  -- Check for unbalanced parentheses for signature help
  if select(2, before:gsub("%(", "")) > select(2, before:gsub("%)", "")) then
    vim.lsp.buf.signature_help()
    return ""
  end

  return "<C-x><C-o>"
end, { expr = true })

-- Auto-trigger completion
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    -- Don't trigger if completion window is already visible
    if vim.fn.pumvisible() == 1 then
      return
    end

    if not lsp_attached then
      return
    end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, col)

    -- Trigger completion on word characters, dots, or colons (for methods)
    if before:match("[%w_]$") or before:match("%.$") or before:match(":$") then
      vim.schedule(function()
        -- Double-check that completion isn't visible before triggering
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
