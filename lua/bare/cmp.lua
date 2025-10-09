-- Default omnifunc for all buffers (fallback)
vim.o.omnifunc = "syntaxcomplete#Complete"
-- Set LSP omnifunc when language server attaches
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

vim.opt.completeopt = { "menu", "menuone", "noselect", "preview" }
vim.opt.updatetime = 300
vim.diagnostic.config({ float = { border = "rounded" } })

-- Auto-completion with debounce to prevent lag
local completion_timer = nil
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    -- Don't trigger if completion menu is already visible
    if vim.fn.pumvisible() == 1 then return end

    if vim.bo.omnifunc ~= "" then
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true),
        "n",
        true
      )
    end
    -- Cancel previous timer to debounce
    if completion_timer then
      vim.fn.timer_stop(completion_timer)
    end

    -- Trigger completion after a short delay (150ms)
    completion_timer = vim.fn.timer_start(150, function()
      if vim.api.nvim_get_mode().mode ~= "i" then return end

      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local char_before = col > 0 and line:sub(col, col) or ""

      -- Trigger on word characters, dot, or colon (for method calls)
      if char_before:match("[%w_%.:]") then
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true),
          "n",
          true
        )
      end
    end)
  end,
})

-- <C-Space> triggers signature help only when inside a function
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    -- Close completion menu first
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<C-e>", true, false, true),
      "n",
      true
    )
  end

  -- Check if cursor is inside function parentheses
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Look backwards for opening parenthesis
  local before_cursor = line:sub(1, col)

  -- Count parentheses to determine if we're inside a function call
  local open_count = select(2, before_cursor:gsub("%(", ""))
  local close_count = select(2, before_cursor:gsub("%)", ""))

  -- Only show signature help if we're inside parentheses
  if open_count > close_count then
    vim.lsp.buf.signature_help()
  end
end, { desc = "Show function signature (only inside function calls)" })
