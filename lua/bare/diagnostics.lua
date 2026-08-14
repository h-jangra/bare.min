local M = {}
local ui = require("bare.ui")
local ns = vim.api.nvim_create_namespace("bare_diagnostics")

local severities = {
  [vim.diagnostic.severity.ERROR] = { icon = "󰅚 ", hl = "DiagnosticError" },
  [vim.diagnostic.severity.WARN] = { icon = "󰀦 ", hl = "DiagnosticWarn" },
  [vim.diagnostic.severity.INFO] = { icon = "󰋼 ", hl = "DiagnosticInfo" },
  [vim.diagnostic.severity.HINT] = { icon = "󰌵 ", hl = "DiagnosticHint" },
}

local function collect(bufnr)
  local diags = bufnr and vim.diagnostic.get(bufnr) or vim.diagnostic.get()
  local items = {}
  for _, d in ipairs(diags) do
    local path = vim.api.nvim_buf_get_name(d.bufnr)
    local rel = path ~= "" and (vim.fs.relpath(vim.fn.getcwd(), path) or path) or "Untitled"
    local sev = severities[d.severity] or severities[vim.diagnostic.severity.INFO]
    table.insert(items, {
      bufnr = d.bufnr,
      path = path,
      lnum = d.lnum + 1,
      col = d.col,
      severity = d.severity,
      icon = sev.icon,
      hl = sev.hl,
      loc = string.format("%s:%d:%d", rel, d.lnum + 1, d.col + 1),
      msg = (d.message:gsub("[\r\n]+", " ")),
    })
  end
  table.sort(items, function(a, b)
    if a.severity ~= b.severity then
      return a.severity < b.severity
    end
    if a.path ~= b.path then
      return a.path < b.path
    end
    return a.lnum < b.lnum
  end)
  return items
end

local function open_picker(title, items)
  if #items == 0 then
    return vim.notify("No diagnostics found", vim.log.levels.INFO)
  end
  local orig_win, lines, hls = vim.api.nvim_get_current_win(), {}, {}

  for i, it in ipairs(items) do
    table.insert(lines, string.format(" %s %-24s %s", it.icon, it.loc, it.msg))
    table.insert(hls, { row = i - 1, hl = it.hl, icon_len = #it.icon + 1, loc_len = #it.loc })
  end

  local buf, win = ui.float({
    width = math.min(math.floor(vim.o.columns * 0.88), 90),
    height = math.min(#lines, math.floor(vim.o.lines * 0.65)),
    title = string.format(" %s (%d) ", title, #items),
    enter = true,
  })

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable, vim.bo[buf].buftype, vim.bo[buf].filetype = false, "nofile", "bare_diagnostics"
  vim.wo[win].cursorline = true

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_set_extmark(buf, ns, h.row, 1, { end_col = 1 + h.icon_len, hl_group = h.hl })
    vim.api.nvim_buf_set_extmark(
      buf,
      ns,
      h.row,
      1 + h.icon_len + 1,
      { end_col = 1 + h.icon_len + 1 + h.loc_len, hl_group = "Directory" }
    )
  end

  local function choose(cmd)
    local idx = vim.api.nvim_win_get_cursor(win)[1]
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_win_is_valid(orig_win) then
      vim.api.nvim_set_current_win(orig_win)
    end
    local it = items[idx]
    if it then
      if it.path ~= "" and it.path ~= vim.api.nvim_buf_get_name(0) then
        vim.cmd((cmd or "edit") .. " " .. vim.fn.fnameescape(it.path))
      end
      vim.api.nvim_win_set_cursor(0, { it.lnum, it.col })
      vim.cmd("normal! zz")
    end
  end

  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>", function()
    choose("edit")
  end, opts)
  vim.keymap.set("n", "v", function()
    choose("vsplit")
  end, opts)
  vim.keymap.set("n", "s", function()
    choose("split")
  end, opts)
  vim.keymap.set("n", "<C-t>", function()
    choose("tabedit")
  end, opts)
  for _, k in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", k, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, opts)
  end
end

function M.picker_workspace()
  open_picker("Workspace Diagnostics", collect(nil))
end

function M.picker_buffer()
  open_picker("Buffer Diagnostics", collect(vim.api.nvim_get_current_buf()))
end

function M.quickfix()
  vim.diagnostic.setqflist({ open = false })
  if #vim.fn.getqflist() == 0 then
    return vim.notify("No workspace diagnostics", vim.log.levels.INFO)
  end
  vim.cmd("copen")
end

function M.loclist()
  vim.diagnostic.setloclist({ open = false })
  if #vim.fn.getloclist(0) == 0 then
    return vim.notify("No buffer diagnostics", vim.log.levels.INFO)
  end
  vim.cmd("lopen")
end

function M.toggle_qf()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "quickfix" then
      return vim.cmd("cclose")
    end
  end
  M.quickfix()
end

function M.toggle_loc()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local wininfo = vim.fn.getwininfo(win)
    if wininfo and #wininfo > 0 and wininfo[1].loclist == 1 then
      return vim.cmd("lclose")
    end
  end
  M.loclist()
end

function M.open_float()
  vim.diagnostic.open_float({ border = "rounded" })
end

function M.next(severity)
  vim.diagnostic.jump({ count = 1, float = true, severity = severity })
  vim.schedule(function()
    vim.cmd("normal! zz")
  end)
end

function M.prev(severity)
  vim.diagnostic.jump({ count = -1, float = true, severity = severity })
  vim.schedule(function()
    vim.cmd("normal! zz")
  end)
end

function M.next_error()
  M.next(vim.diagnostic.severity.ERROR)
end

function M.prev_error()
  M.prev(vim.diagnostic.severity.ERROR)
end

function M.next_warn()
  M.next(vim.diagnostic.severity.WARN)
end

function M.prev_warn()
  M.prev(vim.diagnostic.severity.WARN)
end

function M.toggle()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  vim.notify("Diagnostics " .. (not enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end

function M.copy_line()
  local diags = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
  if #diags == 0 then
    return vim.notify("No diagnostics on this line", vim.log.levels.WARN)
  end
  vim.fn.setreg(
    "+",
    vim.iter(diags)
    :map(function(d)
      return d.message
    end)
    :join("\n")
  )
  vim.notify("Copied line diagnostic(s) to clipboard")
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
  vim.api.nvim_create_user_command("Diagnostics", M.picker_workspace, { desc = "Workspace diagnostics picker" })
end

return M
