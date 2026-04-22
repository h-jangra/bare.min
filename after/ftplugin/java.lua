vim.keymap.set("n", "<leader>r", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  local name = vim.fn.expand("%:t:r")

  vim.cmd("Floaterm javac " .. file .. " && java -cp " .. dir .. " " .. name)
end)
