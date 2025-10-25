vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_mousemaps = 0
vim.g.netrw_keepdir = 0

local function toggle_explorer()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "netrw" then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  vim.cmd("topleft 30Vexplore")
  vim.g.netrw_browse_split = 4
end

vim.keymap.set("n", "<leader>e", toggle_explorer, { desc = "Toggle file explorer (Ex)" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function(event)
    local bufnr = event.buf
    local opts = { buffer = bufnr, silent = true, remap = false }

    vim.schedule(function()
      vim.keymap.set("n", "l", "<CR>", opts)
      vim.keymap.set("n", "h", "-", opts)
      -- Override % to create file in previous window
      vim.keymap.set("n", "%", function()
        local filename = vim.fn.input("New file name: ")
        if filename ~= "" then
          vim.cmd("wincmd p") -- Go to previous window
          vim.cmd("edit " .. vim.fn.fnameescape(filename))
        end
      end, opts)
    end)
  end,
})
