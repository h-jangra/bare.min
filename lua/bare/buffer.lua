local function setup_winbar_highlights()
  local hl = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end

  hl("WinBarActive", { fg = "#7fb4ca", bg = "#2a2a37", bold = true })
  hl("WinBarInactive", { fg = "#54546d", bg = "#2a2a37" })
  hl("WinBarModified", { fg = "#2a2a37", bg = "#7fb4ca", bold = true })
  hl("WinBarModifiedInactive", { fg = "#54546d", bg = "#454555" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = setup_winbar_highlights
})
setup_winbar_highlights()

local function get_buf_name(bufnr)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
  return name == "" and "[No Name]" or name
end

function _G.winbar_buffers()
  local cur, parts = vim.api.nvim_get_current_buf(), {}
  local icons = require("bare.icons")

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted then
      local is_cur, is_mod = bufnr == cur, vim.bo[bufnr].modified

      local group = is_cur and (is_mod and "WinBarModified" or "WinBarActive")
          or (is_mod and "WinBarModifiedInactive" or "WinBarInactive")

      local icon = icons.get(vim.bo[bufnr].filetype) or "󰈚"
      local name = get_buf_name(bufnr)

      table.insert(parts, string.format(
        "%%%d@v:lua.goto_buf@%%#%s# %s %s %%X",
        bufnr, group, icon, name
      ))
    end
  end

  return table.concat(parts, "")
end

local function update_winbar()
  local win_config = vim.api.nvim_win_get_config(0)
  local is_special_win = win_config.relative ~= "" or vim.bo.buftype == "terminal"

  if is_special_win then
    vim.wo.winbar = nil
    return
  end

  local listed_count = 0
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
      listed_count = listed_count + 1
      if listed_count > 1 then break end
    end
  end

  vim.wo.winbar = listed_count > 1 and "%{%v:lua.winbar_buffers()%}" or nil
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
  callback = update_winbar
})

update_winbar()
