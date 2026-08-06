local icons = require("bare.icons")

local function setup_highlights()
  local tab_sel = vim.api.nvim_get_hl(0, { name = "TabLineSel", link = false })
  local active_bg = tab_sel.bg or tab_sel.fg
  vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarActive", { fg = tab_sel.fg, bg = active_bg, bold = true })
  vim.api.nvim_set_hl(0, "WinBarInactive", { fg = tab_sel.bg, bg = tab_sel.fg })
end
setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })

_G.goto_buf = function(buf) vim.api.nvim_set_current_buf(buf) end

local function get_valid_bufs()
  return vim.iter(vim.api.nvim_list_bufs()):filter(function(b)
    return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
  end):totable()
end

function _G.winbar_buffers()
  local cur = vim.api.nvim_get_current_buf()
  local valid = get_valid_bufs()

  local parts = vim.iter(valid):map(function(b)
    local path = vim.api.nvim_buf_get_name(b)
    local name = path == "" and "Untitled" or vim.fs.basename(path)
    local icon = icons.get_icon(vim.bo[b].filetype) or "󰈤"
    local hl = (b == cur) and "WinBarActive" or "WinBarInactive"
    local mod = vim.bo[b].modified and " 󱇬" or ""

    return string.format("%%%d@v:lua.goto_buf@%%#%s# %s %s%s %%X", b, hl, icon, name, mod)
  end):totable()

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
      if cfg.relative == "" and vim.bo[buf].buflisted and show_winbar then
        vim.wo[win].winbar = "%{%v:lua.winbar_buffers()%}"
      else
        vim.wo[win].winbar = ""
      end
    end
  end
end

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(ev) vim.bo[ev.buf].buflisted = false end,
})

vim.api.nvim_create_autocmd(
  { "BufAdd", "BufDelete", "BufWipeout", "BufUnload", "BufEnter", "BufModifiedSet", "WinEnter", "BufWinEnter" },
  { callback = update }
)
update()
