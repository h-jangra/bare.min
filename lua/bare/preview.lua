local M = {}

local state = {
  jobs = {},
  html_port = 8080,
  md_port = 6419,
}

local function executable(cmd)
  return vim.fn.executable(cmd) == 1
end

local function open(url)
  local opener = vim.fn.has("mac") == 1 and "open"
      or vim.fn.has("unix") == 1 and "xdg-open"
      or "start"

  vim.fn.jobstart({ opener, url }, { detach = true })
end

local function stop(name)
  local job = state.jobs[name]

  if job then
    pcall(vim.fn.jobstop, job)
    state.jobs[name] = nil
  end
end

local function current_file()
  return vim.api.nvim_buf_get_name(0)
end

local function start_html(port)
  if not executable("busybox") then return end

  stop("html")

  local file = current_file()

  state.html_port = port or state.html_port
  state.jobs.html = vim.fn.jobstart({
    "busybox",
    "httpd",
    "-f",
    "-p",
    tostring(state.html_port),
  }, {
    cwd = vim.fs.dirname(file),
  })

  open("http://localhost:" .. state.html_port .. "/" .. vim.fs.basename(file))
end

local function start_markdown(port)
  if not executable("grip") then
    return
  end

  stop("markdown")

  local file = current_file()

  state.md_port = port or state.md_port
  state.jobs.markdown = vim.fn.jobstart({
    "grip",
    file,
    tostring(state.md_port),
  })

  vim.defer_fn(function()
    open("http://localhost:" .. state.md_port)
  end, 700)
end

local function start_typst()
  if not executable("tinymist") then
    return
  end

  local file = current_file()
  stop(file)

  state.jobs[file] = vim.fn.jobstart({
    "tinymist",
    "preview",
    file,
    "--open",
  }, {
    cwd = vim.fs.dirname(file),
  })
end

function M.preview(opts)
  local ft = vim.bo.filetype
  local port = tonumber(opts.args)

  if ft == "html" then
    start_html(port)
  elseif ft == "markdown" then
    start_markdown(port)
  elseif ft == "typst" then
    start_typst()
  end
end

function M.stop()
  for name in pairs(state.jobs) do
    stop(name)
  end
end

function M.setup(opts)
  state.html_port = opts and opts.html_port or 8080
  state.md_port = opts and opts.md_port or 6419

  local group = vim.api.nvim_create_augroup("Preview", { clear = true })

  vim.api.nvim_create_user_command("Preview", M.preview, {
    nargs = "?",
  })

  vim.api.nvim_create_user_command("PreviewStop", M.stop, {})

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = M.stop,
  })
end

return M
