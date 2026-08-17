local M = { history = {} }
local ui = require("bare.ui")
local ns = vim.api.nvim_create_namespace("bare_notify")

local active, MAX_HISTORY = {}, 100
local active_win, active_buf, hist_win

local levels = {
  [vim.log.levels.ERROR] = { "󰅚 ", "DiagnosticError" },
  [vim.log.levels.WARN] = { "󰀦 ", "DiagnosticWarn" },
  [vim.log.levels.INFO] = { "󰋼 ", "DiagnosticInfo" },
  [vim.log.levels.DEBUG] = { "󰌵 ", "DiagnosticHint" },
  [vim.log.levels.TRACE] = { "󰌵 ", "DiagnosticHint" },
}

local function get_level(lvl)
  lvl = type(lvl) == "string" and vim.log.levels[lvl:upper()] or lvl
  return levels[lvl] or levels[vim.log.levels.INFO]
end

local function build_lines(notifs, is_hist)
  if is_hist and #notifs == 0 then
    return { " No notification history " }, { { 0, "Comment", 0, -1 } }, 25
  end
  local lines, hls, max_w = {}, {}, 0
  for _, n in ipairs(notifs) do
    local time = is_hist and ("[" .. n.time .. "] ") or ""
    local pfx = time .. n.icon .. (n.title and ("[" .. n.title .. "] ") or "")
    local pad = string.rep(" ", #pfx)
    for i, line in ipairs(n.lines) do
      local s = " " .. (i == 1 and pfx or pad) .. line .. " "
      lines[#lines + 1] = s
      max_w = math.max(max_w, vim.fn.strdisplaywidth(s))
      local lnum = #lines - 1
      if is_hist then
        if i == 1 then
          hls[#hls + 1] = { lnum, "Comment", 1, 1 + #time }
          hls[#hls + 1] = { lnum, n.hl, 1 + #time, 1 + #pfx }
        end
      else
        hls[#hls + 1] = { lnum, n.hl, 0, -1 }
      end
    end
  end
  return lines, hls, max_w
end

local function set_content(buf, lines, hls)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(buf, ns, h[2], h[1], h[3], h[4])
  end

  vim.bo[buf].modifiable = false
end

local function update_active()
  if #active == 0 then
    if active_win and vim.api.nvim_win_is_valid(active_win) then
      vim.api.nvim_win_close(active_win, true)
      active_win = nil
    end
    return
  end

  local lines, hls, w = build_lines(active, false)
  w = math.max(1, math.min(w, math.floor(vim.o.columns * 0.6)))
  local h = #lines
  active_buf, active_win = ui.float({
    buf = active_buf,
    win = active_win,
    width = w,
    height = h,
    row = math.max(0, vim.o.lines - h - vim.o.cmdheight - 1),
    col = math.max(0, vim.o.columns - w - 1),
    border = "none",
    enter = false,
    focusable = false,
    zindex = 250,
  })
  vim.bo[active_buf].bufhidden = "wipe"
  set_content(active_buf, lines, hls)
end

function M.notify(msg, level, opts)
  opts = opts or {}
  local info = get_level(level)
  local notif = {
    time = os.date("%H:%M:%S"),
    title = opts.title,
    lines = vim.split(type(msg) == "string" and msg or vim.inspect(msg), "\n", { plain = true }),
    icon = info[1],
    hl = info[2],
  }

  table.insert(active, notif)
  table.insert(M.history, notif)
  if #M.history > MAX_HISTORY then
    table.remove(M.history, 1)
  end

  vim.defer_fn(function()
    for i, n in ipairs(active) do
      if n == notif then
        table.remove(active, i)
        break
      end
    end
    vim.schedule(update_active)
  end, opts.timeout or 3000)

  vim.schedule(update_active)
end

function M.clear()
  active = {}
  update_active()
end

function M.clear_history()
  M.history = {}
  if hist_win and vim.api.nvim_win_is_valid(hist_win) then
    vim.api.nvim_win_close(hist_win, true)
    hist_win = nil
  end
end

function M.show_history()
  if hist_win and vim.api.nvim_win_is_valid(hist_win) then
    vim.api.nvim_win_close(hist_win, true)
    hist_win = nil
    return
  end

  local lines, hls = build_lines(M.history, true)
  local buf, win = ui.float({
    lines = lines,
    height = math.min(#lines, math.floor(vim.o.lines * 0.6)),
    title = string.format(" Notifications (%d) ", #M.history),
  })
  hist_win = win

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "bare_notify_history"
  set_content(buf, lines, hls)

  for _, k in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", k, function()
      if hist_win and vim.api.nvim_win_is_valid(hist_win) then
        vim.api.nvim_win_close(hist_win, true)
        hist_win = nil
      end
    end, { buffer = buf, silent = true, nowait = true })
  end
  for _, k in ipairs({ "c", "C" }) do
    vim.keymap.set("n", k, M.clear_history, { buffer = buf, silent = true, nowait = true })
  end

  if #lines > 0 then
    vim.api.nvim_win_set_cursor(win, { #lines, 0 })
  end
end

function M.setup()
  vim.notify = M.notify

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("BareNotifySave", { clear = true }),
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if vim.bo[args.buf].buftype == "" and name ~= "" then
        vim.notify("Saved " .. vim.fn.fnamemodify(name, ":~:."), vim.log.levels.INFO)
      end
    end,
  })

  for _, cmd in ipairs({ "w", "write", "update", "wa", "wall" }) do
    vim.cmd(string.format(
      "cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? 'silent %s' : '%s'",
      cmd, cmd, cmd, cmd
    ))
  end

  vim.api.nvim_create_user_command("NotifyHistory", M.show_history, {
    desc = "Show notification history floating window",
  })
end

return M
