local M = {}
local state = { job_id = nil, port = 8080 }

local function open_browser(path)
  local cmd = vim.fn.has("mac") == 1 and "open"
      or vim.fn.has("unix") == 1 and "xdg-open"
      or "start"
  vim.fn.jobstart({ cmd, "http://localhost:" .. state.port .. path }, { detach = true })
end

local function create_typst_html(pdf)
  local html = string.format([[
<!DOCTYPE html>
<html>
<head>
<style>
body { margin: 0; padding: 0; background: #525252; }
iframe { border: none; width: 100vw; height: 100vh; }
</style>
</head>
<body>
<iframe src="%s#toolbar=0"></iframe>
</body>
</html>
]], pdf)

  local file = vim.fn.getcwd() .. "/.typst-preview.html"
  local f = io.open(file, "w")
  if f then
    f:write(html); f:close()
  end
end

function M.start(port)
  M.stop()
  state.port = port or state.port

  if vim.fn.executable("livereload") ~= 1 then
    vim.notify("[LiveServer] Please install Python package 'livereload'", vim.log.levels.ERROR)
    return
  end

  state.job_id = vim.fn.jobstart({ "livereload", ".", "--port", tostring(state.port), "--wait", "0" },
    { cwd = vim.fn.getcwd() })
  vim.notify("[LiveServer] Started at http://localhost:" .. state.port)
  vim.defer_fn(function() open_browser("/") end, 300)
end

function M.start_typst(port)
  local file = vim.fn.expand("%:p")
  if not file:match("%.typ$") or vim.fn.executable("typst") ~= 1 then
    vim.notify("[LiveServer] Open a .typ file or install typst", vim.log.levels.ERROR)
    return
  end

  M.stop()
  state.port = port or state.port
  local pdf = vim.fn.fnamemodify(file, ":t:r") .. ".pdf"

  vim.fn.system({ "typst", "compile", file, pdf })
  if vim.v.shell_error ~= 0 then
    vim.notify("[LiveServer] Typst compile failed", vim.log.levels.ERROR)
    return
  end

  create_typst_html(pdf)

  if vim.fn.executable("livereload") ~= 1 then
    vim.notify("[LiveServer] Please install Python package 'livereload'", vim.log.levels.ERROR)
    return
  end

  state.job_id = vim.fn.jobstart({ "livereload", ".", "--port", tostring(state.port), "--wait", "0" },
    { cwd = vim.fn.getcwd() })

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = file,
    callback = function()
      vim.fn.system({ "typst", "compile", file, pdf })
    end
  })

  vim.notify("[LiveServer] Typst preview started")
  vim.defer_fn(function() open_browser("/.typst-preview.html") end, 500)
end

function M.stop()
  if state.job_id then
    vim.fn.jobstop(state.job_id); state.job_id = nil
  end
  os.remove(vim.fn.getcwd() .. "/.typst-preview.html")
end

function M.setup(opts)
  state.port = opts and opts.port or 8080
  vim.api.nvim_create_user_command("LiveServerStart",
    function(cmd) M.start(cmd.args ~= "" and tonumber(cmd.args) or nil) end, { nargs = "?" })
  vim.api.nvim_create_user_command("LiveServerStartTypst",
    function(cmd) M.start_typst(cmd.args ~= "" and tonumber(cmd.args) or nil) end, { nargs = "?" })
  vim.api.nvim_create_user_command("LiveServerStop", M.stop, {})
  vim.api.nvim_create_autocmd("VimLeavePre", { callback = M.stop })
end

return M
