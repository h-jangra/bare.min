local M = {}
local ui = require("bare.ui")

local active_notifs, history = {}, {}
M.history = history

local active_view, history_view = {}, {}
local ns_id = vim.api.nvim_create_namespace("bare_notify")

local levels = {
  [vim.log.levels.ERROR] = { icon = "󰅚 ", hl = "DiagnosticError" },
  [vim.log.levels.WARN]  = { icon = "󰀦 ", hl = "DiagnosticWarn" },
  [vim.log.levels.INFO]  = { icon = "󰋼 ", hl = "DiagnosticInfo" },
  [vim.log.levels.DEBUG] = { icon = "󰌵 ", hl = "DiagnosticHint" },
  [vim.log.levels.TRACE] = { icon = "󰌵 ", hl = "DiagnosticHint" },
}

local function get_level_info(level)
  if type(level) == "string" then level = vim.log.levels[level:upper()] end
  return levels[level] or levels[vim.log.levels.INFO]
end

local function close_view(view)
  if view.win and vim.api.nvim_win_is_valid(view.win) then
    vim.api.nvim_win_close(view.win, true)
  end
  view.win = nil
end

local function render_notifs(notifs, is_history)
  if is_history and #notifs == 0 then
    return { "No notification history" }, { { line = 0, hl = "Comment" } }
  end

  local lines, highlights = {}, {}
  for _, notif in ipairs(notifs) do
    local time_prefix = is_history and ("[" .. notif.time .. "] ") or ""
    local icon_title = notif.icon .. (notif.title and ("[" .. notif.title .. "] ") or "")
    local prefix = time_prefix .. icon_title

    for i, line in ipairs(notif.lines) do
      table.insert(lines, (i == 1 and prefix or string.rep(" ", #prefix)) .. line)
      local idx = #lines - 1
      if is_history then
        if i == 1 then
          table.insert(highlights, { line = idx, hl = "Comment", col_start = 0, col_end = #time_prefix })
          table.insert(highlights, { line = idx, hl = notif.hl, col_start = #time_prefix, col_end = #prefix })
        end
      else
        table.insert(highlights, { line = idx, hl = notif.hl })
      end
    end
  end
  return lines, highlights
end

local function update_view(view, notifs, is_history)
  if not is_history and #notifs == 0 then
    return close_view(view)
  end

  local lines, highlights = render_notifs(notifs, is_history)
  local max_w = 0
  for _, l in ipairs(lines) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(l))
  end

  local config
  if is_history then
    local width = math.max(32, math.min(max_w + 4, math.floor(vim.o.columns * 0.8)))
    local height = math.max(1, math.min(#lines, math.floor(vim.o.lines * 0.6)))
    config = {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "rounded",
      title = " Notifications History (" .. #history .. ") ",
      title_pos = "center",
      enter = true,
      buf = view.buf,
      win = view.win,
    }
  else
    local width = math.max(1, math.min(max_w, math.floor(vim.o.columns * 0.6)))
    local height = #lines
    local margin_bottom = (vim.o.cmdheight or 1) + (vim.o.laststatus > 0 and 1 or 0)
    config = {
      relative = "editor",
      width = width,
      height = height,
      row = math.max(0, vim.o.lines - height - margin_bottom),
      col = math.max(0, vim.o.columns - width),
      style = "minimal",
      border = "none",
      focusable = false,
      zindex = 250,
      enter = false,
      buf = view.buf,
      win = view.win,
    }
  end

  local buf, win = ui.float(config)
  view.buf, view.win = buf, win

  vim.bo[buf].bufhidden = "wipe"
  if is_history then
    vim.bo[buf].filetype = "bare_notify_history"
    vim.wo[win].winblend = 0
    vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual"
    vim.wo[win].cursorline = true
  else
    vim.wo[win].winblend = 0
    vim.wo[win].winhighlight = "NormalFloat:NormalFloat"
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  for _, h in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns_id, h.hl, h.line, h.col_start or 0, h.col_end or -1)
  end

  return lines
end

local function refresh_active()
  update_view(active_view, active_notifs, false)
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
  if #history > 100 then table.remove(history, 1) end

  vim.defer_fn(function()
    for i, n in ipairs(active_notifs) do
      if n == notif then
        table.remove(active_notifs, i)
        break
      end
    end
    vim.schedule(refresh_active)
  end, opts.timeout or 3000)

  vim.schedule(refresh_active)
end

function M.clear()
  for i = #active_notifs, 1, -1 do active_notifs[i] = nil end
  close_view(active_view)
end

function M.clear_history()
  for i = #history, 1, -1 do history[i] = nil end
  close_view(history_view)
  vim.notify("Notification history cleared", vim.log.levels.INFO)
end

function M.show_history()
  if history_view.win and vim.api.nvim_win_is_valid(history_view.win) then
    return close_view(history_view)
  end

  local lines = update_view(history_view, history, true)
  vim.bo[history_view.buf].modifiable = false

  local close = function() close_view(history_view) end
  local opts = { buffer = history_view.buf, silent = true, noremap = true }
  for _, key in ipairs({ "q", "<Esc>" }) do vim.keymap.set("n", key, close, opts) end
  for _, key in ipairs({ "c", "C" }) do vim.keymap.set("n", key, M.clear_history, opts) end

  if #lines > 0 then
    vim.api.nvim_win_set_cursor(history_view.win, { #lines, 0 })
  end
end

local function setup_autocmds()
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("BareNotifySave", { clear = true }),
    callback = function(args)
      if vim.bo[args.buf].buftype == "" then
        local path = vim.api.nvim_buf_get_name(args.buf)
        if path ~= "" then
          vim.notify("Saved " .. vim.fn.fnamemodify(path, ":~:."), vim.log.levels.INFO)
        end
      end
    end,
  })
end

local function setup_lsp()
  if vim.lsp and vim.lsp.handlers then
    vim.lsp.handlers["window/showMessage"] = function(_, result, ctx)
      if result and result.message then
        local client = ctx and ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id)
        local lvl = ({ vim.log.levels.ERROR, vim.log.levels.WARN, vim.log.levels.INFO, vim.log.levels.DEBUG })
            [result.type]
        vim.notify(result.message, lvl or vim.log.levels.INFO, { title = client and client.name or "LSP" })
      end
    end
  end
end

local function setup_commands()
  for _, cmd in ipairs({ "w", "write", "update", "wa", "wall" }) do
    vim.cmd(string.format("cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? 'silent %s' : '%s'",
      cmd, cmd, cmd, cmd))
  end

  vim.api.nvim_create_user_command("NotifyHistory", M.show_history,
    { desc = "Show notification history floating window" })
  vim.keymap.set("n", "<leader>n", M.show_history, { desc = "Show Notification History" })
end

function M.setup()
  vim.notify = M.notify
  setup_autocmds()
  setup_lsp()
  setup_commands()
end

return M
