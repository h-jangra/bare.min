local function setup_highlights()
  vim.cmd("hi WinBar guibg=NONE | hi WinBarNC guibg=NONE")
  vim.cmd("hi! link WinBarActive TabLineSel | hi! link WinBarModifiedActive TabLineSel")
  vim.cmd("hi! link WinBarInactive TabLine | hi! link WinBarModifiedInactive TabLine")
end
setup_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })

local function bufname(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":t")
end

function _G.goto_buf(buf) vim.api.nvim_set_current_buf(buf) end

local function valid_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].buflisted then return false end
  if vim.bo[buf].buftype ~= "" or vim.bo[buf].filetype == "filetree" then return false end

  local name = vim.api.nvim_buf_get_name(buf)
  if name:find("^term://") then return false end

  if name == "" then
    return buf == vim.api.nvim_get_current_buf() or vim.bo[buf].modified
  end
  return true
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

    parts[#parts + 1] = string.format(
      "%%%d@v:lua.goto_buf@%%#%s# %s %s%s %%X",
      b, group,
      info.icon,
      info.name,
      is_mod and " ●" or ""
    )
  end

  return table.concat(parts) .. "%#Normal#"
end

local function update()
  update_buf_cache()

  local cfg = vim.api.nvim_win_get_config(0)
  if cfg.relative ~= "" or vim.bo.buftype ~= "" then
    vim.wo.winbar = nil
    return
  end

  vim.wo.winbar = #buf_cache > 0 and "%{%v:lua.winbar_buffers()%}" or nil
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "BufModifiedSet" }, { callback = update })

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local cur = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_name(cur) == "" then return end

    vim.schedule(function()
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local bo = vim.bo[b]
        if b == cur or not vim.api.nvim_buf_is_valid(b) or not bo.buflisted
            or bo.modified or bo.buftype ~= ""
            or vim.api.nvim_buf_get_name(b) ~= ""
            or #vim.fn.win_findbuf(b) > 0 then
          goto continue
        end

        local lines = vim.api.nvim_buf_get_lines(b, 0, 1, false)
        if #lines == 0 or (#lines == 1 and lines[1] == "") then
          pcall(vim.api.nvim_buf_delete, b, { force = true })
        end

        ::continue::
      end
    end)
  end,
})

update()
