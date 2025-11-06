vim.opt.pumheight = 15
vim.opt.pumwidth = 25
vim.opt.shortmess:append("c") -- Hide redundant completion messages
vim.opt.pumblend = 10
vim.opt.winblend = 10
vim.opt.pumborder = "rounded"
vim.opt.completeopt = { "menuone", "noselect", "noinsert", "preview" }

local icons = {
  Text          = "󰉿",
  Method        = "󰆧",
  Function      = "󰊕",
  Constructor   = "",
  Field         = "󰜢",
  Variable      = "󰀫",
  Class         = "󰠱",
  Interface     = "",
  Module        = "󰕳",
  Property      = "󰜢",
  Unit          = "󰑭",
  Value         = "󰎠",
  Enum          = "",
  Keyword       = "󰌋",
  Snippet       = "",
  Color         = "󰏘",
  File          = "󰈙",
  Reference     = "󰈇",
  Folder        = "󰉋",
  EnumMember    = "󰒻",
  Constant      = "󰏿",
  Struct        = "󰙅",
  Event         = "",
  Operator      = "󰆕",
  TypeParameter = "󰊄",
}

local debounce_timer = vim.uv.new_timer()
local last_col = nil

local function format_completion(item)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Unknown"
  local label = item.label:gsub("%s*%b()", "")
  return {
    abbr = string.format("%s %s", icons[kind] or "?", label),
    word = item.insertText or item.label,
    kind = kind,
    menu = item.detail or item.source or "",
  }
end

local function trigger_completion()
  if vim.fn.mode() ~= "i" or vim.fn.pumvisible() == 1 then return end
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if last_col == col then return end

  local line = vim.api.nvim_get_current_line()
  if not line:sub(math.max(1, col), col):match("[%w_.:>-]") then return end

  last_col = col
  vim.fn.feedkeys(vim.keycode("<C-x><C-o>"), "n")
  vim.defer_fn(function()
    if vim.fn.pumvisible() == 0 then
      vim.fn.feedkeys(vim.keycode("<C-x><C-n>"), "n")
    end
  end, 30)
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { convert = format_completion })
    end
  end,
})

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if debounce_timer then
      debounce_timer:stop()
      debounce_timer:start(100, 0, vim.schedule_wrap(trigger_completion))
    end
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    if debounce_timer then debounce_timer:stop() end
    last_col = nil
    if vim.fn.pumvisible() == 1 then
      vim.api.nvim_feedkeys(vim.keycode("<C-e>"), "n", true)
    end
  end,
})

vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then return vim.keycode("<C-e>") end
  local text_before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
  if text_before:match("%([^)]*$") then
    vim.lsp.buf.signature_help()
  else
    vim.fn.feedkeys(vim.keycode("<C-x><C-o>"), "n")
  end
end, { expr = true, silent = true, desc = "Completion or signature help" })

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
