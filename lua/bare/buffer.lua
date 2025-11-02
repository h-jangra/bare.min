local function hl(name, opts) vim.api.nvim_set_hl(0, name, opts) end
local function setup_winbar_highlights()
  hl("WinBarActive", { fg = "#7fb4ca", bg = "#2a2a37", bold = true })
  hl("WinBarInactive", { fg = "#54546d", bg = "#2a2a37", italic = true })
  hl("WinBarModified", { fg = "#2a2a37", bg = "#7fb4ca" })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_winbar_highlights })
setup_winbar_highlights()

local function get_buf_name(bufnr)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
  return name ~= "" and name or "[No Name]"
end

function _G.goto_buf(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_set_current_buf(bufnr) end
end

function _G.winbar_buffers()
  local cur = vim.api.nvim_get_current_buf()
  local parts = {}
  local icons = require("bare.icons")
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted then
      local group = (bufnr == cur)
          and (vim.bo[bufnr].modified and "WinBarModified" or "WinBarActive")
          or (vim.bo[bufnr].modified and "WinBarModified" or "WinBarInactive")
      local icon = icons.get(vim.bo[bufnr].filetype) or "󰈤"
      local name = get_buf_name(bufnr)
      table.insert(parts, string.format("%%%d@v:lua.goto_buf@%%#%s# %s %s %%X%%#Normal#", bufnr, group, icon, name))
    end
  end
  return table.concat(parts)
end

local function update_winbar()
  local cfg = vim.api.nvim_win_get_config(0)
  if cfg.relative ~= "" then
    vim.wo.winbar = nil
    return
  end
  if vim.bo.buftype == "terminal" or vim.bo.buftype == "help" or vim.bo.filetype == "help" then
    vim.wo.winbar = nil
    return
  end
  if vim.bo.filetype == "netrw" or vim.bo.filetype == "filetree" then
    vim.wo.winbar = nil
    return
  end
  local listed = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
      listed = listed + 1
      if listed > 1 then break end
    end
  end
  vim.wo.winbar = listed > 1 and "%{%v:lua.winbar_buffers()%}" or nil
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, { callback = update_winbar })
update_winbar()
