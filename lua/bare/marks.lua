local M = {}
local sign = "BuiltinMark"
local group = "BuiltinMarkGroup"
local defined_signs = {}

local function update_signs()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.fn.sign_unplace(group, { buffer = bufnr })
      for _, m in ipairs(vim.fn.getmarklist(bufnr)) do
        local name = m.mark:sub(2, 2)
        if name:match("[a-z]") and m.pos and m.pos[2] > 0 then
          local sign_name = sign .. name
          if not defined_signs[sign_name] then
            vim.fn.sign_define(sign_name, { text = name, texthl = "Comment" })
            defined_signs[sign_name] = true
          end
          vim.fn.sign_place(0, group, sign_name, bufnr, { lnum = m.pos[2] })
        end
      end
      for _, m in ipairs(vim.fn.getmarklist()) do
        local name = m.mark:sub(2, 2)
        if name:match("[A-Z]") and m.pos and m.pos[1] == bufnr and m.pos[2] > 0 then
          local sign_name = sign .. name
          if not defined_signs[sign_name] then
            vim.fn.sign_define(sign_name, { text = name, texthl = "String" })
            defined_signs[sign_name] = true
          end
          vim.fn.sign_place(0, group, sign_name, bufnr, { lnum = m.pos[2] })
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
        local bufname = m.file or vim.api.nvim_buf_get_name(m.pos[1] or 0)
        table.insert(all, {
          name = n,
          file = bufname,
          lnum = m.pos[2],
          col = m.pos[3],
          buf = m.pos[1],
        })
      end
    end
  end
  collect(vim.fn.getmarklist(vim.api.nvim_get_current_buf()))
  collect(vim.fn.getmarklist())
  table.sort(all, function(a, b) return a.name < b.name end)
  return all
end

local function jump_to_mark(mark)
  if mark.file ~= "" and mark.file ~= vim.api.nvim_buf_get_name(0) then
    vim.cmd("edit " .. vim.fn.fnameescape(mark.file))
  end
  if vim.api.nvim_buf_is_valid(0) then
    local success, _ = pcall(vim.api.nvim_win_set_cursor, 0, { mark.lnum, math.max(mark.col - 1, 0) })
    if success then
      vim.cmd("normal! zz")
    end
  end
end

local function show_marks()
  local marks = get_marks()
  if #marks == 0 then
    vim.notify("No marks", vim.log.levels.INFO)
    return
  end
  local lines = {}
  local max_filename_length = 0
  for _, m in ipairs(marks) do
    local fname = vim.fn.fnamemodify(m.file, ":~:.")
    max_filename_length = math.max(max_filename_length, #fname)
  end
  max_filename_length = math.min(max_filename_length, 40)
  for _, m in ipairs(marks) do
    local fname = vim.fn.fnamemodify(m.file, ":~:.")
    if #fname > max_filename_length then
      fname = "…" .. fname:sub(-max_filename_length + 1)
    end
    local formatted_line = string.format("%s  %-" .. max_filename_length .. "s:%d", m.name, fname, m.lnum)
    table.insert(lines, formatted_line)
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "marks", { buf = buf })
  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, #l) end
  width = math.min(width + 4, vim.o.columns - 10)
  local height = math.min(#lines, 20)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  for i, m in ipairs(marks) do
    vim.keymap.set("n", m.name, function()
      close()
      jump_to_mark(m)
    end, { buffer = buf, nowait = true })
  end
  vim.keymap.set("n", "<CR>", function()
    local idx = vim.api.nvim_win_get_cursor(win)[1]
    local m = marks[idx]
    if m then
      close()
      jump_to_mark(m)
    end
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "x", function()
    local idx = vim.api.nvim_win_get_cursor(win)[1]
    local m = marks[idx]
    if m then
      local current_buf = vim.api.nvim_get_current_buf()
      local target_buf = m.buf or current_buf
      if vim.api.nvim_buf_is_valid(target_buf) then
        vim.api.nvim_set_current_buf(target_buf)
      end
      vim.cmd("delmarks " .. m.name)
      close()
      vim.schedule(function()
        update_signs()
        show_marks()
      end)
    end
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Down>", "j", { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Up>", "k", { buffer = buf, nowait = true })
end

function M.setup()
  vim.api.nvim_create_autocmd({ "CursorHold", "BufEnter", "BufWritePost" }, {
    callback = update_signs
  })
  vim.schedule(update_signs)
  vim.api.nvim_create_user_command("Marks", show_marks, {})
  vim.keymap.set("n", "<leader>mm", show_marks, { desc = "Show marks" })
end

return M
