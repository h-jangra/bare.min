local M = {}
M.config = {
  debounce_ms = 100,
  trigger_chars = { '[%w_.]' },
}

local timer = vim.uv.new_timer()

local function has_lsp(buf)
  return #vim.lsp.get_clients({ bufnr = buf }) > 0
end

local function trigger_completion(buf)
  if vim.fn.pumvisible() == 1 then return end
  if has_lsp(buf) then
    vim.lsp.completion.get()
  else
    vim.api.nvim_feedkeys(vim.keycode('<C-x><C-n>'), 'n', false)
  end
end

local function setup_autocmds(buf)
  vim.api.nvim_create_autocmd('TextChangedI', {
    buffer = buf,
    callback = function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local char = line:sub(col, col)
      for _, pattern in ipairs(M.config.trigger_chars) do
        if char:match(pattern) then
          if timer then
            timer:stop()
            timer:start(M.config.debounce_ms, 0, vim.schedule_wrap(function()
              trigger_completion(buf)
            end))
            break
          end
        end
      end
    end,
  })
end

function M.attach(client_id, buf)
  if client_id then
    vim.lsp.completion.enable(true, client_id, buf, { autotrigger = false })
  end
  setup_autocmds(buf)

  vim.keymap.set('i', '<C-Space>', function()
    trigger_completion(buf)
  end, { buffer = buf, silent = true })

  vim.keymap.set('i', '<Up>', function()
    if vim.fn.pumvisible() == 1 then
      vim.api.nvim_feedkeys(vim.keycode('<C-p>'), 'n', false)
    else
      vim.api.nvim_feedkeys(vim.keycode('<Up>'), 'n', false)
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set('i', '<S-Tab>', function()
    if vim.fn.pumvisible() == 1 then
      vim.api.nvim_feedkeys(vim.keycode('<C-n>'), 'n', false)
    else
      vim.api.nvim_feedkeys(vim.keycode('<S-Tab>'), 'n', false)
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set('i', '(', function()
    if has_lsp(buf) then
      vim.lsp.buf.signature_help()
    end
    vim.api.nvim_feedkeys(vim.keycode('('), 'n', false)
  end, { buffer = buf, silent = true })
end

function M.setup(user_config)
  M.config = vim.tbl_deep_extend('force', M.config, user_config or {})
  vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      M.attach(args.data.client_id, args.buf)
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      if #vim.lsp.get_clients({ bufnr = args.buf }) == 0 then
        M.attach(nil, args.buf)
      end
    end,
  })
end

return M
