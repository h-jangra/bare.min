local M = {}
local ui = require("bare.ui")

local active_notifs = {}
local MAX_HISTORY = 100
local history = {}
M.history = history

local views = { active = {}, history = {} }
local ns_id = vim.api.nvim_create_namespace("bare_notify")

local levels = {
  [vim.log.levels.ERROR] = { icon = "󰅚 ", hl = "DiagnosticError" },
  [vim.log.levels.WARN] = { icon = "󰀦 ", hl = "DiagnosticWarn" },
  [vim.log.levels.INFO] = { icon = "󰋼 ", hl = "DiagnosticInfo" },
  [vim.log.levels.DEBUG] = { icon = "󰌵 ", hl = "DiagnosticHint" },
  [vim.log.levels.TRACE] = { icon = "󰌵 ", hl = "DiagnosticHint" },
}

local function get_level_info(level)
  level = type(level) == "string" and vim.log.levels[level:upper()] or level
  return levels[level] or levels[vim.log.levels.INFO]
end

local function close_view(view)
  if view.win and vim.api.nvim_win_is_valid(view.win) then
    vim.api.nvim_win_close(view.win, true)
    view.win = nil
  end
end

local function render_notifs(notifs, is_history)
  if is_history and #notifs == 0 then
    return { " No notification history " }, { { line = 0, hl = "Comment", col_start = 0, col_end = -1 } }, 25
  end

  local lines, hls, max_w = {}, {}, 0
  for _, notif in ipairs(notifs) do
    local time_pfx = is_history and ("[" .. notif.time .. "] ") or ""
    local pfx = time_pfx .. notif.icon .. (notif.title and ("[" .. notif.title .. "] ") or "")

    for i, line in ipairs(notif.lines) do
      local str = " " .. (i == 1 and pfx or string.rep(" ", #pfx)) .. line .. " "
      table.insert(lines, str)
      max_w = math.max(max_w, vim.fn.strdisplaywidth(str))
      local idx = #lines - 1

      if is_history then
        if i == 1 then
          table.insert(hls, { line = idx, hl = "Comment", col_start = 1, col_end = 1 + #time_pfx })
          table.insert(hls, { line = idx, hl = notif.hl, col_start = 1 + #time_pfx, col_end = 1 + #pfx })
        end
      else
        table.insert(hls, { line = idx, hl = notif.hl, col_start = 0, col_end = -1 })
      end
    end
  end
  return lines, hls, max_w
end

local function render(buf, lines, hls)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(buf, ns_id, h.hl, h.line, h.col_start, h.col_end)
  end
end

local function update_view(view, notifs, is_history)
  if not is_history and #notifs == 0 then
    return close_view(view)
  end

  local lines, hls, width = render_notifs(notifs, is_history)
  local opts = {
    buf = view.buf,
    win = view.win,
  }

  if is_history then
    opts.lines = lines
    opts.height = math.min(#lines, math.floor(vim.o.lines * 0.6))
    opts.title = " Notifications (" .. #history .. ") "
  else
    width = math.max(1, math.min(width, math.floor(vim.o.columns * 0.6)))
    local height = #lines

    opts.width = width
    opts.height = height
    opts.row = math.max(0, vim.o.lines - height - vim.o.cmdheight - 1)
    opts.col = math.max(0, vim.o.columns - width - 1)
    opts.border = "none"
    opts.enter = false
    opts.focusable = false
    opts.zindex = 250
  end

  local buf, win = ui.float(opts)
  view.buf, view.win = buf, win

  vim.bo[buf].bufhidden = "wipe"
  if is_history then
    vim.bo[buf].filetype = "bare_notify_history"
  end
  render(buf, lines, hls)
  return lines
end

function M.notify(msg, level, opts)
  opts = opts or {}
  local info = get_level_info(level)
  local notif = {
    time = os.date("%H:%M:%S"),
    title = opts.title,
    lines = vim.split(type(msg) == "string" and msg or vim.inspect(msg), "\n", { plain = true }),
    icon = info.icon,
    hl = info.hl,
  }

  table.insert(active_notifs, notif)
  table.insert(history, notif)
  if #history > MAX_HISTORY then
    table.remove(history, 1)
  end

  local function refresh()
    update_view(views.active, active_notifs, false)
  end

  vim.defer_fn(function()
    for i, n in ipairs(active_notifs) do
      if n == notif then
        table.remove(active_notifs, i)
        break
      end
    end
    vim.schedule(refresh)
  end, opts.timeout or 3000)

  vim.schedule(refresh)
end

function M.clear()
  active_notifs = {}
  close_view(views.active)
end

function M.clear_history()
  for i = #history, 1, -1 do
    history[i] = nil
  end
  close_view(views.history)
end

function M.show_history()
  if views.history.win and vim.api.nvim_win_is_valid(views.history.win) then
    return close_view(views.history)
  end

  local lines = update_view(views.history, history, true)
  vim.bo[views.history.buf].modifiable = false

  local close = function()
    close_view(views.history)
  end
  local opts = { buffer = views.history.buf, silent = true, noremap = true }
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, close, opts)
  end
  for _, key in ipairs({ "c", "C" }) do
    vim.keymap.set("n", key, M.clear_history, opts)
  end

  if #lines > 0 then
    vim.api.nvim_win_set_cursor(views.history.win, { #lines, 0 })
  end
end

local function setup_autocmds()
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("BareNotifySave", { clear = true }),
    callback = function(args)
      if vim.bo[args.buf].buftype ~= "" then
        return
      end

      local path = vim.api.nvim_buf_get_name(args.buf)
      if path == "" then
        return
      end

      vim.notify("Saved " .. vim.fn.fnamemodify(path, ":~:."), vim.log.levels.INFO)
    end,
  })
end

local function setup_commands()
  for _, cmd in ipairs({ "w", "write", "update", "wa", "wall" }) do
    vim.cmd(
      string.format(
        "cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? 'silent %s' : '%s'",
        cmd,
        cmd,
        cmd,
        cmd
      )
    )
  end

  vim.api.nvim_create_user_command(
    "NotifyHistory",
    M.show_history,
    { desc = "Show notification history floating window" }
  )
end

function M.setup()
  vim.notify = M.notify
  setup_autocmds()
  setup_commands()
end

return M
