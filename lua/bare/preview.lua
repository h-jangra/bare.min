local M = {}

local state = {
  jobs = {},
  html_port = 8080,
  md_port = 6419,
}

local function stop(name)
  local proc = state.jobs[name]
  if not proc then return end
  proc:kill(15)
  state.jobs[name] = nil
end

local function start_html(port)
  if vim.fn.executable("busybox") == 0 then return end

  stop("html")

  local file = vim.api.nvim_buf_get_name(0)

  state.html_port = port or state.html_port
  state.jobs.html = vim.system({
    "busybox", "httpd", "-f", "-p", "127.0.0.1:" .. state.html_port,
  }, {
    cwd = vim.fs.dirname(file),
  })

  vim.ui.open("http://localhost:" .. state.html_port .. "/" .. vim.fs.basename(file))
end

local function start_markdown(port)
  if vim.fn.executable("grip") == 0 then return end

  stop("markdown")

  local file = vim.api.nvim_buf_get_name(0)

  state.md_port = port or state.md_port
  state.jobs.markdown = vim.system({ "grip", file, tostring(state.md_port) })

  vim.defer_fn(function()
    vim.ui.open("http://localhost:" .. state.md_port)
  end, 700)
end

local function start_typst()
  if vim.fn.executable("tinymist") == 0 then return end

  local file = vim.api.nvim_buf_get_name(0)
  stop(file)

  state.jobs[file] = vim.system({
    "tinymist", "preview", file, "--open",
  }, {
    cwd = vim.fs.dirname(file),
  })
end

local preview = {
  html = start_html,
  markdown = start_markdown,
  typst = start_typst,
}

function M.preview(opts)
  local fn = preview[vim.bo.filetype]
  if fn then
    fn(tonumber(opts.args))
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

  vim.api.nvim_create_user_command("Preview", M.preview, { nargs = "?" })
  vim.api.nvim_create_user_command("PreviewStop", M.stop, {})
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop, })
end

return M
