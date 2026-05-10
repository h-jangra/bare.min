local servers = {
  lua_ls = { cmd = { "lua-language-server" }, ft = { "lua" }, settings = { Lua = { runtime = { version = "LuaJIT" }, diagnostics = { globals = { "vim" } }, workspace = { library = vim.api.nvim_get_runtime_file("", true) }, telemetry = { enable = false } } } },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    ft = { "python" },
    settings = {
      python = {
        analysis = {
          autoImportCompletions = true,
        },
      },
    },
  },
  ts_ls = { cmd = { "typescript-language-server", "--stdio" }, ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" } },
  rust_analyzer = { cmd = { "rust-analyzer" }, ft = { "rust" } },
  gopls = {
    cmd = { "gopls" },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    settings = {
      gopls = {
        completeUnimported = true,
        analyses = {
          unusedparams = true,
        },
        gofumpt = true,
        staticcheck = true,
      },
    },
  },
  clangd = { cmd = { "clangd" }, ft = { "c", "cpp", "objc", "objcpp" } },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, ft = { "html" } },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, ft = { "css", "scss", "less" } },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, ft = { "json" } },
  taplo = { cmd = { "taplo", "lsp", "stdio" }, ft = { "toml" } },
  bash_lsp = { cmd = { "bash-language-server", "start" }, ft = { "bash", "sh" } },
  tinymist = { cmd = { "tinymist", "lsp" }, ft = { "typst" }, settings = { exportPdf = 'onType', formatterMode = 'typstyle' } },
  jdtls = {
    cmd = { "jdtls" },
    ft = { "java" },
    settings = {
      java = {
        saveActions = {
          organizeImports = true,
        },
        completion = {
          favoriteStaticMembers = {
            "org.junit.Assert.*",
            "org.junit.jupiter.api.Assertions.*",
            "org.mockito.Mockito.*",
          },
          importOrder = {
            "java",
            "javax",
            "com",
            "org",
          },
        },
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
      },
    },
  },
  tailwindcss = {
    cmd = { "tailwindcss-language-server", "--stdio" },
    ft = {
      "html",
      "css",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "svelte",
    },
  },
}

local ft_to_servers = {}
for name, cfg in pairs(servers) do
  for _, ft in ipairs(cfg.ft) do
    ft_to_servers[ft] = ft_to_servers[ft] or {}
    table.insert(ft_to_servers[ft], name)
  end
end

local function on_attach(client, bufnr)
  if client:supports_method("textDocument/documentHighlight") then
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end

  local opts = { buffer = bufnr }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set({ 'n', 'i' }, '<C-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "<C-j>", function()
    vim.diagnostic.jump({
      count = -1,
      on_jump = function()
        vim.diagnostic.open_float()
      end,
    })
  end, opts)

  vim.keymap.set("n", "<C-l>", function()
    vim.diagnostic.jump({
      count = 1,
      on_jump = function()
        vim.diagnostic.open_float()
      end,
    })
  end, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
end

local function get_cap()
  local cap = vim.lsp.protocol.make_client_capabilities()
  cap.textDocument.completion.completionItem = { snippetSupport = true, commitCharactersSupport = true, deprecatedSupport = true, preselectSupport = true, insertReplaceSupport = true }
  cap.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  }
  return cap
end

local capabilities = get_cap()

local function find_root(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local files = vim.fs.find({ '.git', 'package.json', 'Cargo.toml', 'go.mod', 'pyproject.toml', 'setup.py' },
    { path = vim.fs.dirname(path), upward = true })
  return files[1] and vim.fs.dirname(files[1]) or vim.fn.getcwd()
end

local function start_lsp(bufnr)
  local ft = vim.bo[bufnr].filetype
  local server_names = ft_to_servers[ft]
  if not server_names then return end

  for _, server_name in ipairs(server_names) do
    local cfg = servers[server_name]

    local already_attached = false

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if client.name == server_name then
        already_attached = true
        break
      end
    end

    if not already_attached then
      vim.lsp.start({
        name = server_name,
        cmd = cfg.cmd,
        root_dir = find_root(bufnr),
        settings = cfg.settings,
        on_attach = on_attach,
        capabilities = capabilities,
      })
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if ft_to_servers[vim.bo[args.buf].filetype] then start_lsp(args.buf) end
  end
})

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    local bufnr = args.buf
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if not clients[1] then return end

    local view = vim.fn.winsaveview()
    local ft = vim.bo[bufnr].filetype
    local import_ft = {
      javascript = true,
      javascriptreact = true,
      typescript = true,
      typescriptreact = true,
      go = true,
      java = true,
    }
    if import_ft[ft] then
      for _, client in ipairs(clients) do
        if client:supports_method("textDocument/codeAction") then
          local result = vim.lsp.buf_request_sync(
            bufnr,
            "textDocument/codeAction",
            {
              textDocument = vim.lsp.util.make_text_document_params(bufnr),
              context = {
                only = {
                  "source.organizeImports",
                },
              },
            },
            1000
          )

          if result then
            for _, res in pairs(result) do
              for _, action in pairs(res.result or {}) do
                if action.edit then
                  vim.lsp.util.apply_workspace_edit(
                    action.edit,
                    client.offset_encoding
                  )
                end

                if action.command then
                  client:exec_cmd(action.command, {
                    bufnr = bufnr,
                  })
                end
              end
            end
          end
        end
      end
    end

    local formatters = vim.lsp.get_clients({
      bufnr = bufnr,
      method = "textDocument/formatting",
    })
    if formatters[1] then
      vim.lsp.buf.format({ async = false, timeout_ms = 1000 })
    else
      vim.cmd("normal! mzgg=G`z")
    end

    vim.fn.winrestview(view)
  end,
})
