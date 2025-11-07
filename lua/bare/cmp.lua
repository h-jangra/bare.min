vim.opt.pumheight = 10
vim.opt.pumwidth = 20
vim.opt.shortmess:append("c") -- Hide redundant completion messages
vim.opt.pumblend = 10
vim.opt.winblend = 10
vim.opt.pumborder = "rounded"
vim.opt.completeopt = { "menuone", "noselect", "noinsert" }

local icons = {
  Text = "󰉿",
  Method = "󰆧",
  Function = "󰊕",
  Constructor = "",
  Field = "󰜢",
  Variable = "󰀫",
  Class = "󰠱",
  Interface = "",
  Module = "󰕳",
  Property = "󰜢",
  Unit = "󰑭",
  Value = "󰎠",
  Enum = "",
  Keyword = "󰌋",
  Snippet = "",
  Color = "󰏘",
  File = "󰈙",
  Reference = "󰈇",
  Folder = "󰉋",
  EnumMember = "",
  Constant = "",
  Struct = "󰙅",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰊄",
}

local function format_completion(item)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Unknown"
  local icon = icons[kind] or "?"
  local label = item.label:gsub("%s*%b()", ""):gsub("%s*%b<>", "")
  return {
    abbr = string.format("%s %s", icon, label),
    word = item.insertText or item.label,
    kind = kind,
    menu = (item.detail or ""):sub(1, 30),
  }
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
        convert = format_completion,
      })
    end
  end,
})

local function trigger_completion()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  if col == 0 or not line:sub(col, col):match("[%w_]") then return end

  vim.fn.feedkeys(vim.keycode("<C-x><C-o>"), "n")
  vim.defer_fn(function()
    if vim.fn.pumvisible() == 0 then return end
    vim.fn.feedkeys(vim.keycode("<C-x><C-n>"), "n")
  end, 50)
end

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = trigger_completion,
})

vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-e>")
  end
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local text_before = line:sub(1, col)
  if text_before:match("%([^)]*$") then
    vim.lsp.buf.signature_help()
  else
    trigger_completion()
  end
end, { expr = true, silent = true, desc = "Completion or signature help" })

-- Show sign help after (
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    if line:sub(col, col) == "(" then
      vim.defer_fn(function()
        if vim.fn.mode() == "i" then vim.lsp.buf.signature_help() end
      end, 30)
    end
  end,
})

vim.keymap.set("i", "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.schedule(function() vim.snippet.jump(1) end)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<Tab>"
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.schedule(function() vim.snippet.jump(-1) end)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<S-Tab>"
  end
end, { expr = true, silent = true })
