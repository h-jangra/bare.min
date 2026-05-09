local M = {}

local ns = vim.api.nvim_create_namespace("bare_git")

local signs = {
  add = "▎",
  change = "▎",
  delete = "",
}

vim.fn.sign_define("BareGitAdd", {
  text = signs.add,
  texthl = "BareGitAdd",
  numhl = "",
})

vim.fn.sign_define("BareGitChange", {
  text = signs.change,
  texthl = "BareGitChange",
  numhl = "",
})

vim.fn.sign_define("BareGitDelete", {
  text = signs.delete,
  texthl = "BareGitDelete",
  numhl = "",
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
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

local function parse_hunks(buf, base)
  clear(buf)

  local file = vim.api.nvim_buf_get_name(buf)

  if file == "" then
    return
  end

  local result = vim.system({
    "git",
    "-C",
    base,
    "diff",
    "--no-ext-diff",
    "--unified=0",
    "--",
    file,
  }, { text = true }):wait()

  local diff = result.stdout or ""

  local id = 1

  for line in diff:gmatch("[^\r\n]+") do
    local old_start, old_count, new_start, new_count =
        line:match("@@ %-(%d+),?(%d*) %+([0-9]+),?(%d*) @@")

    if old_start then
      old_count = tonumber(old_count) or 1
      new_count = tonumber(new_count) or 1
      new_start = tonumber(new_start)

      if not new_start then
        goto continue
      end

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

      for i = 0, math.max(count - 1, 0) do
        vim.fn.sign_place(id, "bare_git", sign, buf, {
          lnum = start_line + i,
          priority = 10,
        })

        id = id + 1
      end
    end

    ::continue::
  end
end

local function git_root(path)
  local dir = vim.fn.fnamemodify(path, ":h")

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

  return vim.trim(result.stdout)
end

function M.update(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  if vim.bo[buf].buftype ~= "" then
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

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWritePost",
    "TextChanged",
    "TextChangedI",
  }, {
    callback = function(args)
      vim.schedule(function()
        M.update(args.buf)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = set_hl,
  })
end

return M
