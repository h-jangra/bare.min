local modes = {
  n = { letter = "N", color = "#89b4fa" },
  i = { letter = "I", color = "#a6e3a1" },
  v = { letter = "V", color = "#cba6f7" },
  V = { letter = "V-L", color = "#cba6f7" },
  ["\22"] = { letter = "V-B", color = "#cba6f7" },
  R = { letter = "R", color = "#f38ba8" },
  c = { letter = "C", color = "#f9e2af" },
  t = { letter = "T", color = "#fab387" },
}

vim.api.nvim_set_hl(0, "StlText", { fg = "#cdd6f4", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlGit", { fg = "#f9e2af", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlLsp", { fg = "#a6e3a1", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlLspLoading", { fg = "#fab387", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlFile", { fg = "#94e2d5", bg = "#292c3c" })
vim.api.nvim_set_hl(0, "StlFileModified", { fg = "#f2cdcd", bg = "#292c3c", bold = true })

local cache = { branch = nil, lsp_clients = {}, filepath = "", filesize = "" }
local lsp_spinners = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_idx = 0

local function update_git_branch()
  local branch = vim.b.gitsigns_head or vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\\n'")
  cache.branch = (branch and branch ~= "") and branch or nil
end

local function update_lsp_clients()
  cache.lsp_clients = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.attached_buffers[vim.api.nvim_get_current_buf()] then
      table.insert(cache.lsp_clients, client.name)
    end
  end
  vim.cmd("redrawstatus")
end


local function update_file_info()
  local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
  cache.filepath = path == "" and "[No Name]" or path
  local size = vim.fn.getfsize(vim.fn.expand("%:p"))
  if size > 0 then
    local suffixes = { "B", "K", "M", "G" }
    local i = 1
    while size > 1024 and i < #suffixes do
      size = size / 1024
      i = i + 1
    end
    cache.filesize = string.format("%.1f%s", size, suffixes[i])
  else
    cache.filesize = nil
  end
end

local function get_lsp_status()
  if #cache.lsp_clients == 0 then return "" end
  if vim.lsp.status() ~= "" then
    spinner_idx = (spinner_idx % #lsp_spinners) + 1
    return "%#StlLspLoading#" .. lsp_spinners[spinner_idx] .. " "
  end
  return "%#StlLsp# " .. table.concat(cache.lsp_clients, ", ") .. " "
end

_G.status_line = function()
  local mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[mode] or { letter = "?", color = "#6c7086" }
  vim.api.nvim_set_hl(0, "StlMode", { fg = "#292c3c", bg = mode_info.color, bold = true })
  local file_hl = vim.bo.modified and "%#StlFileModified# " or "%#StlText# "

  return table.concat({
    "%#StlMode# ", mode_info.letter, " ",
    file_hl, cache.filepath, " ",
    cache.branch and ("%#StlGit#  " .. cache.branch .. " ") or "",
    "%=",
    get_lsp_status(),
    "%#StlText#", vim.fn.line("$"), " ",
    cache.filesize and ("%#StlFile#" .. cache.filesize .. " ") or "",
  })
end

vim.o.statusline = "%!v:lua.status_line()"

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, { callback = update_file_info })
vim.api.nvim_create_autocmd("BufEnter", { callback = update_git_branch })
vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach", }, { callback = update_lsp_clients })
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function()
    spinner_idx = (spinner_idx % #lsp_spinners) + 1; vim.cmd("redrawstatus")
  end,
})
vim.api.nvim_create_autocmd("ModeChanged", { callback = function() vim.cmd("redrawstatus") end })
