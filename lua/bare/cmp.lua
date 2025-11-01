vim.opt.completeopt = { "menu", "menuone", "noselect" }

local uv = vim.uv
local timer = uv.new_timer()
local completing = false

local function debounce(ms, fn)
  if timer and not timer:is_closing() then timer:stop() end
  if timer then timer:start(ms, 0, vim.schedule_wrap(fn)) end
end

local function has_lsp()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end

local function trigger_completion()
  if completing or vim.fn.pumvisible() == 1 then return end
  completing = true

  if has_lsp() then
    vim.lsp.completion.get({ bufnr = 0 })
    vim.defer_fn(function()
      if vim.fn.pumvisible() == 0 then
        vim.api.nvim_feedkeys(vim.keycode("<C-x><C-n>"), "n", false)
      end
      completing = false
    end, 80)
  else
    vim.api.nvim_feedkeys(vim.keycode("<C-x><C-n>"), "n", false)
    completing = false
  end
end

-- Enable LSP completion on attach
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      vim.lsp.completion.enable(true, args.data.client_id, args.buf, {
        autotrigger = true
      })
    end
  end,
})

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local char = line:sub(col, col)
    if char:match("[%w_.]") then debounce(100, trigger_completion) end
  end,
})

vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then return "<C-e>" end
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if has_lsp() and line:sub(1, col):match("%(") and not line:sub(1, col):match("%)") then
    vim.lsp.buf.signature_help()
  else
    trigger_completion()
  end
  return ""
end, { expr = true, silent = true })

vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, silent = true })

vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, silent = true })
