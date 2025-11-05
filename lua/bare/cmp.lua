vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }

local debounce_timer = vim.uv.new_timer()
local debounce_ms = 150

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
        convert = function(item)
          return {
            kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Unknown",
          }
        end,
      })
    end
  end,
})

local function trigger_completion()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local char = line:sub(col, col)
  if char:match("[%w]") and vim.fn.pumvisible() == 0 then
    vim.lsp.completion.get()
    vim.defer_fn(function()
      if vim.fn.pumvisible() == 0 then
        vim.api.nvim_feedkeys(vim.keycode("<C-x><C-n>"), "n", false)
      end
    end, 50)
  end
end

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if debounce_timer then
      debounce_timer:stop()
      debounce_timer:start(debounce_ms, 0, vim.schedule_wrap(trigger_completion))
    end
  end,
})

vim.keymap.set("i", "<C-Space>", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if line:sub(1, col):match("%(") then
    vim.lsp.buf.signature_help()
  else
    trigger_completion()
  end
end, { noremap = true, silent = true })

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
