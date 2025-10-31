-- Requires fzf and ripgrep
local M = {}

local function has(cmd)
  return vim.fn.executable(cmd) == 1
end

local function float_cmd(cmd, on_select)
  local tmp = vim.fn.tempname()
  local buf = vim.api.nvim_create_buf(false, true)
  local width, height = math.floor(vim.o.columns * 0.8), math.floor(vim.o.lines * 0.6)



  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 3),
    col = math.floor((vim.o.columns - width) / 2),
  })

  local normal_hl = vim.api.nvim_get_hl(0, { name = 'Normal' })
  local float_hl = vim.api.nvim_get_hl(0, { name = 'Comment' })

  local ns = vim.api.nvim_create_namespace("fzf_float_" .. tostring(win))
  vim.api.nvim_win_set_hl_ns(win, ns)

  vim.api.nvim_set_hl(ns, 'NormalFloat', { bg = normal_hl.bg })
  vim.api.nvim_set_hl(ns, 'FloatBorder', { bg = normal_hl.bg, fg = float_hl.fg })

  vim.bo[buf].bufhidden = "wipe"

  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
        if vim.fn.filereadable(tmp) == 1 then
          local result = vim.fn.readfile(tmp)[1]
          if result then on_select(result) end
          vim.fn.delete(tmp)
        end
      end)
    end,
  })

  vim.fn.jobstart(cmd .. " > " .. tmp, { term = true })
  vim.cmd("startinsert")
end

function M.files()
  if not has("fzf") then return end

  local find_cmd = has("rg")
      and "rg --files --hidden --follow --glob '!.git/*' --glob '!**/*.png'"
      or "find . -type f -not -path '*/.git/*'"

  local preview = has("bat")
      and "bat --style=numbers --color=always --line-range :500 {}"
      or "cat {}"

  local cmd = string.format('%s | fzf --prompt="Files> " --preview="%s"', find_cmd, preview)
  float_cmd(cmd, function(file)
    vim.cmd("edit " .. vim.fn.fnameescape(file))
  end)
end

function M.grep()
  if not (has("fzf") and has("rg")) then return end

  local preview = has("bat")
      and "bat --style=numbers --color=always --highlight-line {2} {1}"
      or "cat {1}"

  local cmd = string.format(
    'fzf --ansi --disabled --prompt="Grep> " --delimiter=: ' ..
    '--preview="%s" --preview-window="right:60%%:wrap:+{2}-/2" ' ..
    '--bind="change:reload:sleep 0.1; rg --column --line-number --no-heading --color=always --smart-case {q} || true"',
    preview
  )

  float_cmd(cmd, function(line)
    local file, lnum, col = line:match("([^:]+):(%d+):(%d+)")

    if file and lnum and col then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
      vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
      vim.cmd("normal! zz")
    end
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader><leader>", M.files)
  vim.keymap.set("n", "<leader>fg", M.grep)
end

return M
