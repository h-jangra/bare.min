local M = {}
local state = { job_id = nil, port = 8080, dir = nil }

-- Get URL
local function url() return "http://localhost:" .. state.port .. "/" end

-- Check if server is running
local function running() return state.job_id ~= nil end

-- Open URL in default browser
local function open_browser(u)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = "open"
  elseif vim.fn.has("unix") == 1 then
    cmd = "xdg-open"
  elseif vim.fn.has("win32") == 1 then
    cmd = "start"
  end
  if cmd then vim.fn.jobstart({ cmd, u }, { detach = true }) end
end

-- Start server (stops previous if any)
function M.start(port)
  if running() then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end
  state.port = port or state.port
  state.dir = vim.fn.getcwd()

  state.job_id = vim.fn.jobstart(
    { "python3", "-m", "http.server", tostring(state.port) },
    { cwd = state.dir, detach = true }
  )

  if state.job_id <= 0 then
    state.job_id = nil
    vim.notify("[LiveServer] Failed to start server", vim.log.levels.ERROR)
    return
  end

  vim.notify("[LiveServer] Started at " .. url())
  vim.defer_fn(function() open_browser(url()) end, 300)
end

-- Setup user command
function M.setup(opts)
  opts = opts or {}
  state.port = opts.default_port or 8080

  vim.api.nvim_create_user_command("LiveServerStart", function(cmd)
    M.start(tonumber(cmd.args) or state.port)
  end, { nargs = "?", desc = "Start live server (stops previous, opens in browser)" })
end

return M
