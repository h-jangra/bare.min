vim.opt.pumheight = 10
vim.opt.shortmess:append("c")
-- vim.opt.complete = ".,w,b,u"
vim.opt.completeopt = { "menuone", "noinsert", "noselect" }
vim.opt.pumborder = "rounded"

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
  Event         = "",
  Operator      = "󰆕",
  TypeParameter = "󰊄",
}


local function format_completion(item)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Unknown"
  local label = item.label
  return {
    abbr = (icons[kind] or "?") .. " " .. label,
    word = item.label,
    menu = item.detail or item.source or "",
  }
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    if client and client:supports_method("textDocument/completion") then
      -- local chars = {}
      -- for c in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"):gmatch(".") do
      --   table.insert(chars, c)
      -- end
      -- client.server_capabilities.completionProvider.triggerCharacters = chars

      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
        convert = format_completion,
      })
    end
  end,
})

vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then return vim.keycode("<C-e>") end
  local text_before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
  if text_before:match("%([^)]*$") then
    vim.lsp.buf.signature_help()
  else
    vim.lsp.completion.get()
  end

  return vim.keycode("")
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

vim.keymap.set("i", "<CR>", function()
  if vim.fn.complete_info()["selected"] ~= -1 then
    return vim.keycode("<C-y>")
  end
  return vim.keycode("<CR>")
end, { expr = true, silent = true })

vim.api.nvim_create_autocmd("InsertCharPre", {
  callback = function()
    if vim.fn.pumvisible() == 1 then return end
    if vim.fn.match(vim.v.char, '[[:keyword:]]') < 0 then return end
    vim.schedule(function()
      vim.lsp.completion.get()
    end)
  end,
})
