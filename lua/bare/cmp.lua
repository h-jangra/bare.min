vim.opt.pumheight = 12
vim.opt.shortmess:append("c")
vim.opt.complete = ".,w,b,u"
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }
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
  Event         = "",
  Operator      = "󰆕",
  TypeParameter = "󰊄",
}


local function format_completion(item)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Unknown"
  local label = item.label
  return {
    abbr = string.format("%s %s", icons[kind] or "?", label),
    word = item.label,
    kind = kind,
    menu = item.detail or item.source or "",
  }
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end


    if client and client:supports_method("textDocument/completion") then
      local chars = {}
      for c in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.:=>"):gmatch(".") do
        table.insert(chars, c)
      end
      client.server_capabilities.completionProvider.triggerCharacters = chars

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

vim.api.nvim_create_autocmd("CompleteDone", {
  callback = function()
    local item = vim.v.completed_item
    if not item or not item.user_data then return end

    local completion = item.user_data.nvim and item.user_data.nvim.lsp and item.user_data.nvim.lsp.completion_item
    if not completion then return end

    -- Apply additionalTextEdits (autoimport)
    local edits = completion.additionalTextEdits
    if edits and #edits > 0 then
      local bufnr = vim.api.nvim_get_current_buf()
      local client_id = item.user_data.nvim.lsp.client_id
      local client = vim.lsp.get_client_by_id(client_id)
      if client then
        vim.lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding)
      end
      return
    end

    -- If edits not in item yet, resolve them
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    for _, client in ipairs(clients) do
      if client:supports_method("completionItem/resolve") then
        local result = vim.lsp.buf_request_sync(bufnr, "completionItem/resolve", completion, 500)
        if result then
          for _, res in pairs(result) do
            local resolved = res.result
            if resolved and resolved.additionalTextEdits and #resolved.additionalTextEdits > 0 then
              vim.lsp.util.apply_text_edits(resolved.additionalTextEdits, bufnr, client.offset_encoding)
            end
          end
        end
        break
      end
    end
  end,
})

-- vim.api.nvim_create_autocmd("InsertCharPre", {
--   callback = function()
--     local col = vim.fn.col('.')
--     local ch = vim.v.char
--     if ch:match("[%w_.:]") then
--       vim.defer_fn(function()
--         vim.fn.feedkeys(vim.keycode("<C-x><C-o>"), "n")
--       end, 1)
--     end
--   end,
-- })
