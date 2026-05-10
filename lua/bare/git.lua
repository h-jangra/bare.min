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

local function clear(buf)
  vim.fn.sign_unplace("bare_git", { buffer = buf })
end

local function git_root(path)
  local dir = vim.fs.dirname(path)

  if root_cache[dir] then
    return root_cache[dir]
  end

  local result = vim.system({
    "git",
    "-C",
    dir,
    "rev-parse",
    "--show-toplevel",
  }, { text = true }):wait()

  if result.code ~= 0 then
    return nil
  end

  local root = vim.trim(result.stdout)
  root_cache[dir] = root

  return root
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

      local id = 1

      for line in diff:gmatch("[^\r\n]+") do
        local old_start, old_count, new_start, new_count =
            line:match("@@ %-(%d+),?(%d*) %+([0-9]+),?(%d*) @@")

        if old_start then
          old_count = tonumber(old_count) or 1
          new_count = tonumber(new_count) or 1
          new_start = tonumber(new_start)

          local sign
          local start_line
          local count

          if new_count == 0 then
            sign = "BareGitDelete"
            start_line = math.max(new_start, 1)
            count = 1
          elseif old_count == 0 then
            sign = "BareGitAdd"
            start_line = new_start
            count = new_count
          else
            sign = "BareGitChange"
            start_line = new_start
            count = math.max(old_count, new_count)
          end

          for i = 0, count - 1 do
            vim.fn.sign_place(id, "bare_git", sign, buf, {
              lnum = start_line + i,
              priority = 10,
            })

            id = id + 1
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

  local timer = vim.uv.new_timer()

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWritePost",
    "TextChanged",
  }, {
    group = group,
    callback = function(args)
      timer:stop()

      timer:start(120, 0, function()
        vim.schedule(function()
          M.update(args.buf)
        end)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = set_hl,
  })
end

return M
