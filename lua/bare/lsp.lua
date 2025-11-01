local servers = {
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },
  pyright = { cmd = { "pyright-langserver", "--stdio" }, filetypes = { "python" } },
  ts_ls = { cmd = { "typescript-language-server", "--stdio" }, filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" } },
  rust_analyzer = { cmd = { "rust-analyzer" }, filetypes = { "rust" } },
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
  },
  clangd = { cmd = { "clangd" }, filetypes = { "c", "cpp", "objc", "objcpp" } },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, filetypes = { "html" } },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, filetypes = { "css", "scss", "less" } },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, filetypes = { "json" } },
  taplo = { cmd = { "taplo", "lsp", "stdio" }, filetypes = { "toml" } },
  bash_lsp = { cmd = { "bash-language-server", "start" }, filetypes = { "bashrc", "sh" } },
  tinymist = {
    cmd = { "tinymist", "lsp" },
    filetypes = { "typst" },
    settings = {
      exportPdf = 'onType',
      formatterMode = 'typstyle',
      preview = { background = { enabled = true, args = { "--data-plane-host=127.0.0.1:23635" } } }
    }
  },
  mdls = {
    cmd = { "markdown-oxide" },
    filetypes = { "md", "markdown" }
  }
}

local ft_to_server = {}
for name, cfg in pairs(servers) do
  for _, ft in ipairs(cfg.filetypes) do ft_to_server[ft] = name end
end

local function on_attach(_, bufnr)
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  vim.diagnostic.config({ virtual_text = true })

  local opts = { buffer = bufnr }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "<C-h>", function() vim.diagnostic.jump({ count = -1 }) end, opts)
  vim.keymap.set("n", "<C-j>", function() vim.diagnostic.jump({ count = 1 }) end, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
end

local function get_capabilities()
  local cap = vim.lsp.protocol.make_client_capabilities()

  -- Enhanced completion capabilities
  cap.textDocument.completion.completionItem = {
    snippetSupport = true,
    commitCharactersSupport = true,
    deprecatedSupport = true,
    preselectSupport = true,
    tagSupport = { valueSet = { 1 } }, -- CompletionItemTag
    insertReplaceSupport = true,
    resolveSupport = {
      properties = { "documentation", "detail", "additionalTextEdits" },
    },
  }

  -- Additional capabilities
  cap.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
  cap.textDocument.semanticTokens = vim.empty_dict()

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

-- Auto organize imports on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local diagnostics = vim.diagnostic.get(0)
    vim.lsp.buf.code_action({
      context = {
        diagnostics = diagnostics,
        only = { "source.organizeImports" }
      },
      apply = true
    })
  end,
})
-- Auto-format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    local clients = vim.lsp.get_clients({ bufnr = args.buf })
    if #clients > 0 then
      vim.lsp.buf.format({ async = false, timeout_ms = 1000 })
    end
  end,
})

vim.diagnostic.config({
  virtual_text = { current_line = true },
})
