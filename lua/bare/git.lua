local M = {}

local signs = {
  add = "▎",
  change = "▎",
  delete = "",
}

local root_cache = {}
local pending = {}
local last_diff = {}

vim.fn.sign_define("BareGitAdd", {
  text = signs.add,
  texthl = "BareGitAdd",
})

vim.fn.sign_define("BareGitChange", {
  text = signs.change,
  texthl = "BareGitChange",
})

vim.fn.sign_define("BareGitDelete", {
  text = signs.delete,
  texthl = "BareGitDelete",
})

local function set_hl()
  vim.api.nvim_set_hl(0, "BareGitAdd", {
    fg = "#98bb6c",
  })

  vim.api.nvim_set_hl(0, "BareGitChange", {
    fg = "#7fb4ca",
  })

  vim.api.nvim_set_hl(0, "BareGitDelete", {
    fg = "#e46876",
  })
end

local ns = vim.api.nvim_create_namespace("bare_git")

local function clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

local function git_root(path)
  return vim.fs.root(path, ".git")
end

local function parse_hunks(buf, base)
  if pending[buf] then
    return
  end

  pending[buf] = true

  local file = vim.api.nvim_buf_get_name(buf)

  if file == "" then
    pending[buf] = nil
    return
  end

  local rel = vim.fs.relpath(base, file)

  if not rel then
    pending[buf] = nil
    return
  end

  vim.system({
    "git",
    "-C",
    base,
    "diff",
    "--no-ext-diff",
    "--unified=0",
    "--",
    rel,
  }, {
    text = true,
  }, function(result)
    vim.schedule(function()
      pending[buf] = nil

      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      local diff = result.stdout or ""

      if last_diff[buf] == diff then
        return
      end

      last_diff[buf] = diff

      clear(buf)
      local total_lines = vim.api.nvim_buf_line_count(buf)

      for line in diff:gmatch("[^\r\n]+") do
        local old_start, old_count, new_start, new_count =
            line:match("@@ %-(%d+),?(%d*) %+([0-9]+),?(%d*) @@")

        if old_start then
          old_count = tonumber(old_count) or 1
          new_count = tonumber(new_count) or 1
          new_start = tonumber(new_start)

          local sign_text
          local hl
          local start_line
          local count

          if new_count == 0 then
            sign_text = signs.delete
            hl = "BareGitDelete"
            start_line = math.max(new_start, 1)
            count = 1
          elseif old_count == 0 then
            sign_text = signs.add
            hl = "BareGitAdd"
            start_line = new_start
            count = new_count
          else
            sign_text = signs.change
            hl = "BareGitChange"
            start_line = new_start
            count = math.max(old_count, new_count)
          end

          for i = 0, count - 1 do
            local lnum = start_line + i - 1
            if lnum >= 0 and lnum < total_lines then
              vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
                sign_text = sign_text,
                sign_hl_group = hl,
                priority = 10,
              })
            end
          end
        end
      end
    end)
  end)
end

function M.update(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  if vim.bo[buf].buftype ~= "" then
    return
  end

  if vim.api.nvim_buf_line_count(buf) > 10000 then
    return
  end

  local file = vim.api.nvim_buf_get_name(buf)

  if file == "" then
    return
  end

  local root = git_root(file)

  if not root then
    clear(buf)
    return
  end

  parse_hunks(buf, root)
end

function M.setup()
  set_hl()

  local group = vim.api.nvim_create_augroup("BareGit", { clear = true })

  local timers = {}

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWritePost",
    "TextChanged",
  }, {
    group = group,
    callback = function(args)
      local buf = args.buf
      if not timers[buf] then
        timers[buf] = vim.uv.new_timer()
      end
      timers[buf]:stop()

      timers[buf]:start(120, 0, function()
        vim.schedule(function()
          M.update(buf)
        end)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      local buf = args.buf
      if timers[buf] then
        timers[buf]:stop()
        timers[buf]:close()
        timers[buf] = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = set_hl,
  })
end

return M
