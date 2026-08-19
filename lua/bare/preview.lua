local M = {}

function M.setup(opts)
  if type(opts) == "function" then opts = { start = opts } end
  opts = opts or {}
  local job

  local function stop()
    if job then
      job:kill(15)
      job = nil
    end

    if opts.stop then opts.stop() end
  end

  vim.api.nvim_buf_create_user_command(0, "Preview", function(args)
    stop()
    if opts.start then job = opts.start(args) end
  end, { nargs = "?" })

  vim.api.nvim_buf_create_user_command(0, "PreviewStop", stop, {})

  vim.api.nvim_create_autocmd("VimLeavePre", { buffer = 0, callback = stop, })
end

return M
