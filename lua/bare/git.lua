local M = {}

local api = vim.api
local DEBOUNCE_MS, MAX_LINES, SIGN_PRIORITY = 120, 10000, 10

local SIGNS = {
  Add    = { text = "▎", fg = "#98bb6c", hl = "BareGitAdd" },
  Change = { text = "▎", fg = "#7fb4ca", hl = "BareGitChange" },
  Delete = { text = "", fg = "#e46876", hl = "BareGitDelete" },
}

local ns = api.nvim_create_namespace("bare_git")
local bufs = {}

local function get_buf(buf)
  bufs[buf] = bufs[buf] or { ver = 0 }
  return bufs[buf]
end

local function set_hl()
  for _, s in pairs(SIGNS) do
    api.nvim_set_hl(0, s.hl, { fg = s.fg })
  end
end

local function clear(buf)
  if api.nvim_buf_is_valid(buf) then
    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

local function apply_hunks(buf, diff)
  local total = api.nvim_buf_line_count(buf)
  for line in diff:gmatch("[^\r\n]+") do
    local os, oc, ns_start, nc = line:match("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
    if os then
      oc, nc, ns_start = tonumber(oc) or 1, tonumber(nc) or 1, tonumber(ns_start)
      local sign, count, start = SIGNS.Change, math.max(oc, nc), ns_start
      if nc == 0 then
        sign, count, start = SIGNS.Delete, 1, math.max(ns_start, 1)
      elseif oc == 0 then
        sign, count = SIGNS.Add, nc
      end

      for i = 0, count - 1 do
        local lnum = start + i - 1
        if lnum >= 0 and lnum < total then
          api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
            sign_text = sign.text,
            sign_hl_group = sign.hl,
            priority = SIGN_PRIORITY,
          })
        end
      end
    end
  end
end

function M.update(buf)
  buf = buf or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(buf) then return end

  local b = get_buf(buf)
  b.ver = b.ver + 1

  local file = api.nvim_buf_get_name(buf)
  local root = file ~= "" and vim.fs.root(file, ".git")
  local rel = root and vim.fs.relpath(root, file)

  if vim.bo[buf].buftype ~= "" or api.nvim_buf_line_count(buf) > MAX_LINES or not rel then
    b.diff = nil
    clear(buf)
    return
  end

  local ver = b.ver
  vim.system({ "git", "-C", root, "diff", "--no-ext-diff", "--unified=0", "--", rel }, { text = true }, function(res)
    vim.schedule(function()
      if not bufs[buf] or not api.nvim_buf_is_valid(buf) or ver ~= b.ver then return end
      local diff = res.stdout or ""
      if b.diff == diff then return end
      b.diff = diff
      clear(buf)
      apply_hunks(buf, diff)
    end)
  end)
end

function M.setup()
  set_hl()
  local group = api.nvim_create_augroup("BareGit", { clear = true })

  api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged" }, {
    group = group,
    callback = function(args)
      local b = get_buf(args.buf)
      b.timer = b.timer or vim.uv.new_timer()
      b.timer:stop()
      b.timer:start(DEBOUNCE_MS, 0, function()
        vim.schedule(function() M.update(args.buf) end)
      end)
    end,
  })

  api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      local b = bufs[args.buf]
      if b then
        if b.timer then b.timer:stop(); b.timer:close() end
        bufs[args.buf] = nil
      end
    end,
  })

  api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl })
end

return M
