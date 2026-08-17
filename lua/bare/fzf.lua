local M = {}
local ui = require("bare.ui")

local function run(command, on_select)
  if vim.fn.executable("fzf") == 0 then
    return
  end

  local outfile = vim.fn.tempname()
  local bufnr, winid = ui.float()

  vim.bo[bufnr].bufhidden = "wipe"

  vim.api.nvim_create_autocmd("TermClose", {
    buffer = bufnr,
    once = true,
    callback = function()
      vim.schedule(function()
        pcall(vim.api.nvim_win_close, winid, true)
        local ok, lines = pcall(vim.fn.readfile, outfile)
        vim.fn.delete(outfile)

        if ok and lines[1] and lines[1] ~= "" then
          on_select((lines[1]:gsub("[\r\n]+$", "")))
        end
      end)
    end,
  })

  vim.fn.jobstart({ "sh", "-c", command .. " > " .. outfile }, { term = true })
  vim.cmd.startinsert()
end

function M.files()
  run("fzf --prompt='Files> '", function(file)
    vim.cmd("edit " .. vim.fn.fnameescape(file))
    vim.cmd("FileTreeClose")
  end)
end

function M.grep()
  if vim.fn.executable("rg") == 0 then
    return
  end

  local preview = vim.fn.executable("bat") == 1 and "bat --style=numbers --color=always --highlight-line {2} {1}"
      or "cat {1}"

  local command = string.format(
    'fzf --ansi --disabled --prompt="Grep> " --delimiter=: '
    .. '--preview="%s" --preview-window="right:60%%:wrap:+{2}-/2" '
    .. '--bind="change:reload:sleep 0.1; rg --column --line-number --no-heading --color=always --smart-case {q} || true"',
    preview
  )

  run(command, function(line)
    local file, lnum, col = line:match("([^:]+):(%d+):(%d+)")
    if file and lnum and col then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
      vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
      vim.cmd("normal! zz")
    end
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader><leader>", M.files, { desc = "Open FZF" })
  vim.keymap.set("n", "<leader>fg", M.grep, { desc = "Open Grep" })
end

return M
