local M = {}
local fn = vim.fn

local function exists(cmd)
  return fn.executable(cmd) == 1
end

local has = {
  fzf = exists("fzf"),
  rg = exists("rg"),
  bat = exists("bat"),
}

-- Preview command
local function preview()
  return has.bat and "bat --style=numbers --color=always --line-range :500 {}" or "cat {}"
end

-- Floating terminal
local function float_term(cmd, tmp_file, on_select)
  local w, h = math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.9)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.fn.termopen(cmd, {
    on_exit = function(_, code)
      vim.api.nvim_win_close(win, true)
      if code == 0 and vim.fn.filereadable(tmp_file) == 1 then
        local lines = vim.fn.readfile(tmp_file)
        if lines and #lines > 0 and lines[1] ~= "" then
          vim.schedule(function() on_select(lines[1]) end)
        end
      end
      vim.fn.delete(tmp_file)
    end,
  })

  vim.cmd("startinsert")
end

-- FZF file picker
function M.files()
  if not has.fzf then
    return vim.notify("fzf not installed", vim.log.levels.ERROR)
  end

  local tmp = fn.tempname()
  local cmd
  if has.rg then
    -- Exclude .git folder
    cmd = "rg --files --hidden --follow --glob '!.git/*' --no-messages"
  else
    cmd = "find . -type f -not -path '*/.git/*'"
  end
  local fzf_cmd = string.format('%s | fzf --prompt="Files> " --preview="%s" > %s', cmd, preview(), tmp)

  float_term(fzf_cmd, tmp, function(f)
    vim.cmd("edit " .. fn.fnameescape(f))
  end)
end

-- FZF grep
function M.grep()
  if not (has.fzf and has.rg) then
    return vim.notify("fzf + rg required", vim.log.levels.ERROR)
  end

  local tmp = fn.tempname()
  local prev = has.bat and "bat --style=numbers --color=always --highlight-line {2} {1}" or "cat {1}"
  local fzf_cmd = string.format(
    'fzf --ansi --disabled --prompt="Grep> " --delimiter=: ' ..
    '--preview="%s" ' ..
    '--preview-window="right:60%%:wrap:+{2}-/2" ' ..
    '--bind="change:reload:sleep 0.1; rg --column --line-number --no-heading --color=always --smart-case {q} || true" ' ..
    '> %s',
    prev:gsub('"', '\\"'), tmp
  )

  float_term(fzf_cmd, tmp, function(line)
    local parts = vim.split(line, ":", { plain = true })
    if #parts >= 3 then
      local file, lnum, col = parts[1], tonumber(parts[2]), tonumber(parts[3])
      if file and lnum and col then
        vim.cmd("edit " .. fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
        vim.cmd("normal! zz")
      end
    end
  end)
end

-- FZF buffer picker
function M.buffers()
  if not has.fzf then
    return vim.notify("fzf not installed", vim.log.levels.ERROR)
  end

  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then table.insert(bufs, name) end
    end
  end

  if #bufs == 0 then return vim.notify("No buffers", vim.log.levels.WARN) end

  local tmp = fn.tempname()
  local fzf_cmd = string.format(
    'printf "%%s\\n" %s | fzf --prompt="Buffers> " --preview="%s" > %s',
    fn.shellescape(table.concat(bufs, "\n")), preview(), tmp
  )

  float_term(fzf_cmd, tmp, function(f)
    vim.cmd("buffer " .. fn.fnameescape(f))
  end)
end

-- Setup keymaps
function M.setup(keys)
  keys = keys or {
    ["<leader><leader>"] = M.files,
    ["<leader>fw"] = M.grep,
    ["<leader>fb"] = M.buffers,
  }
  for k, fn in pairs(keys) do
    vim.keymap.set("n", k, fn, { desc = "FZF: " .. k })
  end
end

return M
