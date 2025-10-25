vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local hl = vim.api.nvim_set_hl
    hl(0, "WinBarActive", { fg = "#7fb4ca", bold = true })
    hl(0, "WinBarInactive", { fg = "#7f849c" })
    hl(0, "WinBarModified", { fg = "#fab387" })
  end,
})
vim.cmd("doautocmd ColorScheme")

local function get_icon(ft)
  local ok, icons = pcall(require, "bare.icons")
  return ok and icons.get(ft) or "󰈚"
end

function _G.update_winbar()
  local listed_bufs = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted then
      table.insert(listed_bufs, bufnr)
    end
  end

  if #listed_bufs <= 1 then
    vim.wo.winbar = nil -- disable winbar for single buffer
    return
  end

  local cur = vim.api.nvim_get_current_buf()
  local parts = {}

  for _, bufnr in ipairs(listed_bufs) do
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    name = name ~= "" and name or "[No Name]"

    local hl = vim.bo[bufnr].modified and "WinBarModified"
        or bufnr == cur and "WinBarActive"
        or "WinBarInactive"

    local icon = get_icon(vim.bo[bufnr].filetype)

    local func_name = "switch_to_buffer_" .. bufnr
    _G[func_name] = function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_set_current_buf(bufnr)
      end
    end

    table.insert(parts, string.format(
      " %%%d@v:lua.%s@%%#%s#%s %s",
      bufnr, func_name, hl, icon, name
    ))
  end

  vim.wo.winbar = table.concat(parts, " ")
end

_G.update_winbar()

vim.api.nvim_create_autocmd(
  { "BufEnter", "BufWritePost", "BufAdd", "BufDelete", "WinEnter" },
  { callback = function() vim.schedule(_G.update_winbar) end }
)
