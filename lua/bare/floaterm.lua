-- Usage:
--   <leader>t to toggle floating terminal
--   <leader>T to toggle split terminal
--   <leader>r to run active file (floating runner)
--   :Floaterm to open floating terminal
--   :Run / :Run <cmd>

local M = {}

M.config = {
  width = 0.9,
  height = 0.9,
  border = "rounded",
}

M.state = {
  win = nil,
  buf = nil,
  cmd = nil,
}

local normal_term = { win = nil, buf = nil }

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

local ui = require("bare.ui")

local function create_window(title)
  local buf, win = ui.float({
    width = math.floor(vim.o.columns * M.config.width),
    height = math.floor(vim.o.lines * M.config.height),
    border = M.config.border,
    title = title or " Terminal ",
  })

  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.api.nvim_win_set_buf(win, M.state.buf)
    vim.api.nvim_buf_delete(buf, { force = true })
  else
    M.state.buf = buf
  end

  vim.cmd.startinsert()
  vim.api.nvim_buf_set_keymap(M.state.buf, "t", "<Esc>", "<C-\\><C-n>:Floaterm<CR>", {
    noremap = true,
    silent = true,
  })

  M.state.win = win
end

function M.open(cmd, title)
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
    M.state.win = nil
    return
  end

  if cmd and cmd ~= "" then
    M.state.buf = vim.api.nvim_create_buf(false, true)
    create_window(title or (" Run: " .. cmd .. " "))
    M.state.cmd = cmd
    vim.fn.termopen(cmd)
    return
  end

  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    create_window(title or " Terminal ")
    return
  end

  M.state.buf = vim.api.nvim_create_buf(false, true)
  create_window(title or " Terminal ")
  M.state.cmd = vim.o.shell
  vim.fn.termopen(M.state.cmd)
end

function M.toggle_split()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" and vim.api.nvim_win_get_config(win).relative == "" then
      vim.api.nvim_win_close(win, true)
      normal_term.win = nil
      return
    end
  end

  vim.cmd("botright 12split")
  normal_term.win = vim.api.nvim_get_current_win()

  if normal_term.buf and vim.api.nvim_buf_is_valid(normal_term.buf) then
    vim.api.nvim_win_set_buf(normal_term.win, normal_term.buf)
  else
    vim.cmd("terminal")
    normal_term.buf = vim.api.nvim_get_current_buf()
  end

  vim.cmd.startinsert()
end

local runners = {
  python = "python3 %s",
  javascript = "node %s",
  typescript = "bun %s",
  lua = "nvim --headless -c 'luafile %s' -c 'q'",
  go = "go run %s",
  rust = "cargo run",
  c = "gcc %s -o /tmp/a.out && /tmp/a.out",
  cpp = "g++ -std=c++20 %s -o /tmp/a.out && /tmp/a.out",
  sh = "bash %s",
  bash = "bash %s",
  zsh = "zsh %s",
  typst = "typst compile %s",
  html = "xdg-open %s",
}

function M.run(custom_cmd)
  if custom_cmd and custom_cmd ~= "" then
    M.open(custom_cmd, " Run: " .. custom_cmd .. " ")
    return
  end

  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No file to run", vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then vim.cmd("write") end

  local cmd_template = runners[ft]
  if not cmd_template then
    if vim.fn.executable(file) == 1 then
      cmd_template = "%s"
    else
      vim.ui.input({ prompt = "Run command: ", default = ft .. " " .. vim.fn.fnameescape(file) }, function(input)
        if input and input ~= "" then M.open(input) end
      end)
      return
    end
  end

  local cmd = string.format(cmd_template, vim.fn.fnameescape(file))
  M.open(cmd, " Run: " .. vim.fn.fnamemodify(file, ":t") .. " ")
end

vim.api.nvim_create_user_command("Floaterm", function(opts)
  M.open(opts.args or "")
end, { nargs = "?", desc = "Open floating terminal" })

vim.api.nvim_create_user_command("Run", function(opts)
  M.run(opts.args or "")
end, { nargs = "?", desc = "Run code for active file or specified command" })

vim.keymap.set("n", "<leader>t", M.open, { desc = "Toggle floating terminal" })
vim.keymap.set("n", "<leader>T", M.toggle_split, { desc = "Toggle split terminal" })
vim.keymap.set("n", "<leader>r", function() M.run() end, { desc = "Run code for active file" })

return M
