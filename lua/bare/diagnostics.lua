local M = {}

local function open(cmd, list, msg)
  if #list() == 0 then
    return vim.notify(msg, vim.log.levels.INFO)
  end
  vim.cmd(cmd)
end
function M.workspace()
  vim.diagnostic.setqflist()
  open("copen", vim.fn.getqflist, "No diagnostics")
end

function M.buffer()
  vim.diagnostic.setloclist()
  open("lopen", function()
    return vim.fn.getloclist(0)
  end, "No diagnostics")
end

function M.float()
  vim.diagnostic.open_float({ border = "rounded" })
end

function M.jump(count, severity)
  vim.diagnostic.jump({ count = count, float = true, severity = severity })
  vim.cmd("normal! zz")
end

function M.copy_line()
  local diags = vim.diagnostic.get(0, {
    lnum = vim.fn.line(".") - 1,
  })

  if #diags > 0 then
    vim.fn.setreg("+", table.concat(vim.tbl_map(function(d)
      return d.message
    end, diags), "\n"))
  end
end

function M.setup()
  vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded" },
  })

  local map = vim.keymap.set
  local error = vim.diagnostic.severity.ERROR
  local warn = vim.diagnostic.severity.WARN

  map("n", "<leader>dw", M.workspace, { desc = "Diagnostics" })
  map("n", "<leader>db", M.buffer, { desc = "Buffer Diagnostics" })
  map("n", "<leader>df", M.float, { desc = "Diagnostic Float" })
  map("n", "<leader>dc", M.copy_line, { desc = "Copy Diagnostic" })

  map("n", "]e", function() M.jump(1, error) end, { desc = "Next Error" })
  map("n", "[e", function() M.jump(-1, error) end, { desc = "Prev Error" })
  map("n", "]w", function() M.jump(1, warn) end, { desc = "Next Warning" })
  map("n", "[w", function() M.jump(-1, warn) end, { desc = "Prev Warning" })
end

return M
