vim.opt.completeopt = { "menu", "menuone", "noselect" }

local function has_lsp()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end

local timer = vim.uv.new_timer()

local function restart_timer(timeout, cb)
  if not timer or timer:is_closing() then
    timer = vim.uv.new_timer()
  end

  if timer then
    timer:stop()
    timer:start(timeout, 0, vim.schedule_wrap(cb))
  end
end

vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e>"
  end

  if not has_lsp() then
    return "<C-n>"
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)

  if before:match("%(") and not before:match("%)") then
    vim.lsp.buf.signature_help()
    return ""
  end

  return "<C-x><C-o>"
end, { expr = true, silent = true })

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if vim.fn.pumvisible() == 1 or not has_lsp() then
      return
    end

    if timer and not timer:is_closing() then
      timer:stop()
    end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local char = line:sub(col, col)

    if char:match("[%w_.:>]") then
      restart_timer(100, function()
        if vim.fn.pumvisible() == 0 and vim.api.nvim_get_mode().mode == "i" then
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true),
            "n",
            false
          )
        end
      end)
    end
  end,
})

vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, silent = true })

vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, silent = true })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})
