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
  return tools.bat and "bat --style=numbers --color=always --line-range :500 {}" or "cat {}"
end

local function fzf_float(cmd, callback)
  local tmp = vim.fn.tempname()
  local full_cmd = string.format("%s > %s", cmd, tmp)
  local buf = vim.api.nvim_create_buf(false, true)
  local _, win = require("bare.float").open(buf)

  vim.fn.termopen(full_cmd, {
    on_exit = function(_, code)
      require("bare.float").close(win)
      if code == 0 and vim.fn.filereadable(tmp) == 1 then
        local result = vim.fn.readfile(tmp)[1]
        if result and result ~= "" then
          vim.schedule(function() callback(result) end)
        end
      end
      vim.fn.delete(tmp)
    end,
  })

  vim.cmd("startinsert")
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

function M.buffers()
  if not tools.fzf then
    return vim.notify("fzf not installed", vim.log.levels.ERROR)
  end

  local buffers = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) then
      local name = vim.api.nvim_buf_get_name(b)
      if name ~= "" then
        table.insert(buffers, name)
      end
    end
  end

  if #buffers == 0 then
    return vim.notify("No buffers", vim.log.levels.WARN)
  end

  local cmd = string.format(
    'printf "%%s\\n" %s | fzf --prompt="Buffers> " --preview="%s"',
    vim.fn.shellescape(table.concat(buffers, "\n")),
    preview_cmd()
  )

  fzf_float(cmd, function(file)
    vim.cmd("buffer " .. vim.fn.fnameescape(file))
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader><leader>", M.files, { desc = "FZF Files" })
  vim.keymap.set("n", "<leader>fw", M.grep, { desc = "FZF Grep" })
  vim.keymap.set("n", "<leader>fb", M.buffers, { desc = "FZF Buffers" })
end

return M
