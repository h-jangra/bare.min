-- Requires Busybox, Tinymist, and markdown_py

local M, state = {}, {
  html_job = nil,
  html_port = 8080,
  typst_jobs = {},
  md_job = nil,
  md_port = 6419,
  md_file = nil,
  md_html = nil,
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

local function generate_md_html(file, html_file)
  vim.fn.jobstart({ "markdown_py", file }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data then return end
      local html = table.concat({
        [[
        <!DOCTYPE html><html><head><meta charset="utf-8"><style>
        body { max-width: 800px; margin: auto; font-family: sans-serif; line-height: 1.6; padding: 2rem; color: #24292e; background: #ffffff; }
        h1,h2,h3,h4,h5,h6 { border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; margin-top: 1.5em; margin-bottom: 0.5em; font-weight: 600; color: #0366d6; }
        p { margin: 0.8em 0; }
        a { color: #0366d6; text-decoration: none; }
        a:hover { text-decoration: underline; }
        pre { background: #f6f8fa; padding: 1rem; overflow-x: auto; border-radius: 6px; border: 1px solid #d1d5da; }
        code { background: #f6f8fa; padding: 0.2rem 0.4rem; border-radius: 3px; font-family: monospace; }
        pre code { padding: 0; background: none; }
        ul, ol { margin: 0.8em 0 0.8em 2em; }
        blockquote { border-left: 4px solid #dfe2e5; padding-left: 1em; color: #6a737d; margin: 0.8em 0; background: #f6f8fa; }
        table { border-collapse: collapse; margin: 1em 0; width: 100%; }
        th, td { border: 1px solid #dfe2e5; padding: 0.5em 1em; }
        th { background: #f6f8fa; }
        img { max-width: 100%; }
        </style></head><body>
        ]],
        table.concat(data, "\n"),
        [[</body></html>]]
      }, "\n")

      local f = io.open(html_file, "w")
      if f then
        f:write(html); f:close()
      end
    end
  })
end

function M.start_md(port)
  local file = vim.fn.expand("%:p")
  if not file:match("%.md$") then
    vim.notify("Not a markdown file", vim.log.levels.WARN)
    return
  end
  if not check_exec("markdown_py") or not check_exec("busybox") then return end

  M.stop_md()
  state.md_port = port or state.md_port
  state.md_file = file

  -- Generate HTML next to Markdown with same filename
  state.md_html = vim.fn.fnamemodify(file, ":p:r") .. ".html"
  generate_md_html(file, state.md_html)

  -- Auto-update on save
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = state.md_file,
    callback = function() generate_md_html(state.md_file, state.md_html) end,
  })

  -- Serve the Markdown folder
  local serve_dir = vim.fn.fnamemodify(file, ":h")
  state.md_job = vim.fn.jobstart({ "busybox", "httpd", "-f", "-p", tostring(state.md_port) }, { cwd = serve_dir })

  open_browser("http://localhost:" .. state.md_port .. "/" .. vim.fn.fnamemodify(state.md_html, ":t"))
end

function M.stop_md()
  if state.md_job then
    vim.fn.jobstop(state.md_job)
    state.md_job = nil
  end

  if state.md_html and vim.fn.filereadable(state.md_html) == 1 then
    os.remove(state.md_html)
    state.md_html = nil
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
