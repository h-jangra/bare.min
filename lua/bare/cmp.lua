vim.opt.completeopt = { "menu", "menuone", "noselect" }

local function has_lsp()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end

-- For debounce completion
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

-- Trigger signature_help in function
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then return "<C-e>" end
  if not has_lsp() then return "<C-x><C-n>" end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  if line:sub(1, col):match("%(") and not line:sub(1, col):match("%)") then
    vim.lsp.buf.signature_help()
    return ""
  end

  return "<C-x><C-o>"
end, { expr = true, silent = true })

-- Auto-trigger completion on typing
vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if vim.fn.pumvisible() == 1 or not has_lsp() then return end

    if timer and not timer:is_closing() then timer:stop() end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    -- Trigger on word characters and common trigger characters
    if line:sub(col, col):match("[%w_.:>]") then
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

-- PUM navigation
for _, k in ipairs({ "Down", "Up", "CR" }) do
  local rhs = k == "Down" and "<C-n>" or k == "Up" and "<C-p>" or "<C-y>"
  vim.keymap.set("i", k, function()
    return vim.fn.pumvisible() == 1 and rhs or (k == "CR" and "<CR>" or "<" .. k .. ">")
  end, { expr = true, silent = true })
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
})
