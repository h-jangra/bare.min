local modes = {
  n = { letter = "N", color = "#89b4fa" },
  i = { letter = "I", color = "#a6e3a1" },
  v = { letter = "V", color = "#cba6f7" },
  V = { letter = "V", color = "#cba6f7" },
  [""] = { letter = "V", color = "#cba6f7" },
  R = { letter = "R", color = "#f38ba8" },
  c = { letter = "C", color = "#f9e2af" },
  t = { letter = "T", color = "#fab387" },
}

local function set_hl(name, fg, bg)
  vim.cmd(string.format("highlight %s guifg=%s guibg=%s", name, fg, bg))
end

local function get_git_branch()
  if vim.b.gitsigns_head then
    return vim.b.gitsigns_head
  end
  local branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\\n'")
  return (branch ~= "") and branch or nil
end

local function get_lsp_name()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if not vim.tbl_isempty(clients) then
    return clients[1].name
  end
  return nil
end

local function get_file_size()
  local file = vim.fn.expand('%:p')
  if file == "" then return "0" end
  local size = vim.fn.getfsize(file)
  if size <= 0 then return "0" end

  local suffixes = { "B", "K", "M", "G" }
  local i = 1

  while size > 1024 and i < #suffixes do
    size = size / 1024
    i = i + 1
  end
  return string.format("%.1f%s", size, suffixes[i])
end

_G.status_line = function()
  local mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[mode] or { letter = "?", color = "#6c7086" }

  set_hl("StlMode", mode_info.color, "#292c3c")
  set_hl("StlText", "#cdd6f4", "#292c3c")
  set_hl("StlGit", "#f9e2af", "#292c3c")
  set_hl("StlLsp", "#cba6f7", "#292c3c")

  local filepath = vim.fn.fnamemodify(vim.fn.expand('%'), ':~:.')
  if filepath == "" then filepath = "[No Name]" end
  if vim.bo.modified then filepath = filepath .. " ●" end

  local git_branch = get_git_branch()
  local lsp_name = get_lsp_name()
  local file_size = get_file_size()

  return table.concat({
    "%#StlMode#", " ", mode_info.letter, "  ",
    "%#StlText#", filepath, " ",
    git_branch and ("%#StlGit# " .. git_branch .. " ") or "",
    "%=",
    lsp_name and ("%#StlLsp#" .. lsp_name .. " ") or "",
    "%#StlText#", " ", vim.fn.line('$'), " ",
    "%#StlMode#", file_size, " "
  })
end

vim.o.statusline = "%!v:lua.status_line()"
vim.api.nvim_create_autocmd({ "ModeChanged", "BufEnter", "BufModifiedSet" }, {
  callback = function() vim.cmd("redrawstatus") end
})
