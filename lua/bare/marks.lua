local M = {}
local sign, group, defined_signs = "BuiltinMark", "BuiltinMarkGroup", {}
local show_marks

local function place_signs(list, pat, hl, bufnr)
  for _, m in ipairs(list) do
    local name = m.mark:sub(2, 2)
    if name:match(pat) and m.pos and m.pos[2] > 0 and (pat == "[a-z]" or m.pos[1] == bufnr) then
      local s = sign .. name
      if not defined_signs[s] then
        vim.fn.sign_define(s, { text = name, texthl = hl })
        defined_signs[s] = true
      end
      vim.fn.sign_place(0, group, s, bufnr, { lnum = m.pos[2] })
    end
  end
end

local function update_signs(opts)
  local bufnr = (opts and opts.buf) or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(bufnr) or vim.bo[bufnr].buftype ~= "" then return end

  vim.fn.sign_unplace(group, { buffer = bufnr })
  place_signs(vim.fn.getmarklist(bufnr), "[a-z]", "Comment", bufnr)
  place_signs(vim.fn.getmarklist(), "[A-Z]", "String", bufnr)
end

local function get_marks()
  local marks, seen = {}, {}
  for _, list in ipairs({ vim.fn.getmarklist(0), vim.fn.getmarklist() }) do
    for _, m in ipairs(list) do
      local name = m.mark:sub(2, 2)
      if name:match("%a") and not seen[name] and m.pos and m.pos[2] > 0 then
        seen[name] = true
        marks[#marks + 1] = {
          name = name,
          file = (m.file and m.file ~= "") and m.file or vim.api.nvim_buf_get_name(m.pos[1] or 0),
          lnum = m.pos[2],
          col = m.pos[3],
          buf = m.pos[1],
        }
      end
    end
  end
  table.sort(marks, function(a, b) return a.name < b.name end)
  return marks
end

local function jump_to_mark(mark)
  if mark.file ~= "" and mark.file ~= vim.api.nvim_buf_get_name(0) then
    vim.cmd.edit(vim.fn.fnameescape(mark.file))
  end
  vim.api.nvim_win_set_cursor(0, { mark.lnum, math.max(mark.col - 1, 0) })
  vim.cmd.normal("zz")
end

local function create_window(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable, vim.bo[buf].filetype = false, "marks"

  local width, height = 0, math.min(#lines, 20)
  for _, l in ipairs(lines) do width = math.max(width, #l) end
  width = math.min(width + 4, vim.o.columns - 10)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  vim.wo[win].cursorline = true
  return buf, win
end

local function set_keymaps(buf, win, marks)
  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
  end

  local opts = { buffer = buf, nowait = true }

  for _, m in ipairs(marks) do
    vim.keymap.set("n", m.name, function() close(); jump_to_mark(m) end, opts)
  end

  vim.keymap.set("n", "<CR>", function()
    local m = marks[vim.api.nvim_win_get_cursor(win)[1]]
    if m then close(); jump_to_mark(m) end
  end, opts)

  vim.keymap.set("n", "x", function()
    local m = marks[vim.api.nvim_win_get_cursor(win)[1]]
    if m then
      if m.buf and vim.api.nvim_buf_is_valid(m.buf) then
        vim.api.nvim_set_current_buf(m.buf)
      end
      vim.cmd("delmarks " .. m.name)
      close()
      vim.schedule(function()
        update_signs()
        show_marks()
      end)
    end
  end, opts)

  for _, k in ipairs({ "q", "<Esc>" }) do vim.keymap.set("n", k, close, opts) end
  vim.keymap.set("n", "<Down>", "j", opts)
  vim.keymap.set("n", "<Up>", "k", opts)
end

show_marks = function()
  local marks = get_marks()
  if #marks == 0 then return vim.notify("No marks", vim.log.levels.INFO) end

  local lines, max_len = {}, 0
  for _, m in ipairs(marks) do
    max_len = math.min(math.max(max_len, #vim.fn.fnamemodify(m.file, ":~:.")), 40)
  end
  for _, m in ipairs(marks) do
    local f = vim.fn.fnamemodify(m.file, ":~:.")
    if #f > max_len then f = "…" .. f:sub(-max_len + 1) end
    lines[#lines + 1] = string.format("%s  %-" .. max_len .. "s:%d", m.name, f, m.lnum)
  end

  local buf, win = create_window(lines)
  set_keymaps(buf, win, marks)
end

function M.setup()
  vim.api.nvim_create_autocmd({ "CursorHold", "BufEnter", "BufWritePost" }, {
    callback = update_signs,
  })
  vim.schedule(update_signs)
  vim.api.nvim_create_user_command("Marks", show_marks, {})
  vim.keymap.set("n", "<leader>mm", show_marks, { desc = "Show marks" })
end

return M
