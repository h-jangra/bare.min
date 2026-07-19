local function setup_highlights()
  vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarActive", { link = "TabLineSel" })
  vim.api.nvim_set_hl(0, "WinBarInactive", { link = "TabLine" })
  vim.api.nvim_set_hl(0, "WinBarModifiedActive", { link = "TabLineSel" })
  vim.api.nvim_set_hl(0, "WinBarModifiedInactive", { link = "TabLine" })
end
setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })

local function bufname(buf)
  return vim.fn.fnamemodify(
    vim.api.nvim_buf_get_name(buf),
    ":t"
  )
end

function _G.goto_buf(buf) vim.api.nvim_set_current_buf(buf) end

local function valid_buf(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return vim.bo[buf].buflisted
      and vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buftype == ""
      and name ~= ""
      and not name:find("^term://")
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
    local is_cur = (b == cur)
    local is_mod = vim.bo[b].modified
    local group = is_cur and (is_mod and "WinBarModifiedActive" or "WinBarActive")
                       or (is_mod and "WinBarModifiedInactive" or "WinBarInactive")

    local mod_flag = is_mod and " ●" or ""

    parts[#parts + 1] = string.format(
      "%%%d@v:lua.goto_buf@%%#%s# %s %s%s %%X",
      b, group,
      info.icon,
      info.name,
      mod_flag
    )
  end

  return table.concat(parts) .. "%#Normal#"
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

  vim.wo.winbar = count > 0
      and "%{%v:lua.winbar_buffers()%}"
      or nil
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "BufModifiedSet", "OptionSet" }, { callback = update })
update()
