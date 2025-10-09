local M = {}
local sign = "BuiltinMark"
local group = "BuiltinMarkGroup"

local function update_signs()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    vim.fn.sign_unplace(group, { buffer = bufnr })
    for _, m in ipairs(vim.fn.getmarklist(bufnr)) do
      local name = m.mark:sub(2, 2)
      if name:match("%a") and m.pos and m.pos[2] > 0 then
        vim.fn.sign_define(sign .. name, { text = name, texthl = "WarningMsg" })
        vim.fn.sign_place(0, group, sign .. name, bufnr, { lnum = m.pos[2] })
      end
    end
  end
end

local function get_marks()
  local all = {}
  local seen = {}
  local function collect(list)
    for _, m in ipairs(list) do
      local n = m.mark:sub(2, 2)
      if n:match("[%a]") and not seen[n] and m.pos and m.pos[2] > 0 then
        seen[n] = true
        table.insert(all, {
          name = n,
          file = m.file or vim.api.nvim_buf_get_name(m.pos[1] or 0),
          lnum = m.pos[2],
          col = m.pos[3],
        })
      end
    end
  end
  collect(vim.fn.getmarklist(vim.api.nvim_get_current_buf()))
  collect(vim.fn.getmarklist())
  table.sort(all, function(a, b) return a.name < b.name end)
  return all
end

local function show_marks()
  local marks = get_marks()
  if #marks == 0 then return vim.notify("No marks") end

  local lines = { "Marks (press letter to jump, x=delete, q=quit)" }
  for _, m in ipairs(marks) do
    table.insert(lines, string.format(" %s → %s:%d", m.name,
      vim.fn.fnamemodify(m.file, ":t"), m.lnum))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, #l) end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width + 2,
    height = #lines + 2,
    row = math.floor((vim.o.lines - #lines) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  for _, m in ipairs(marks) do
    vim.keymap.set("n", m.name, function()
      close()
      if m.file ~= "" then vim.cmd("edit " .. vim.fn.fnameescape(m.file)) end
      pcall(vim.api.nvim_win_set_cursor, 0, { m.lnum, math.max(m.col - 1, 0) })
      vim.cmd("normal! zz")
    end, { buffer = buf, nowait = true })
  end

  vim.keymap.set("n", "x", function()
    local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    local mark_index = cursor_line - 1

    if mark_index > 0 and mark_index <= #marks then
      local mark_to_delete = marks[mark_index].name
      local file = marks[mark_index].file

      if file ~= "" and vim.fn.filereadable(file) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(file))
      end

      vim.cmd("delmarks " .. mark_to_delete)

      close()
      vim.schedule(show_marks)
    end
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

function M.setup()
  vim.fn.sign_define(sign, { text = "", texthl = "WarningMsg" })
  vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, { callback = update_signs })
  vim.api.nvim_create_user_command("Marks", show_marks, {})
  vim.keymap.set("n", "<leader>mm", show_marks, { desc = "Show marks" })
end

return M
