local modes = {
  n = { letter = "N", color = "#89b4fa" },
  i = { letter = "I", color = "#a6e3a1" },
  v = { letter = "V", color = "#cba6f7" },
  V = { letter = "V-L", color = "#cba6f7" },
  [""] = { letter = "V-B", color = "#cba6f7" },
  R = { letter = "R", color = "#f38ba8" },
  c = { letter = "C", color = "#f9e2af" },
  t = { letter = "T", color = "#fab387" },
}

vim.api.nvim_set_hl(0, "StlText", { fg = "#cdd6f4", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlGit", { fg = "#f9e2af", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlLsp", { fg = "#cba6f7", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlFile", { fg = "#94e2d5", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlLoading", { fg = "#fab387", bg = "#292c3c" })

local cache = {
  branch = "",
  lsp = "",
  filepath = "",
  filesize = "",
}

local function update_git_branch()
  if vim.b.gitsigns_head then
    cache.branch = vim.b.gitsigns_head
  else
    local ok, branch = pcall(vim.fn.system, "git branch --show-current 2>/dev/null | tr -d '\\n'")
    cache.branch = (ok and branch ~= "") and branch or ""
  end
end

local function update_lsp_name()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  cache.lsp = (clients[1] and clients[1].name) or ""
  vim.cmd("redrawstatus")
end

local function update_file_info()
  local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
  cache.filepath = (path == "" and "[No Name]") or path
  local file = vim.fn.expand("%:p")
  local size = (file == "" or vim.fn.getfsize(file) <= 0) and 0 or vim.fn.getfsize(file)
  local suffixes = { "B", "K", "M", "G" }
  local i = 1
  while size > 1024 and i < #suffixes do
    size = size / 1024
    i = i + 1
  end
  cache.filesize = string.format("%.1f%s", size, suffixes[i])
end

local function get_lsp_status()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end

  local loading = vim.lsp.status() ~= ""
  if loading then
    return "%#StlLoading# 󰪞 "
  end

  return cache.lsp ~= "" and ("%#StlLsp#" .. cache.lsp .. " ") or ""
end

_G.status_line = function()
  local mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[mode] or { letter = "?", color = "#6c7086" }
  vim.api.nvim_set_hl(0, "StlMode", { fg = "#292c3c", bg = mode_info.color, bold = true })

  local filepath = cache.filepath
  if vim.bo.modified then
    filepath = filepath .. " ●"
  end

  local lsp_status = get_lsp_status()

  return table.concat({
    "%#StlMode# ", mode_info.letter, " ",
    "%#StlText# ", filepath, " ",
    cache.branch ~= "" and ("%#StlGit# " .. cache.branch .. " ") or "",
    "%=",
    lsp_status,
    "%#StlText# " .. vim.fn.line("$"), " ",
    cache.filesize ~= "" and ("%#StlFile#" .. cache.filesize .. " ") or "",
  })
end

vim.o.statusline = "%!v:lua.status_line()"

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, { callback = update_file_info })
vim.api.nvim_create_autocmd({ "BufEnter" }, { callback = update_git_branch })
vim.api.nvim_create_autocmd({ "LspAttach" }, { callback = update_lsp_name })
vim.api.nvim_create_autocmd({ "LspProgress" }, { callback = function() vim.cmd("redrawstatus") end })
vim.api.nvim_create_autocmd({ "ModeChanged" }, { callback = function() vim.cmd("redrawstatus") end })
