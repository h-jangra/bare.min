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
    * { margin: 0; padding: 0; }
    .container { position: relative; width: 100vw; height: 100vh; overflow: hidden; }
    iframe { position: absolute; width: 100%%; height: 100%%; border: none; opacity: 0; transition: opacity 0.2s; }
    iframe.active { opacity: 1; z-index: 2; }
  </style>
</head>
<body>
  <div class="container">
    <iframe id="a" src="%s?t=%d#toolbar=0" class="active"></iframe>
    <iframe id="b"></iframe>
  </div>
  <script>
    const pdf = '%s';
    let active = a, hidden = b, last = null;

    function swap() {
      active.classList.remove('active');
      hidden.classList.add('active');
      [active, hidden] = [hidden, active];
    }

    fetch(pdf).then(r => last = r.headers.get('last-modified'));

    setInterval(() => {
      fetch(pdf, { method: 'HEAD' }).then(r => {
        const mod = r.headers.get('last-modified');
        if (mod && mod !== last) {
          last = mod;
          hidden.src = pdf + '?t=' + Date.now() + '#toolbar=0';
          hidden.onload = () => setTimeout(swap, 50);
        }
      }).catch(() => {});
    }, 800);
  </script>
</body>
</html>
]], pdf_name, os.time(), pdf_name)

  local file = io.open(vim.fn.getcwd() .. "/.typst-preview.html", "w")
  if file then
    file:write(html)
    file:close()
  end
end

local function cleanup()
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end
  os.remove(vim.fn.getcwd() .. "/.typst-preview.html")
end

function M.stop()
  cleanup()
end

function M.start(port)
  M.stop()
  state.port = port or state.port
  state.job_id = vim.fn.jobstart({ "python3", "-m", "http.server", tostring(state.port) }, { cwd = vim.fn.getcwd() })
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
  local pdf = vim.fn.fnamemodify(file, ":t:r") .. ".pdf"

  if vim.v.shell_error ~= 0 then
    vim.notify("[LiveServer] Compile failed", vim.log.levels.ERROR)
    return
  end

  vim.fn.system({ "typst", "compile", file, pdf })
  create_html(pdf)

  state.job_id = vim.fn.jobstart({ "python3", "-m", "http.server", tostring(state.port) }, { cwd = vim.fn.getcwd() })

  if state.job_id > 0 then
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = file,
      callback = function() vim.fn.system({ "typst", "compile", file, pdf }) end
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
