local icons = require("bare.icons")

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return (ok and hl) and hl or {}
end

local function setup_highlights()
  local tab_sel = get_hl("TabLineSel")
  local warn = get_hl("DiagnosticSignHint")

  local active_bg = tab_sel.bg or tab_sel.fg

  vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })

  vim.api.nvim_set_hl(0, "WinBarActive", { fg = tab_sel.fg, bg = active_bg, bold = true })
  vim.api.nvim_set_hl(0, "WinBarActiveCap", { fg = active_bg, bg = "NONE" })

  vim.api.nvim_set_hl(0, "WinBarInactive", { fg = tab_sel.bg, bg = tab_sel.fg })
  vim.api.nvim_set_hl(0, "WinBarInactiveCap", { fg = tab_sel.fg, bg = "NONE", })

  vim.api.nvim_set_hl(0, "WinBarModifiedActive", { fg = tab_sel.fg, bg = active_bg })
  vim.api.nvim_set_hl(0, "WinBarModifiedActiveCap", { fg = active_bg, bg = "NONE" })

  vim.api.nvim_set_hl(0, "WinBarModifiedInactive", { fg = warn.fg, bg = tab_sel.fg, italic = true })
  vim.api.nvim_set_hl(0, "WinBarModifiedInactiveCap", { fg = tab_sel.fg, bg = "NONE", })
end
setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })

_G.goto_buf = function(buf) vim.api.nvim_set_current_buf(buf) end

local function valid_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].buflisted then return false end
  if vim.bo[buf].buftype ~= "" or vim.bo[buf].filetype == "filetree" then return false end

  local name = vim.api.nvim_buf_get_name(buf)
  if name:find("^term://") then return false end

  return true
end

local function get_valid_bufs()
  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if valid_buf(b) then
      table.insert(bufs, b)
    end
  end
  return bufs
end

function _G.winbar_buffers()
  local cur = vim.api.nvim_get_current_buf()
  local parts = {}

  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if valid_buf(b) then
      local path = vim.api.nvim_buf_get_name(b)
      local name = path == "" and "Untitled" or vim.fn.fnamemodify(path, ":t")
      local icon = icons.get_icon(vim.bo[b].filetype) or "󰈤"
      local is_cur = (b == cur)
      local is_mod = vim.bo[b].modified

      local group = is_cur and (is_mod and "WinBarModifiedActive" or "WinBarActive")
          or (is_mod and "WinBarModifiedInactive" or "WinBarInactive")
      local cap = group .. "Cap"
      parts[#parts + 1] = string.format("%%%d@v:lua.goto_buf@%%#%s#%%#%s#%s %s%%#%s#%%X",
        b, cap, group, icon, name, cap)
    end
  end

  return table.concat(parts, "") .. "%#Normal#"
end

local function update(ev)
  if ev and (ev.event == "BufDelete" or ev.event == "BufWipeout" or ev.event == "BufUnload") then
    return vim.schedule(update)
  end

  local valid_bufs = get_valid_bufs()
  local show_winbar = #valid_bufs > 1

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == "" and vim.bo[buf].buftype == "" and show_winbar then
        vim.wo[win].winbar = "%{%v:lua.winbar_buffers()%}"
      else
        vim.wo[win].winbar = nil
      end
    end
  end
end

vim.api.nvim_create_autocmd(
  { "BufAdd", "BufDelete", "BufWipeout", "BufUnload", "BufEnter", "BufModifiedSet", "WinEnter", "BufWinEnter" },
  { callback = update })

update()
