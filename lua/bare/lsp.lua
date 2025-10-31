local servers = {
  lua_ls = {
    cmd = { "lua-language-server" },
    ft = { "lua" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },
  pyright = { cmd = { "pyright-langserver", "--stdio" }, ft = { "python" } },
  ts_ls = { cmd = { "typescript-language-server", "--stdio" }, ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" } },
  rust_analyzer = { cmd = { "rust-analyzer" }, ft = { "rust" } },
  gopls = {
    cmd = { "gopls" },
    ft = { "go", "gomod", "gowork", "gotmpl" },
  },
  clangd = { cmd = { "clangd" }, ft = { "c", "cpp", "objc", "objcpp" } },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, ft = { "html" } },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, ft = { "css", "scss", "less" } },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, ft = { "json" } },
  taplo = { cmd = { "taplo", "lsp", "stdio" }, ft = { "toml" } },
  bash_lsp = { cmd = { "bash-language-server", "start" }, ft = { "bashrc", "sh" } },
  tinymist = {
    cmd = { "tinymist", "lsp" },
    ft = { "typst" },
    settings = {
      exportPdf = 'onType',
      formatterMode = 'typstyle',
      preview = { background = { enabled = true, args = { "--data-plane-host=127.0.0.1:23635" } } }
    }
  },
}

local ft_to_server = {}
for name, cfg in pairs(servers) do
  for _, ft in ipairs(cfg.ft) do ft_to_server[ft] = name end
end

local function on_attach(_, bufnr)
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  vim.diagnostic.config({ virtual_text = true })

  local opts = { buffer = bufnr }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<C-l>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "<C-j>", vim.diagnostic.goto_next, opts)
  vim.keymap.set("n", "<C-k>", vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
end

local function get_capabilities()
  local cap = vim.lsp.protocol.make_client_capabilities()
  cap.textDocument.completion.completionItem.snippetSupport = true
  return cap
end

local root_patterns = { '.git', 'package.json', 'Cargo.toml', 'go.mod', 'pyproject.toml', 'setup.py' }
local function find_root(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local files = vim.fs.find(root_patterns, { path = path, upward = true })
  return files[1] and vim.fs.dirname(files[1]) or vim.fn.getcwd()
end

local function start_lsp(bufnr)
  local ft = vim.bo[bufnr].filetype
  local server_name = ft_to_server[ft]
  if not server_name then return end
  local cfg = servers[server_name]
  vim.lsp.start({
    name = server_name,
    cmd = cfg.cmd,
    root_dir = find_root(bufnr),
    settings = cfg.settings,
    on_attach = on_attach,
    capabilities = get_capabilities(),
  })
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if ft_to_server[vim.bo[args.buf].filetype] then start_lsp(args.buf) end
  end,
})
