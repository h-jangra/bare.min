local timer = vim.uv.new_timer()
local debounce_ms = 80
local last_line = ""
local last_col = 0

vim.opt.completeopt = { "menu", "menuone", "noselect" }

local function show_signature()
  vim.lsp.buf.signature_help()
end

local function trigger_completion()
  if vim.fn.pumvisible() == 0 then
    vim.api.nvim_feedkeys(vim.keycode("<C-x><C-n>"), "n", false)
  end
end

local function should_trigger_completion(line, col)
  return col > 0
      and line:sub(col, col):match("[%w_]")
      and (line ~= last_line or col ~= last_col)
end

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    if should_trigger_completion(line, col) then
      last_line, last_col = line, col
      if timer then
        timer:stop()
        timer:start(debounce_ms, 0, vim.schedule_wrap(trigger_completion))
      end
    end
  end,
})

vim.api.nvim_create_autocmd("CompleteDone", {
  callback = function()
    local item = vim.v.completed_item
    if item and item.user_data then
      pcall(function()
        local ok, data = pcall(vim.json.decode, item.user_data)
        if ok and data.snippet then
          vim.snippet.expand(data.snippet)
        end
      end)
    end
  end,
})

vim.keymap.set("i", "<C-Space>", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if line:sub(1, col):match("%(") then
    show_signature()
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
end, { expr = true })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.schedule(function() vim.snippet.jump(-1) end)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<S-Tab>"
  end
end, { expr = true })
