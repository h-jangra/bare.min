vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.complete = { ".", "w", "b", "u", "t", "s", "i" }

local timer = vim.uv.new_timer()

local function has_lsp()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if vim.fn.pumvisible() == 1 then return end
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local char = line:sub(col, col)
    if char:match("[%w_]") or (col > 0 and line:sub(col - 1, col - 1) == ".") then
      if timer then
        timer:stop()
        timer:start(150, 0, vim.schedule_wrap(function()
          if vim.fn.pumvisible() == 0 and vim.api.nvim_get_mode().mode == "i" then
            vim.api.nvim_feedkeys(vim.keycode(has_lsp() and "<C-x><C-o>" or "<C-x><C-n>"), "n", false)
            if has_lsp() then
              vim.defer_fn(function()
                if vim.fn.pumvisible() == 0 then
                  vim.api.nvim_feedkeys(vim.keycode("<C-x><C-n>"), "n", false)
                end
              end, 50)
            end
          end
        end))
      end
    end
  end,
})

-- Ctrl+Space for manual completion or signature help
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-e>")
  end
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if line:sub(1, col):match("%(") and not line:sub(1, col):match("%)") then
    vim.lsp.buf.signature_help()
  else
    vim.lsp.completion.get()
  end
  return ""
end, { expr = true, silent = true })

vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, silent = true })

vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, silent = true })
