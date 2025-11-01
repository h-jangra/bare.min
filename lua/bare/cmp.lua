vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
    end
  end,
})

local timer = vim.uv.new_timer()
vim.api.nvim_create_autocmd('TextChangedI', {
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    if line:sub(col, col):match('[%w_.]') then
      if timer then
        timer:stop()
        timer:start(100, 0, vim.schedule_wrap(function()
          if vim.fn.pumvisible() == 0 then
            local has_lsp = #vim.lsp.get_clients({ bufnr = 0 }) > 0
            if has_lsp then
              vim.lsp.completion.get()
              vim.defer_fn(function()
                if vim.fn.pumvisible() == 0 then
                  vim.api.nvim_feedkeys(vim.keycode('<C-x><C-n>'), 'n', false)
                end
              end, 80)
            else
              vim.api.nvim_feedkeys(vim.keycode('<C-x><C-n>'), 'n', false)
            end
          end
        end))
      end
    end
  end,
})

vim.keymap.set('i', '<C-Space>', function()
  if vim.fn.pumvisible() == 1 then return '<C-e>' end
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 and line:sub(1, col):match('%(') and not line:sub(1, col):match('%)') then
    vim.lsp.buf.signature_help()
  else
    vim.lsp.completion.get()
  end
  return ''
end, { expr = true, silent = true })

vim.keymap.set('i', '<Tab>', function()
  return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>'
end, { expr = true, silent = true })

vim.keymap.set('i', '<S-Tab>', function()
  return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>'
end, { expr = true, silent = true })
