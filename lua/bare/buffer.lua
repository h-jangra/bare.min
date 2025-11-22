vim.api.nvim_set_hl(0, "WinBarActive", { fg = "#7fb4ca", bg = "#2a2a37", bold = true })
vim.api.nvim_set_hl(0, "WinBarInactive", { fg = "#54546d", bg = "#2a2a37", italic = true })
vim.api.nvim_set_hl(0, "WinBarModified", { fg = "#2a2a37", bg = "#7fb4ca" })

local function bufname(buf)
  local n = vim.api.nvim_buf_get_name(buf)
  n = vim.fn.fnamemodify(n, ":t")
  return (n ~= "" and n or "[No Name]")
end

function _G.goto_buf(buf) vim.api.nvim_set_current_buf(buf) end

local function real_bufs()
  local n = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted
        and vim.api.nvim_buf_is_loaded(b)
        and vim.bo[b].buftype == ""
        and vim.api.nvim_buf_get_name(b) ~= "" then
      n = n + 1
      if n > 1 then return n end
    end
  end
  return n
end

function _G.winbar_buffers()
  local cur = vim.api.nvim_get_current_buf()
  local parts = {}
  local icons = require("bare.icons")

  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted
        and vim.api.nvim_buf_is_loaded(b)
        and vim.bo[b].buftype == ""
        and vim.api.nvim_buf_get_name(b) ~= "" then
      local group =
          (b == cur)
          and (vim.bo[b].modified and "WinBarModified" or "WinBarActive")
          or (vim.bo[b].modified and "WinBarModified" or "WinBarInactive")

      table.insert(parts,
        string.format("%%%d@v:lua.goto_buf@%%#%s# %s %s %%X%%#Normal#",
          b, group,
          icons.get(vim.bo[b].filetype) or "󰈤",
          bufname(b)
        )
      )
    end
  end

  return table.concat(parts)
end

local function update()
  local cfg = vim.api.nvim_win_get_config(0)
  if cfg.relative ~= "" then
    vim.wo.winbar = nil; return
  end

  vim.wo.winbar = (real_bufs() > 1)
      and "%{%v:lua.winbar_buffers()%}"
      or nil
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "BufLeave" }, { callback = update })
update()
