local M = {}
local state = { job_id = nil, port = 8080 }

local function open_browser(path)
  local cmd = vim.fn.has("mac") == 1 and "open"
      or vim.fn.has("unix") == 1 and "xdg-open"
      or "start"
  if cmd then
    vim.fn.jobstart({ cmd, "http://localhost:" .. state.port .. path }, { detach = true })
  end
end

local function create_html(pdf_name)
  local html = string.format([[
<!DOCTYPE html>
<html>
<head>
  <style>
    body { margin: 0; padding: 0; }
    embed { width: 100vw; height: 100vh; }
  </style>
</head>
<body>
  <embed src="%s?t=%d" type="application/pdf">
  <script>
    setInterval(() => fetch('%s?t=' + Date.now()).then(r => {
      if (r.headers.get('last-modified') > window.lastMod) {
        window.lastMod = r.headers.get('last-modified')
        document.querySelector('embed').src = '%s?t=' + Date.now()
      }
    }), 500)
    fetch('%s?t=' + Date.now()).then(r => window.lastMod = r.headers.get('last-modified'))
  </script>
</body>
</html>
]], pdf_name, os.time(), pdf_name, pdf_name, pdf_name)

  local html_path = vim.fn.getcwd() .. "/.typst-preview.html"
  local file = io.open(html_path, "w")
  if file then
    file:write(html)
    file:close()
  end
  return html_path
end

local function cleanup()
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end
  -- Delete HTML file on cleanup
  local html_path = vim.fn.getcwd() .. "/.typst-preview.html"
  os.remove(html_path)
end

function M.stop()
  cleanup()
end

function M.start(port)
  M.stop()
  state.port = port or state.port

  state.job_id = vim.fn.jobstart(
    { "python3", "-m", "http.server", tostring(state.port) },
    { cwd = vim.fn.getcwd() }
  )

  if state.job_id > 0 then
    vim.notify("[LiveServer] Started at http://localhost:" .. state.port)
    vim.defer_fn(function() open_browser("/") end, 300)
  end
end

function M.start_typst(port)
  local file = vim.fn.expand("%:p")
  if not file:match("%.typ$") or vim.fn.executable("typst") ~= 1 then
    vim.notify("[LiveServer] Open a .typ file or install typst", vim.log.levels.ERROR)
    return
  end

  M.stop()
  state.port = port or state.port

  local pdf_name = vim.fn.fnamemodify(file, ":t:r") .. ".pdf"
  local result = vim.fn.system({ "typst", "compile", file, pdf_name })
  if vim.v.shell_error ~= 0 then
    vim.notify("[LiveServer] Compile failed: " .. result, vim.log.levels.ERROR)
    return
  end

  create_html(pdf_name)

  state.job_id = vim.fn.jobstart(
    { "python3", "-m", "http.server", tostring(state.port) },
    { cwd = vim.fn.getcwd() }
  )

  if state.job_id > 0 then
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = file,
      callback = function()
        vim.fn.system({ "typst", "compile", file, pdf_name })
      end
    })

    vim.notify("[LiveServer] Typst preview started")
    vim.defer_fn(function() open_browser("/.typst-preview.html") end, 500)
  end
end

function M.setup(opts)
  state.port = opts and opts.port or 8080

  vim.api.nvim_create_user_command("LiveServerStart", function(cmd)
    M.start(cmd.args ~= "" and tonumber(cmd.args) or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("LiveServerStartTypst", function(cmd)
    M.start_typst(cmd.args ~= "" and tonumber(cmd.args) or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("LiveServerStop", M.stop, {})
  vim.api.nvim_create_autocmd("VimLeavePre", { callback = cleanup })
end

return M
