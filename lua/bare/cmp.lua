vim.opt.pumheight = 10
vim.opt.pumwidth = 20
vim.opt.shortmess:append("c")
vim.opt.pumborder = "shadow"
vim.opt.completeopt = { "menuone", "noselect" }

local icons = {
  Text = "󰉿",
  Method = "󰆧",
  Function = "󰊕",
  Constructor = "",
  Field = "󰜢",
  Variable = "󰀫",
  Class = "󰠱",
  Interface = "",
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
  Constant = "󰏿",
  Struct = "󰙅",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰊄",
}

local function format_completion(item)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Unknown"
  local label = item.label:gsub("%b()", "")
  return {
    abbr = string.format("%s %s", icons[kind] or "?", label),
    kind = kind,
  }
end

local debounce_timer = vim.uv.new_timer()
local debounce_ms = 150

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
  if vim.fn.mode() ~= "i" then return end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Only trigger on word characters or after specific symbols
  local char_before = line:sub(col - 1, col - 1)
  if not char_before:match("[%w_]") then return end

  vim.lsp.completion.get()
end

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if debounce_timer then
      debounce_timer:stop()
      debounce_timer:start(debounce_ms, 0, vim.schedule_wrap(trigger_completion))
    end
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    if debounce_timer then debounce_timer:stop() end
  end,
})

vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-e>")
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  if line:sub(1, col):match("%(") then
    vim.lsp.buf.signature_help()
  else
    vim.lsp.completion.get()
  end
end, { noremap = true, silent = true })

vim.keymap.set("i", "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.schedule(function() vim.snippet.jump(1) end)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-n>")
  else
    return vim.keycode("<Tab>")
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.schedule(function() vim.snippet.jump(-1) end)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-p>")
  else
    return vim.keycode("<S-Tab>")
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<C-e>", function()
  if vim.fn.pumvisible() == 1 then
    vim.api.nvim_feedkeys(vim.keycode("<C-e>"), "n", false)
  end
end, { noremap = true, silent = true })
