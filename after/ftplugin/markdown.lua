require("bare.preview").setup(function(opts)
  local port = tonumber(opts.args) or 6419
  local file = vim.api.nvim_buf_get_name(0)

  vim.defer_fn(function()
    vim.ui.open("http://localhost:" .. port)
  end, 700)

  return vim.system({ "grip", file, tostring(port) })
end)
