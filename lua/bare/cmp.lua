vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Track LSP attachment per buffer
local function has_lsp()
  local bufnr = vim.api.nvim_get_current_buf()
  return #vim.lsp.get_clients({ bufnr = bufnr }) > 0
end

-- Setup omnifunc when LSP attaches
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

  if not has_lsp() then
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

-- Auto-trigger completion on typing
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    -- Don't trigger if completion window is already visible
    if vim.fn.pumvisible() == 1 then
      return
    end

    -- Don't trigger if no LSP is attached
    if not has_lsp() then
      return
    end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, col)

    -- Trigger completion on word characters, dots, or colons (for methods)
    if before:match("[%w_%.:]$") then
      -- Small delay to avoid triggering too frequently
      vim.defer_fn(function()
        -- Double-check that completion isn't visible and LSP is still attached
        if vim.fn.pumvisible() == 0 and has_lsp() then
          local keys = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end
      end, 100)
    end
  end,
})

-- Navigation keymaps
vim.keymap.set("i", "<Down>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Down>"
end, { expr = true })

vim.keymap.set("i", "<Up>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<Up>"
end, { expr = true })

vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })
