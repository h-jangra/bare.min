vim.api.nvim_set_hl(0, "WinBarActive", { fg = "#7fb4ca", bg = "#2a2a37", bold = true })
vim.api.nvim_set_hl(0, "WinBarInactive", { fg = "#54546d", bg = "#2a2a37", italic = true })
vim.api.nvim_set_hl(0, "WinBarModified", { fg = "#2a2a37", bg = "#7fb4ca" })

local function bufname(buf)
  return vim.fn.fnamemodify(
    vim.api.nvim_buf_get_name(buf),
    ":t"
  )
end

function _G.goto_buf(buf) vim.api.nvim_set_current_buf(buf) end

local function valid_buf(buf)
  return vim.bo[buf].buflisted
      and vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
end

local icons = require("bare.icons")
local buf_cache = {}

local function update_buf_cache()
  buf_cache = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if valid_buf(b) then
      table.insert(buf_cache, {
        id = b,
        icon = icons.get_icon(vim.bo[b].filetype) or "󰈤",
        name = bufname(b),
      })
    end
  end
end

function _G.winbar_buffers()
  local cur = vim.api.nvim_get_current_buf()
  local parts = {}

  for _, info in ipairs(buf_cache) do
    local b = info.id
    local group =
        (b == cur)
        and (vim.bo[b].modified and "WinBarModified" or "WinBarActive")
        or (vim.bo[b].modified and "WinBarModified" or "WinBarInactive")

    parts[#parts + 1] = string.format(
      "%%%d@v:lua.goto_buf@%%#%s# %s %s %%X%%#Normal#",
      b, group,
      info.icon,
      info.name
    )
  end

  return table.concat(parts)
end

local function update()
  update_buf_cache()
  local cfg = vim.api.nvim_win_get_config(0)

  if cfg.relative ~= ""
      or vim.bo.filetype == "filetree"
      or vim.bo.buftype ~= ""
  then
    vim.wo.winbar = nil
    return
  end

  local count = #buf_cache

  vim.wo.winbar = count > 1
      and "%{%v:lua.winbar_buffers()%}"
      or nil
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "BufModifiedSet", "OptionSet" }, { callback = update })
update()
