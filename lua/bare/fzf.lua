local M = {}
local function has_cmd(cmd)
  return vim.fn.executable(cmd) == 1
end
local tools = {
  fzf = has_cmd("fzf"),
  rg = has_cmd("rg"),
  bat = has_cmd("bat"),
}
local function preview_cmd()
  return tools.bat
      and "bat --style=numbers --color=always --line-range :500 {}"
      or "cat {}"
end
local function open_float()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "solid",
    row = row,
    col = col,
    width = width,
    height = height,
  })

  vim.cmd("startinsert")
  return buf, win
end

local function close_float(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end
local function fzf_float(cmd, callback)
  local tmp = vim.fn.tempname()
  local full_cmd = string.format("%s > %s", cmd, tmp)
  local buf, win = open_float()

  vim.fn.termopen(full_cmd, {
    on_exit = function(_, code)
      close_float(win)
      if code == 0 and vim.fn.filereadable(tmp) == 1 then
        local result = vim.fn.readfile(tmp)[1]
        if result and result ~= "" then
          vim.schedule(function() callback(result) end)
        end
      end
      vim.fn.delete(tmp)
    end,
  })
end

function M.files()
  if not tools.fzf then
    return vim.notify("fzf not installed", vim.log.levels.ERROR)
  end

  local find_cmd = tools.rg
      and "rg --files --hidden --follow --glob '!.git/*'"
      or "find . -type f -not -path '*/.git/*'"

  local cmd = string.format('%s | fzf --prompt="Files> " --preview="%s"', find_cmd, preview_cmd())

  fzf_float(cmd, function(file)
    vim.cmd("edit " .. vim.fn.fnameescape(file))
  end)
end

function M.grep()
  if not (tools.fzf and tools.rg) then
    return vim.notify("fzf and rg required", vim.log.levels.ERROR)
  end

  local preview = tools.bat
      and "bat --style=numbers --color=always --highlight-line {2} {1}"
      or "cat {1}"

  local cmd = string.format(
    'fzf --ansi --disabled --prompt="Grep> " --delimiter=: ' ..
    '--preview="%s" --preview-window="right:60%%:wrap:+{2}-/2" ' ..
    '--bind="change:reload:sleep 0.1; rg --column --line-number --no-heading --color=always --smart-case {q} || true"',
    preview:gsub('"', '\\"')
  )

  fzf_float(cmd, function(line)
    local file, lnum, col = line:match("([^:]+):(%d+):(%d+)")
    if file and lnum and col then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
      vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
      vim.cmd("normal! zz")
    end
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader><leader>", M.files, { desc = "FZF Files" })
  vim.keymap.set("n", "<leader>fw", M.grep, { desc = "Grep" })
end

return M
