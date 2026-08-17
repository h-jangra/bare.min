local M = {}

local ft_formatter = {
  html = "html",
  css = "cssls",
  scss = "cssls",
  less = "cssls",
  javascript = "ts_ls",
  javascriptreact = "ts_ls",
  typescript = "ts_ls",
  typescriptreact = "ts_ls",
}

local organise_imports_client = {
  javascript = "ts_ls",
  javascriptreact = "ts_ls",
  typescript = "ts_ls",
  typescriptreact = "ts_ls",
  java = "jdtls",
}

local servers = {
  luals = {
    cmd = { "lua-language-server" },
    ft = { "lua" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" }, disable = { "undefined-global" } },
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    ft = { "python" },
    settings = { python = { analysis = { autoImportCompletions = true } } },
  },
  tsls = {
    cmd = { "typescript-language-server", "--stdio" },
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    settings = {
      typescript = { suggest = { autoImports = true } },
      javascript = { suggest = { autoImports = true } },
    },
  },
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    ft = { "rust" },
    settings = {
      ["rust-analyzer"] = { cargo = { allFeatures = true }, checkOnSave = true, procMacro = { enable = true } },
    },
  },
  gopls = {
    cmd = { "gopls" },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    settings = {
      gopls = {
        completeUnimported = true,
        gofumpt = true,
        staticcheck = true,
        analyses = { unusedparams = true },
      },
    },
  },
  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--completion-style=detailed",
      "--header-insertion=iwyu",
    },
    ft = { "c", "cpp", "objc", "objcpp" },
  },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, ft = { "html" } },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, ft = { "css", "scss", "less" } },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, ft = { "json" } },
  taplo = { cmd = { "taplo", "lsp", "stdio" }, ft = { "toml" } },
  bash_ls = { cmd = { "bash-language-server", "start" }, ft = { "bash", "sh" } },
  ansiblels = { cmd = { "ansible-language-server", "--stdio" }, ft = { "yaml", "yml" } },
  tinymist = { cmd = { "tinymist", "lsp" }, ft = { "typst" }, },
  jdtls = {
    cmd = { "jdtls" },
    ft = { "java" },
    settings = {
      java = {
        saveActions = { organizeImports = true },
        completion = { enabled = true, guessMethodArguments = true, lazyResolveTextEdit = true },
        signatureHelp = { enabled = false },
        configuration = { updateBuildConfiguration = "interactive" },
      },
    },
  },
  tailwindcss = {
    cmd = { "tailwindcss-language-server", "--stdio" },
    ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
  },
  qmlls = { cmd = { "qml-language-server" }, ft = { "qml" } },
  nimls = { cmd = { "nimlangserver" }, ft = { "nim", "nimble" } },
}

local function on_attach(_, bufnr)
  if vim.lsp.inlay_hint then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
  local map = function(m, l, r, desc)
    vim.keymap.set(m, l, r, { buffer = bufnr, silent = true, desc = desc })
  end
  map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem = {
  snippetSupport = true,
  commitCharactersSupport = true,
  deprecatedSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  insertTextModeSupport = { valueSet = { 1, 2 } },
  resolveSupport = { properties = { "documentation", "detail", "additionalTextEdits" } },
}

local root_markers = {
  ".git", "pom.xml", "build.gradle", "mvnw", "gradlew", "package.json", "Cargo.toml",
  "go.mod", "pyproject.toml", "setup.py", "requirements.txt", ".venv", ".luarc.json", "stylua.toml",
}

local ft_to_servers = {}
for name, cfg in pairs(servers) do
  for _, ft in ipairs(cfg.ft) do
    ft_to_servers[ft] = ft_to_servers[ft] or {}
    table.insert(ft_to_servers[ft], name)
  end
end

local function start_lsp(bufnr)
  local names = ft_to_servers[vim.bo[bufnr].filetype]
  if not names then
    return
  end
  for _, name in ipairs(names) do
    local cfg = servers[name]
    if vim.fn.executable(cfg.cmd[1]) == 1 then
      vim.lsp.start({
        name = name,
        cmd = cfg.cmd,
        root_dir = vim.fs.root(bufnr, root_markers),
        settings = cfg.settings,
        on_attach = on_attach,
        capabilities = capabilities,
        flags = { allow_incremental_sync = true },
      }, { bufnr = bufnr })
    end
  end
end

local group = vim.api.nvim_create_augroup("LspConfig", { clear = true })

if vim.lsp.config then
  for name, cfg in pairs(servers) do
    if vim.fn.executable(cfg.cmd[1]) == 1 then
      vim.lsp.config[name] = {
        cmd = cfg.cmd,
        filetypes = cfg.ft,
        root_markers = root_markers,
        settings = cfg.settings,
        capabilities = capabilities,
        on_attach = on_attach,
      }
      vim.lsp.enable(name)
    end
  end
else
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(a)
      start_lsp(a.buf)
    end,
  })
end

local function organize_imports(buf, name)
  local client = name and vim.lsp.get_clients({ bufnr = buf, name = name })[1]
  if not client then return end

  local results = vim.lsp.buf_request_sync(buf, "textDocument/codeAction", {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    context = { only = { "source.organizeImports" } },
  }, 1000)

  for _, result in pairs(results or {}) do
    for _, action in ipairs(result.result or {}) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      end
      if action.command then
        client:exec_cmd(action.command, { bufnr = buf })
      end
    end
  end
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(args)
    local buf = args.buf
    local ft = vim.bo[buf].filetype

    organize_imports(buf, organise_imports_client[ft])
    vim.lsp.buf.format({
      bufnr = b,
      filter = function(cl)
        return not ft_formatter[ft] or cl.name == ft_formatter[ft]
      end,
    })
  end,
})

function M.document_symbols()
  vim.lsp.buf_request(0, "textDocument/documentSymbol", {
    textDocument = vim.lsp.util.make_text_document_params(),
  }, function(_, result)
    if not result or #result == 0 then
      return vim.notify("No document symbols", vim.log.levels.INFO)
    end

    vim.lsp.buf.document_symbol()
  end)
end

function M.workspace_symbols()
  vim.ui.input({ prompt = "Symbol: " }, function(query)
    if not query or query == "" then
      return
    end

    vim.lsp.buf_request(0, "workspace/symbol", { query = query }, function(_, result)
      if not result or #result == 0 then
        return vim.notify("No workspace symbols", vim.log.levels.INFO)
      end

      vim.lsp.buf.workspace_symbol(query)
    end)
  end)
end

return M
