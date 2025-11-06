vim.opt.pumheight = 10
vim.opt.pumwidth = 20
vim.opt.shortmess:append("c")
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

local debounce_timer = vim.uv.new_timer()
local debounce_ms = 100
local last_col = nil

local function trigger_completion()
  if vim.fn.mode() ~= "i" then return end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  if last_col == col and vim.fn.pumvisible() == 1 then return end
  last_col = col

  if col == 0 or not line:sub(col, col):match("[%w_]") then return end

  vim.fn.feedkeys(vim.keycode("<C-x><C-o>"), "n")
  vim.defer_fn(function()
    if vim.fn.pumvisible() == 0 then
      vim.fn.feedkeys(vim.keycode("<C-x><C-n>"), "n")
    end
  end, 30)
end

-- Set up LSP completion
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, {
        convert = format_completion,
      })
    end
  end,
})

-- Auto-completion triggers
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
    if debounce_timer then
      debounce_timer:stop()
    end
    last_col = nil
    if vim.fn.pumvisible() == 1 then
      vim.api.nvim_feedkeys(vim.keycode("<C-e>"), "n", true)
    end
  end,
})

-- Manual trigger
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
    vim.fn.feedkeys(vim.keycode("<C-x><C-o>"), "n")
  end
end, { expr = true, silent = true, desc = "Trigger LSP completion or signature help" })

vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-n>")
  end
  if vim.snippet and vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1)
    return ""
  end
  return vim.keycode("<Tab>")
end, { expr = true, silent = true, desc = "Completion or snippet jump" })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-p>")
  end
  if vim.snippet and vim.snippet.active({ direction = -1 }) then
    vim.snippet.jump(-1)
    return ""
  end
  return vim.keycode("<S-Tab>")
end, { expr = true, silent = true, desc = "Previous completion or snippet jump" })
