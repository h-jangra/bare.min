local M = {}

M.servers = {
  lua = {
    name = "lua_ls",
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_dir = vim.fs.root(0, {
      ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml",
      "stylua.toml", "selene.toml", "selene.yml", ".git"
    }),
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },

  python = {
    name = "pyright",
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_dir = vim.fs.root(0, { "pyproject.toml", "setup.py", ".git" }),
  },

  javascript = {
    name = "ts_ls",
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_dir = vim.fs.root(0, { "package.json", "tsconfig.json", ".git" }),
  },

  go = {
    name = "gopls",
    cmd = { "gopls" },
    filetypes = { "go" },
    root_dir = vim.fs.root(0, { "go.mod", ".git" }),
  },

  rust = {
    name = "rust_analyzer",
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_dir = vim.fs.root(0, { "Cargo.toml", ".git" }),
  },

  typst = {
    name = "tinymist",
    cmd = { "tinymist" },
    filetypes = { "typst" },
  }
}


-- Check if a command exists in PATH
local function executable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Start LSP safely
function M.start_lsp(config)
  local cmd_name = config.cmd[1]
  if not executable(cmd_name) then
    vim.notify(
      string.format("LSP '%s' not found! Run: %s", config.name, config.install_cmd or "install manually"),
      vim.log.levels.WARN
    )
    if config.install_cmd then
      vim.fn.system(config.install_cmd)
      vim.notify(string.format("Tried installing '%s'. Restart Neovim if successful.", config.name))
    end
    return
  end
  vim.lsp.start(config)
end

-- Setup autocmd for all servers
function M.setup(user_servers)
  -- Merge default servers with user-provided servers
  if user_servers then
    for k, v in pairs(user_servers) do
      M.servers[k] = v
    end
  end

  -- Create autocmds
  for ft, config in pairs(M.servers) do
    vim.api.nvim_create_autocmd("FileType", {
      pattern = ft,
      callback = function()
        M.start_lsp(config)
      end,
    })
  end
end

return M
