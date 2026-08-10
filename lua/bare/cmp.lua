vim.opt.pumheight   = 10
vim.opt.complete    = { ".", "w", "b", "u" }
vim.opt.completeopt = { "menuone", "noinsert", "noselect", "popup" }
vim.opt.pumborder   = "rounded"
-- vim.o.autocomplete      = true
-- vim.o.autocompletedelay = 0

local icons         = {
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

local function format(item)
  local kinds = vim.lsp.protocol.CompletionItemKind
  return {
    abbr = (icons[kinds[item.kind]] or "") .. " " .. item.label,
    kind = kinds[item.kind],
  }
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true, convert = format })
    end
  end,
})

vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get)

vim.keymap.set("i", "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<Tab>"
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.snippet.jump(-1)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<S-Tab>"
  end
end, { expr = true, silent = true })

-- vim.keymap.set("i", "<CR>", function()
--   if vim.fn.complete_info().selected ~= -1 then
--     return vim.keycode("<C-y>")
--   end
--   return vim.keycode("<CR>")
-- end, { expr = true, silent = true })

vim.api.nvim_create_autocmd("InsertCharPre", {
  callback = function()
    vim.lsp.completion.get()
  end,
})
