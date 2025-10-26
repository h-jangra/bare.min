local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<Esc>", "<cmd>nohlsearch<cr>", opts)
map("n", "<C-s>", "<cmd>w<cr>", opts)
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>o", "<cmd>update<cr>:source %<cr>", { desc = "Save & Reload" })
map("n", "<A-q>", "<cmd>q<cr>", opts)
map("n", "<leader>a", "ggVG", { desc = "Select All" })

-- Clipboard
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to Clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank Line to Clipboard" })
map("n", "<C-c>", "<cmd>%y+<cr>", { desc = "Copy File to Clipboard" })

-- Buffers
map("n", "<Tab>", "<cmd>bnext<cr>", opts)
map("n", "<S-Tab>", "<cmd>bprevious<cr>", opts)
map("n", "<leader>x", "<cmd>bdelete!<cr>", { desc = "Close Buffer" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)

-- Move lines
map("n", "<A-j>", ":m .+1<cr>==", opts)
map("n", "<A-k>", ":m .-2<cr>==", opts)
map("i", "<A-j>", "<Esc>:m .+1<cr>==gi", opts)
map("i", "<A-k>", "<Esc>:m .-2<cr>==gi", opts)
map("v", "<A-j>", ":m '>+1<cr>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<cr>gv=gv", opts)

-- Delete/change (don't yank)
map("n", "x", '"_x', opts)
map("v", "x", '"_x', opts)
map("v", "c", '"_c', opts)
map("x", "c", '"_c', opts)

-- Find and replace
map("n", "<leader>fr", function()
  local find = vim.fn.input("Find: ")
  if find == "" then
    return
  end
  local replace = vim.fn.input("Replace: ")
  vim.cmd("%s/" .. find .. "/" .. replace .. "/gc")
end, { desc = "Find & Replace" })

-- Copy diagnostics to clipboard
map("n", "<leader>cd", function()
  local diags = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
  if #diags == 0 then
    vim.notify("No diagnostics on this line", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg(
    "+",
    table.concat(
      vim.tbl_map(function(d)
        return d.message
      end, diags),
      "\n"
    )
  )
  vim.notify("Diagnostics copied to clipboard")
end, { desc = "Copy Line Diagnostics" })

-- LSP
map("n", "<leader>lf", function()
  vim.lsp.buf.format({ async = true, timeout_ms = 2000 })
end, { desc = "LSP Format" })
map("n", "<leader>li", "gg=G``", { desc = "Indent Entire File" })

-- Config
map("n", "<leader>fc", function()
  vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Edit Config" })

map("i", "jk", "<Esc>", opts)
map("i", "kj", "<Esc>", opts)
map("i", "<C-s>", "<Esc><cmd>w<cr>", opts)
