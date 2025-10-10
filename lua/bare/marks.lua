local M = {}
local sign = "BuiltinMark"
local group = "BuiltinMarkGroup"

local function update_signs()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.fn.sign_unplace(group, { buffer = bufnr })

      for _, m in ipairs(vim.fn.getmarklist(bufnr)) do
        local name = m.mark:sub(2, 2)
        if name:match("[a-z]") and m.pos and m.pos[2] > 0 then
          vim.fn.sign_define(sign .. name, { text = name, texthl = "Comment" })
          vim.fn.sign_place(0, group, sign .. name, bufnr, { lnum = m.pos[2] })
        end
      end

      for _, m in ipairs(vim.fn.getmarklist()) do
        local name = m.mark:sub(2, 2)
        if name:match("[A-Z]") and m.pos and m.pos[1] == bufnr and m.pos[2] > 0 then
          vim.fn.sign_define(sign .. name, { text = name, texthl = "String" })
          vim.fn.sign_place(0, group, sign .. name, bufnr, { lnum = m.pos[2] })
        end
      end
    end
  end
end

local function get_marks()
  local all, seen = {}, {}

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
  if #marks == 0 then return vim.notify("No marks", vim.log.levels.INFO) end

  local lines = {}
  for _, m in ipairs(marks) do
    local fname = vim.fn.fnamemodify(m.file, ":~:.")
    if #fname > 30 then fname = "…" .. fname:sub(-29) end
    table.insert(lines, string.format("%s  %s:%d", m.name, fname, m.lnum))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, #l) end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width + 4,
    height = math.min(#lines, 20),
    row = math.floor((vim.o.lines - math.min(#lines, 20)) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "single",
  })

  vim.api.nvim_set_option_value("cursorline", true, { win = win })

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end

  for i, m in ipairs(marks) do
    vim.keymap.set("n", m.name, function()
      close()
      if m.file ~= "" then vim.cmd("edit " .. vim.fn.fnameescape(m.file)) end
      pcall(vim.api.nvim_win_set_cursor, 0, { m.lnum, math.max(m.col - 1, 0) })
      vim.cmd("normal! zz")
    end, { buffer = buf, nowait = true })
  end

  vim.keymap.set("n", "<CR>", function()
    local idx = vim.api.nvim_win_get_cursor(win)[1]
    local m = marks[idx]
    if m then
      close()
      if m.file ~= "" then vim.cmd("edit " .. vim.fn.fnameescape(m.file)) end
      pcall(vim.api.nvim_win_set_cursor, 0, { m.lnum, math.max(m.col - 1, 0) })
      vim.cmd("normal! zz")
    end
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "x", function()
    local idx = vim.api.nvim_win_get_cursor(win)[1]
    local m = marks[idx]
    if m then
      if m.file ~= "" and vim.fn.filereadable(m.file) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(m.file))
      end
      vim.cmd("delmarks " .. m.name)
      close()
      vim.schedule(function()
        update_signs()
        show_marks()
      end)
    end
  end, { buffer = buf, nowait = true })

  update_signs()
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

function M.setup()
  -- vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TextChanged" }, {
  --   callback = update_signs
  -- })
  vim.api.nvim_create_autocmd("CursorHold", { callback = update_signs })
  vim.api.nvim_create_user_command("Marks", show_marks, {})
  vim.keymap.set("n", "<leader>mm", show_marks, { desc = "Show marks" })
  -- vim.schedule(update_signs)
end

return M
