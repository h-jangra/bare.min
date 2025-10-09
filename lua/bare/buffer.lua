vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local function hl(name, opts) vim.api.nvim_set_hl(0, name, opts) end
    hl("WinBarActive", { fg = "#7fb4ca", bg = "#2a2a37", bold = true })
    hl("WinBarInactive", { fg = "#54546d", bg = "#2a2a37" })
    hl("WinBarModified", { fg = "#2a2a37", bg = "#7fb4ca", bold = true })
    hl("WinBarModifiedInactive", { fg = "#54546d", bg = "#454555" })
    hl("WinBarIconActive", { fg = "#7fb4ca", bg = "#2a2a37" })
    hl("WinBarIconModified", { fg = "#2a2a37", bg = "#7fb4ca" })
    hl("WinBarIconInactive", { fg = "#727289", bg = "#2a2a37" })
    hl("WinBarIconModifiedInactive", { fg = "#727289", bg = "#454555" })
    hl("WinBarSep", { fg = "#54546d", bg = "#2a2a37" })
  end,
})

vim.cmd("doautocmd ColorScheme")

local icons = require("bare.icons")

function _G.winbar_goto_buf(bufnr, _)
  if vim.api.nvim_buf_is_loaded(bufnr) then
    vim.api.nvim_set_current_buf(bufnr)
  end
end

function _G.winbar_buffers()
  local cur = vim.api.nvim_get_current_buf()
  local bufs = vim.api.nvim_list_bufs()
  local parts = {}

  for _, bufnr in ipairs(bufs) do
    if vim.bo[bufnr].buflisted then
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
      if name == "" then name = "[No Name]" end

      local is_mod = vim.bo[bufnr].modified
      local is_cur = bufnr == cur

      local group, icon_group
      if is_cur and is_mod then
        group = "WinBarModified"
        icon_group = "WinBarIconModified"
      elseif is_cur then
        group = "WinBarActive"
        icon_group = "WinBarIconActive"
      elseif is_mod then
        group = "WinBarModifiedInactive"
        icon_group = "WinBarIconModifiedInactive"
      else
        group = "WinBarInactive"
        icon_group = "WinBarIconInactive"
      end

      local icon = icons.get(vim.bo[bufnr].filetype) or "󰈚"
      local icon_segment = string.format("%%#%s#%s ", icon_group, icon)

      -- Segment
      local segment = string.format(
        "%%%d@v:lua.winbar_goto_buf@%%#%s# %s%s %%#Normal#",
        bufnr, group, icon_segment, name
      )

      table.insert(parts, segment)
    end
  end

  return table.concat(parts)
end

vim.o.winbar = "%{%v:lua.winbar_buffers()%}"

vim.api.nvim_create_autocmd(
  { "BufEnter", "BufWinEnter", "BufWritePost", "TabEnter", "WinEnter", "BufModifiedSet" },
  { callback = function() vim.cmd("redrawstatus") end }
)
