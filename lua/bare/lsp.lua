-- Enhanced capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = { 'documentation', 'detail', 'additionalTextEdits' }
}
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true
}

-- Improved on_attach function
local function on_attach(_, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }

  -- Navigation
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)

  -- Code actions
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)

  -- Diagnostics
  vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, opts)
  vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, opts)
end

-- Configure diagnostics
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
})

-- Server configurations with filetypes and commands
local servers = {
  -- Lua
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  },
  -- Python
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
  },
  -- TypeScript/JavaScript
  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
  -- Rust
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
  },

  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
  },

  clangd = {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
  },
  -- HTML
  html = {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html" },
    root_dir = vim.fs.dirname(vim.fs.find({ "index.html", ".git" }, { upward = true })[1]),
  },

  -- CSS
  cssls = {
    cmd = { "vscode-css-language-server", "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_dir = vim.fs.dirname(vim.fs.find({ "package.json", ".git" }, { upward = true })[1]),
  },

  -- JSON
  jsonls = {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json" },
    root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),
    settings = {
      json = {
        validate = { enable = true },
      },
    },
  },

  -- TOML
  taplo = {
    cmd = { "taplo", "lsp" },
    filetypes = { "toml" },
    root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.toml", ".git" }, { upward = true })[1]),
  },

  -- Typst
  tinymist = {
    cmd = { "tinymist", "lsp" },
    filetypes = { "typst" },
    root_dir = function()
      return vim.fs.dirname(vim.fs.find({ '.git' }, { upward = true })[1])
    end,
    settings = {
      exportPdf = 'onType',
      formatterMode = 'typstyle',
    },
    init_options = {
      formatterMode = 'typstyle',
    },
  },
}

-- Enhanced diagnostic signs
-- local signs = { Error = '✘', Warn = '▲', Hint = '⚑', Info = '»' }
-- for type, icon in pairs(signs) do
--   local hl = "DiagnosticSign" .. type
--   vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
-- end

-- Autocommand to start LSP servers
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(args)
    local bufnr = args.buf
    local ft = vim.bo[bufnr].filetype

    for server_name, config in pairs(servers) do
      if vim.tbl_contains(config.filetypes, ft) then
        local clients = vim.lsp.get_clients({ bufnr = bufnr, name = server_name })
        if #clients > 0 then
          return
        end

        vim.lsp.start({
          name = server_name,
          cmd = config.cmd,
          root_dir = vim.fn.getcwd(),
          settings = config.settings or {},
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end
    end
  end,
})
