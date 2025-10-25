-- Requires Busybox, Tinymist & Grip

local M, state = {}, {
  html_job = nil,
  html_port = 8080,
  typst_jobs = {},
  md_job = nil,
  md_port = 6419,
  md_file = nil,
}

local function open_browser(url)
  local cmd = vim.fn.has("mac") == 1 and "open"
      or vim.fn.has("unix") == 1 and "xdg-open"
      or "start"
  vim.fn.jobstart({ cmd, url }, { detach = true })
end

local function check_exec(name)
  if vim.fn.executable(name) ~= 1 then
    vim.notify(name .. " not found in PATH", vim.log.levels.WARN)
    return false
  end
  return true
end

function M.start_html(port)
  M.stop_html()
  if not check_exec("busybox") then return end
  state.html_port = port or state.html_port
  state.html_job = vim.fn.jobstart({ "busybox", "httpd", "-f", "-p", tostring(state.html_port) },
    { cwd = vim.fn.getcwd() })
  open_browser("http://localhost:" .. state.html_port .. "/index.html")
end

function M.stop_html()
  if state.html_job then
    vim.fn.jobstop(state.html_job)
    state.html_job = nil
  end
end

function M.start_typst()
  local file = vim.fn.expand("%:p")
  if not file:match("%.typ$") then
    vim.notify("Not a typst file", vim.log.levels.WARN)
    return
  end
  if state.typst_jobs[file] then vim.fn.jobstop(state.typst_jobs[file]) end
  state.typst_jobs[file] = vim.fn.jobstart({ "tinymist", "preview", file }, { cwd = vim.fn.fnamemodify(file, ":h") })
  open_browser("http://127.0.0.1:23625")
end

function M.stop_typst()
  for _, job in pairs(state.typst_jobs) do vim.fn.jobstop(job) end
  state.typst_jobs = {}
end

function M.start_md(port)
  M.stop_md()
  local file = vim.fn.expand("%:p")
  state.md_port = port or state.md_port
  state.md_job = vim.fn.jobstart({ "grip", file, tostring(state.md_port) })
  vim.defer_fn(function()
    open_browser("http://localhost:" .. state.md_port)
  end, 500)
end

function M.stop_md()
  if state.md_job then
    vim.fn.jobstop(state.md_job)
    state.md_job = nil
  end
end

function M.stop()
  M.stop_html()
  M.stop_typst()
  M.stop_md()
end

function M.setup(opts)
  state.html_port = opts and opts.html_port or 8080
  state.md_port = opts and opts.md_port or 6419

  local cmds = {
    html = { "PreviewHTML", M.start_html },
    typst = { "PreviewTypst", M.start_typst },
    markdown = { "PreviewMarkdown", M.start_md },
  }

  for ft, c in pairs(cmds) do
    vim.api.nvim_create_autocmd("FileType", {
      pattern = ft,
      callback = function()
        vim.api.nvim_create_user_command(c[1], function(cmd) c[2](tonumber(cmd.args) or nil) end, { nargs = "?" })
      end
    })
  end

  vim.api.nvim_create_user_command("PreviewStop", M.stop, {})
  vim.api.nvim_create_autocmd("VimLeavePre", { callback = M.stop })
end

return M
