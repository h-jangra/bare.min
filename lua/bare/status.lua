local M = {}

local api = vim.api
local fn = vim.fn

local bg = "#292c3c"
local fg = "#c6d0f5"

api.nvim_set_hl(0, "StlBubble", { fg = fg, bg = bg })
api.nvim_set_hl(0, "StlBubbleCap", { fg = bg, bg = "NONE" })
api.nvim_set_hl(0, "StlAccent", { fg = "#81c8be", bg = bg })
api.nvim_set_hl(0, "StlDiagErr", { fg = "#e78284", bg = bg, bold = true })
api.nvim_set_hl(0, "StlDiagWarn", { fg = "#e5c890", bg = bg })

local modes = {
  n       = { letter = "N", color = "#8caaee" },
  i       = { letter = "I", color = "#99d1db" },
  v       = { letter = "V", color = "#ca9ee6" },
  V       = { letter = "V", color = "#ca9ee6" },
  ["\22"] = { letter = "V", color = "#ca9ee6" },
  R       = { letter = "R", color = "#eebebe" },
  c       = { letter = "C", color = "#e5c890" },
  t       = { letter = "T", color = "#ea999c" },
}

local seen = {}

for _, m in pairs(modes) do
  if not seen[m.letter] then
    seen[m.letter] = true
    api.nvim_set_hl(0, "StlMode" .. m.letter, { fg = bg, bg = m.color, bold = true })
    api.nvim_set_hl(0, "StlCap" .. m.letter, { fg = m.color, bg = "NONE" })
  end
end

local cache = {}

local function get_git_branch(bufnr)
  local file = api.nvim_buf_get_name(bufnr)
  local dir = file ~= "" and vim.fs.dirname(file) or fn.getcwd()
  local root = vim.fs.root(dir, ".git")
  if not root then return "" end

  local git_dir = vim.fs.joinpath(root, ".git")
  local stat = vim.uv.fs_stat(git_dir)
  if not stat then return "" end

  if stat.type == "file" then
    local f = io.open(git_dir, "r")
    if f then
      local line = f:read("*l")
      f:close()
      local real_dir = line and line:match("^gitdir:%s*(.+)")
      if real_dir then git_dir = real_dir end
    end
  end

  local head_file = vim.fs.joinpath(git_dir, "HEAD")
  local f = io.open(head_file, "r")
  if not f then return "" end
  local line = f:read("*l")
  f:close()
  if not line then return "" end

  local branch = line:match("ref: refs/heads/(.+)") or line:sub(1, 7)
  return " " .. vim.trim(branch)
end

local function get_lsp_name(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then return "" end
  local names = {}
  for i, client in ipairs(clients) do
    names[i] = client.name
  end
  return table.concat(names, ",")
end

local function update_cache(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or api.nvim_get_current_buf()
  cache[bufnr] = {
    git = get_git_branch(bufnr),
    lsp = get_lsp_name(bufnr),
  }
end

local function get_diag_status()
  local count = vim.diagnostic.count(0)
  local err = count[vim.diagnostic.severity.ERROR] or 0
  local warn = count[vim.diagnostic.severity.WARN] or 0
  local str = ""
  if err > 0 then str = str .. " %#StlDiagErr#󰅚 " .. err end
  if warn > 0 then str = str .. " %#StlDiagWarn#󰀦 " .. warn end
  return str
end

function M.statusline()
  local mode_info = modes[api.nvim_get_mode().mode] or modes.n
  local bufnr = api.nvim_get_current_buf()

  if not cache[bufnr] then
    update_cache(bufnr)
  end

  local file = fn.expand("%:~:.")
  if file == "" then
    file = "Untitled"
  elseif vim.bo.buftype == "terminal" then
    file = "Terminal"
  end

  local file_hl = vim.bo.modified and " %#StlAccent#" or " %#StlBubble#"
  local buf_cache = cache[bufnr]

  local hl = "StlMode" .. mode_info.letter
  local cap = "StlCap" .. mode_info.letter

  local left = "%#" .. cap .. "#%#" .. hl .. "#" .. mode_info.letter .. " %#StlBubble#" .. file_hl .. file
  if buf_cache.git ~= "" then
    left = left .. " %#StlAccent#" .. buf_cache.git .. "%#StlBubble#"
  end
  left = left .. get_diag_status() .. "%#StlBubbleCap#"

  local right = ""
  if buf_cache.lsp ~= "" then
    right = "%#StlBubbleCap#%#StlBubble#%#StlAccent#" .. buf_cache.lsp .. " "
  end
  right = right ..
      (buf_cache.lsp ~= "" and "%#" .. hl .. "#" or "%#" .. cap .. "#%#" .. hl .. "#") .. " %L%#" .. cap .. "#"

  return left .. "%=" .. right
end

local augroup = api.nvim_create_augroup("StlCache", { clear = true })

api.nvim_create_autocmd({ "BufEnter", "DirChanged" },
  { group = augroup, callback = function(args) update_cache(args.buf) end })

api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = augroup,
  callback = function(args)
    if cache[args.buf] then
      cache[args.buf].lsp = get_lsp_name(args.buf)
    else
      update_cache(args.buf)
    end
    vim.cmd.redrawstatus()
  end,
})

api.nvim_create_autocmd("BufWipeout", { group = augroup, callback = function(args) cache[args.buf] = nil end })

vim.o.statusline = "%!v:lua.require('bare.status').statusline()"

return M
