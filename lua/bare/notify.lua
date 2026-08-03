local M = {}

local ui = require("bare.ui")

local active_notifs = {}
local history = {}
M.history = history

local active_view = {}
local history_view = {}
local ns_id = vim.api.nvim_create_namespace("bare_notify")

local levels = {
  [vim.log.levels.ERROR] = { icon = "󰅚 ", hl = "DiagnosticError" },
  [vim.log.levels.WARN]  = { icon = "󰀦 ", hl = "DiagnosticWarn" },
  [vim.log.levels.INFO]  = { icon = "󰋼 ", hl = "DiagnosticInfo" },
  [vim.log.levels.DEBUG] = { icon = "󰌵 ", hl = "DiagnosticHint" },
  [vim.log.levels.TRACE] = { icon = "󰌵 ", hl = "DiagnosticHint" },
}

local function get_level_info(level)
  if type(level) == "string" then
    level = vim.log.levels[level:upper()]
  end
  return levels[level] or levels[vim.log.levels.INFO]
end

local function fit_width(content_w, padding, min_w, max_ratio)
  return math.max(min_w, math.min(content_w + padding, math.floor(vim.o.columns * max_ratio)))
end

local function measure_width(lines)
  local w = 0
  for _, l in ipairs(lines) do
    w = math.max(w, vim.fn.strdisplaywidth(l))
  end
  return w
end

local function close_view(view)
  if view.win and vim.api.nvim_win_is_valid(view.win) then
    vim.api.nvim_win_close(view.win, true)
  end
  view.win = nil
end

local function ensure_float(view, config, enter, win_opts, filetype)
  config.buf = view.buf
  config.win = view.win
  config.enter = enter or false

  local buf, win = ui.float(config)
  view.buf = buf
  view.win = win

  vim.bo[buf].bufhidden = "wipe"
  if filetype and vim.bo[buf].filetype ~= filetype then
    vim.bo[buf].filetype = filetype
  end

  if win_opts then
    for k, v in pairs(win_opts) do
      vim.wo[win][k] = v
    end
  end
  return view
end

local function apply_buf(buf, lines, highlights)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  for _, h in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns_id, h.hl, h.line, h.col_start or 0, h.col_end or -1)
  end
end

local function render_notifs(notifs, is_history)
  if is_history and #notifs == 0 then
    return { "No notification history" }, { { line = 0, hl = "Comment" } }
  end

  local lines, highlights = {}, {}
  for idx, notif in ipairs(notifs) do
    local time_prefix = is_history and ("[" .. notif.time .. "] ") or ""
    local icon_title = notif.icon .. (notif.title and ("[" .. notif.title .. "] ") or "")
    local prefix = time_prefix .. icon_title

    for i, line in ipairs(notif.lines) do
      local pad = (i == 1) and prefix or string.rep(" ", #prefix)
      table.insert(lines, pad .. line)
      local line_idx = #lines - 1

      if is_history then
        if i == 1 then
          local t_len = #time_prefix
          table.insert(highlights, { line = line_idx, hl = "Comment", col_start = 0, col_end = t_len })
          table.insert(highlights, { line = line_idx, hl = notif.hl, col_start = t_len, col_end = #prefix })
        end
      else
        table.insert(highlights, { line = line_idx, hl = notif.hl })
      end
    end
  end

  return lines, highlights
end

local function render_view(view, notifs, is_history, calc_config, win_opts, filetype)
  local lines, highlights = render_notifs(notifs, is_history)
  local config = calc_config(#lines, measure_width(lines))
  ensure_float(view, config, is_history, win_opts, filetype)
  apply_buf(view.buf, lines, highlights)
  return lines
end

local function refresh_active()
  if #active_notifs == 0 then
    return close_view(active_view)
  end
  render_view(active_view, active_notifs, false, function(height, max_w)
    local width = fit_width(max_w, 0, 1, 0.6)
    local margin_bottom = (vim.o.cmdheight or 1) + (vim.o.laststatus > 0 and 1 or 0)
    local row = math.max(0, vim.o.lines - height - margin_bottom)
    local col = math.max(0, vim.o.columns - width)
    return {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "none",
      focusable = false,
      zindex = 250,
    }
  end, { winblend = 0, winhighlight = "NormalFloat:NormalFloat" })
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
  if #history > 100 then
    table.remove(history, 1)
  end

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

  local lines = render_view(history_view, history, true, function(line_cnt, max_w)
    local width = fit_width(max_w, 4, 32, 0.8)
    local height = math.max(1, math.min(line_cnt, math.floor(vim.o.lines * 0.6)))
    return {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "rounded",
      title = " Notifications History (" .. #history .. ") ",
      title_pos = "center",
    }
  end, {
    winblend = 0,
    winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual",
    cursorline = true,
  }, "bare_notify_history")

  vim.bo[history_view.buf].modifiable = false
  local close = function() close_view(history_view) end
  local opts = { buffer = history_view.buf, silent = true, noremap = true }
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  vim.keymap.set("n", "c", M.clear_history, opts)
  vim.keymap.set("n", "C", M.clear_history, opts)

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
  vim.cmd([[
    cnoreabbrev <expr> w (getcmdtype() ==# ':' && getcmdline() ==# 'w') ? 'silent w' : 'w'
    cnoreabbrev <expr> write (getcmdtype() ==# ':' && getcmdline() ==# 'write') ? 'silent write' : 'write'
    cnoreabbrev <expr> update (getcmdtype() ==# ':' && getcmdline() ==# 'update') ? 'silent update' : 'update'
    cnoreabbrev <expr> wa (getcmdtype() ==# ':' && getcmdline() ==# 'wa') ? 'silent wa' : 'wa'
    cnoreabbrev <expr> wall (getcmdtype() ==# ':' && getcmdline() ==# 'wall') ? 'silent wall' : 'wall'
  ]])

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
