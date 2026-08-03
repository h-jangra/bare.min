local M = {}

local api = vim.api

local DEBOUNCE_MS = 120
local MAX_LINES = 10000
local SIGN_PRIORITY = 10

local SIGNS = {
  Add = { text = "▎", fg = "#98bb6c", hl = "BareGitAdd" },
  Change = { text = "▎", fg = "#7fb4ca", hl = "BareGitChange" },
  Delete = { text = "", fg = "#e46876", hl = "BareGitDelete" },
}

local ns = api.nvim_create_namespace("bare_git")
local pending = {}
local last_diff = {}

for _, cfg in pairs(SIGNS) do
  vim.fn.sign_define(cfg.hl, { text = cfg.text, texthl = cfg.hl })
end

local function set_hl()
  for _, cfg in pairs(SIGNS) do
    api.nvim_set_hl(0, cfg.hl, { fg = cfg.fg })
  end
end

local function clear(buf)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

local function parse_hunks(buf, base, file)
  if pending[buf] then
    return
  end

  local rel = vim.fs.relpath(base, file)
  if not rel then
    return
  end

  pending[buf] = true

  vim.system(
    { "git", "-C", base, "diff", "--no-ext-diff", "--unified=0", "--", rel },
    { text = true },
    function(result)
      vim.schedule(function()
        pending[buf] = nil

        if not api.nvim_buf_is_valid(buf) then
          return
        end

        local diff = result.stdout or ""
        if last_diff[buf] == diff then
          return
        end

        last_diff[buf] = diff
        clear(buf)

        local total_lines = api.nvim_buf_line_count(buf)

        for line in diff:gmatch("[^\r\n]+") do
          local old_start, old_count, new_start, new_count =
            line:match("@@ %-(%d+),?(%d*) %+([0-9]+),?(%d*) @@")

          if old_start then
            old_count = tonumber(old_count) or 1
            new_count = tonumber(new_count) or 1
            new_start = tonumber(new_start)

            local sign, count, start_line
            if new_count == 0 then
              sign, count, start_line = SIGNS.Delete, 1, math.max(new_start, 1)
            elseif old_count == 0 then
              sign, count, start_line = SIGNS.Add, new_count, new_start
            else
              sign, count, start_line = SIGNS.Change, math.max(old_count, new_count), new_start
            end

            for i = 0, count - 1 do
              local lnum = start_line + i - 1
              if lnum >= 0 and lnum < total_lines then
                api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
                  sign_text = sign.text,
                  sign_hl_group = sign.hl,
                  priority = SIGN_PRIORITY,
                })
              end
            end
          end
        end
      end)
    end
  )
end

function M.update(buf)
  buf = buf or api.nvim_get_current_buf()

  if vim.bo[buf].buftype ~= "" or api.nvim_buf_line_count(buf) > MAX_LINES then
    return
  end

  local file = api.nvim_buf_get_name(buf)
  if file == "" then
    return
  end

  local root = vim.fs.root(file, ".git")
  if not root then
    clear(buf)
    return
  end

  parse_hunks(buf, root, file)
end

function M.setup()
  set_hl()

  local group = api.nvim_create_augroup("BareGit", { clear = true })
  local timers = {}

  api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged" }, {
    group = group,
    callback = function(args)
      local buf = args.buf
      local timer = timers[buf] or vim.uv.new_timer()
      timers[buf] = timer
      timer:stop()
      timer:start(DEBOUNCE_MS, 0, function()
        vim.schedule(function()
          M.update(buf)
        end)
      end)
    end,
  })

  api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      local buf = args.buf
      if timers[buf] then
        timers[buf]:stop()
        timers[buf]:close()
        timers[buf] = nil
      end
      pending[buf] = nil
      last_diff[buf] = nil
    end,
  })

  api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = set_hl,
  })
end

return M
