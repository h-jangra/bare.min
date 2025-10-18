vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local hl = vim.api.nvim_set_hl
    hl(0, "WinBarActive", { fg = "#7fb4ca", bold = true })
    hl(0, "WinBarInactive", { fg = "#54546d" })
    hl(0, "WinBarModified", { fg = "#dca561" })
  end,
})
vim.cmd("doautocmd ColorScheme")

local function get_icon(ft)
  local ok, icons = pcall(require, "bare.icons")
  return ok and icons.get(ft) or "󰈚"
end

function _G.get_winbar()
  local cur = vim.api.nvim_get_current_buf()
  local parts = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted then
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
  end

  return table.concat(parts, " ")
end

vim.o.winbar = "%{%v:lua.get_winbar()%}"

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "BufAdd", "BufDelete" }, {
  callback = function()
    vim.schedule(function() vim.cmd.redrawstatus() end)
  end
})
