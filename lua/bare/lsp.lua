local function on_attach(client, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }

  -- Navigation
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  -- vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)

  -- Code actions
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)

  -- Diagnostics
  vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)

  -- print("LSP atached: " .. client.name)
end

-- Configure diagnostics display
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- LSP server configurations
local servers = {
  -- Lua
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_dir = vim.fs.dirname(vim.fs.find({ ".luarc.json", ".luarc.jsonc", ".git" }, { upward = true })[1]),
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
    root_dir = vim.fs.dirname(vim.fs.find({ "setup.py", "pyproject.toml", ".git" }, { upward = true })[1]),
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "workspace",
        },
      },
    },
  },

  -- TypeScript/JavaScript
  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_dir = vim.fs.dirname(vim.fs.find({ "package.json", "tsconfig.json", ".git" }, { upward = true })[1]),
  },

  -- Rust
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.toml", ".git" }, { upward = true })[1]),
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        checkOnSave = { command = "clippy" },
      },
    },
  },

  -- Go
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = vim.fs.dirname(vim.fs.find({ "go.mod", ".git" }, { upward = true })[1]),
    settings = {
      gopls = {
        analyses = { unusedparams = true },
        staticcheck = true,
      },
    },
  },

  -- C/C++
  clangd = {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_dir = vim.fs.dirname(vim.fs.find({ "compile_commands.json", ".git" }, { upward = true })[1]),
  },

  -- Typst
  tinymist = {
    cmd = { "tinymist", "lsp" },
    filetypes = { "typst" },
    root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),
    settings = {
      exportPdf = "onSave",
      formatterMode = "typstyle",
    },
    init_options = {
      formatterMode = "typstyle",
    },
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
}

-- Autocommand to start LSP servers
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(args)
    local bufnr = args.buf
    local ft = vim.bo[bufnr].filetype

    -- Find matching server for this filetype
    for server_name, config in pairs(servers) do
      if vim.tbl_contains(config.filetypes, ft) then
        -- Check if this buffer already has this LSP client
        local clients = vim.lsp.get_clients({ bufnr = bufnr, name = server_name })
        if #clients > 0 then
          return
        end

        -- Determine root directory
        local root_dir = config.root_dir or vim.fn.getcwd()
        if not root_dir then
          return
        end

        -- Start the LSP client
        vim.lsp.start({
          name = server_name,
          cmd = config.cmd,
          root_dir = root_dir,
          settings = config.settings or {},
          init_options = config.init_options or {},
          on_attach = on_attach,
          capabilities = vim.lsp.protocol.make_client_capabilities(),
        })
      end
    end
  end,
})

-- Diagnostic signs
local signs = { Error = "✘", Warn = "▲", Hint = "⚑", Info = "»" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
