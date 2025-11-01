vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.complete = { ".", "w", "b", "u", "t", "s", "i" }

local timer = vim.uv.new_timer()
local is_completing = false

local function debounce(ms, fn)
  if timer and not timer:is_closing() then timer:stop() else timer = vim.uv.new_timer() end
  if timer then timer:start(ms, 0, vim.schedule_wrap(fn)) end
end

local function has_lsp()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if vim.fn.pumvisible() == 1 or is_completing then return end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local char = line:sub(col, col)
    local prev = col > 1 and line:sub(col - 1, col - 1) or ""

    if char:match("[%w_]") or prev == "." then
      debounce(100, function()
        if vim.fn.pumvisible() == 1 or vim.api.nvim_get_mode().mode ~= "i" then return end

        is_completing = true
        if has_lsp() then
          pcall(vim.lsp.completion.trigger)

          vim.defer_fn(function()
            if vim.fn.pumvisible() == 0 and vim.api.nvim_get_mode().mode == "i" then
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-n>", true, false, true), "n", false)
            end
            is_completing = false
          end, 50)
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-n>", true, false, true), "n", false)
          is_completing = false
        end
      end)
    end
  end,
})

vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then return "<C-e>" end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  if has_lsp() and line:sub(1, col):match("%(") and not line:sub(1, col):match("%)") then
    vim.lsp.buf.signature_help()
  end
  return ""
end, { expr = true, silent = true })

vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, silent = true })

vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, silent = true })
