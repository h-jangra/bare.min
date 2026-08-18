local active = false

require("bare.preview").setup({
  start = function()
    local file = vim.api.nvim_buf_get_name(0)
    local client = vim.lsp.get_clients({ bufnr = 0, name = "tinymist", })[1]

    if client then
      active = true
      client:exec_cmd({ command = "tinymist.doStartBrowsingPreview", arguments = { { file } }, },
        {}, function(_, result)
          if result then
            vim.ui.open("http://" .. result.staticServerAddr)
          end
        end)
    else
      return vim.system({ "tinymist", "preview", file, "--open" })
    end
  end,

  stop = function()
    if not active then return end
    active = false

    local client = vim.lsp.get_clients({ bufnr = 0, name = "tinymist", })[1]

    if client then
      pcall(client.exec_cmd, client, {
        command = "tinymist.doKillPreview",
        arguments = { "default_preview" },
      })
    end
  end,
})
