require("bare.preview").setup(function(opts)
  local port = tonumber(opts.args) or 8080
  local file = vim.api.nvim_buf_get_name(0)

  vim.ui.open(("http://localhost:%d/%s"):format(port, vim.fs.basename(file)))

  return vim.system({ "busybox", "httpd", "-f", "-p", "127.0.0.1:" .. port, },
    { cwd = vim.fs.dirname(file), })
end)
