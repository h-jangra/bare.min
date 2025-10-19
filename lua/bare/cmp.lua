vim.opt.completeopt = { "menu", "menuone", "noselect" }

local lsp_attached = false
local completion_debounce = nil

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    lsp_attached = true
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  callback = function()
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

-- Manual completion trigger
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e>"
  end

  if not lsp_attached then
    return "<C-x><C-n>"
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)

  -- Check if we're inside parentheses for signature help
  if select(2, before:gsub("%(", "")) > select(2, before:gsub("%)", "")) then
    vim.lsp.buf.signature_help()
    return ""
  end

  return "<C-x><C-o>"
end, { expr = true })

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if vim.fn.pumvisible() == 1 then
      return
    end

    if not lsp_attached then
      return
    end

    -- Clear any pending completion
    if completion_debounce then
      completion_debounce:close()
      completion_debounce = nil
    end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, col)
    local char_before = before:sub(-1, -1)

    -- Only trigger completion in specific contexts to reduce LSP calls
    local trigger_chars = {
      ['.'] = true,  -- Object property
      [':'] = true,  -- Type annotation or method call
      ['>'] = true,  -- XML/JSX tag
      ['\\'] = true, -- LaTeX or paths
    }

    -- Word characters and trigger characters
    if char_before:match("[%w_]") or trigger_chars[char_before] then
      completion_debounce = vim.defer_fn(function()
        if vim.fn.pumvisible() == 0 and vim.api.nvim_get_mode().mode == "i" then
          local keys = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end
        completion_debounce = nil
      end, 100) -- 100ms debounce delay
    end
  end,
})

-- Navigation in completion menu
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

vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  else
    return "<CR>"
  end
end, { expr = true })

