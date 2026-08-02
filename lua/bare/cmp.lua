vim.opt.pumheight = 10
vim.opt.shortmess:append("c")
vim.opt.complete = { ".", "w", "b", "u" }
vim.opt.completeopt = { "menuone", "noinsert", "noselect", "popup" }
vim.opt.pumborder = "rounded"

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
  EnumMember = "󰒻",
  Constant = "󰏿",
  Struct = "󰙅",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰊄",
}

local function format(item)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind]
  return { abbr = item.label, kind = icons[kind] or "", menu = item.detail }
end

local function complete_buffer()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  local base = line:sub(1, col):match("[%w_]+$")
  if not base or #base < 2 then return end

  local matches, seen = {}, { [base] = true }
  local bufs = { vim.api.nvim_get_current_buf() }
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= bufs[1] and vim.api.nvim_buf_is_loaded(b) then table.insert(bufs, b) end
  end

  for _, b in ipairs(bufs) do
    for _, l in ipairs(vim.api.nvim_buf_get_lines(b, 0, -1, false)) do
      for w in l:gmatch("[%w_]+") do
        if #w >= 3 and w:sub(1, #base) == base and not seen[w] then
          seen[w] = true
          table.insert(matches, { word = w, abbr = w, kind = icons.Text })
          if #matches >= 25 then break end
        end
      end
      if #matches >= 25 then break end
    end
    if #matches >= 25 then break end
  end

  if #matches > 0 and vim.fn.pumvisible() == 0 then
    vim.fn.complete(col - #base + 1, matches)
  end
end

local function trigger_completion()
  if vim.fn.pumvisible() == 1 then return end
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.get()
      break
    end
  end
  complete_buffer()
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true, convert = format })
    end
  end,
})

-- Keymaps
vim.keymap.set("i", "<C-Space>", trigger_completion)

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
    if vim.fn.match(vim.v.char, "[[:keyword:]]") < 0 then return end
    vim.schedule(trigger_completion)
  end,
})
