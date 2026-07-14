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
  lua_ls = {
    cmd = { "lua-language-server" },
    ft = { "lua" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      }
    },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    ft = { "python" },
    settings = { python = { analysis = { autoImportCompletions = true } } },
  },
  ts_ls = {
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
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        checkOnSave = true,
        procMacro = { enable = true },
      },
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
      }
    },
  },
  clangd = {
    cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed", "--header-insertion=iwyu" },
    ft = { "c", "cpp", "objc", "objcpp" }
  },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, ft = { "html" } },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, ft = { "css", "scss", "less" } },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, ft = { "json" } },
  taplo = { cmd = { "taplo", "lsp", "stdio" }, ft = { "toml" } },
  bash_lsp = { cmd = { "bash-language-server", "start" }, ft = { "bash", "sh" } },
  yaml_lsp = { cmd = { "yaml-language-server", "--stdio" }, ft = { "yaml", "yml" } },
  tinymist = {
    cmd = { "tinymist", "lsp" },
    ft = { "typst" },
    settings = { exportPdf = "onType", formatterMode = "typstyle" },
  },
  jdtls = {
    cmd = { "jdtls" },
    ft = { "java" },
    settings = {
      java = {
        saveActions = { organizeImports = true },
        completion = {
          enabled = true,
          guessMethodArguments = true,
          lazyResolveTextEdit = true,
          favoriteStaticMembers = { "org.junit.Assert.*", "org.junit.jupiter.api.Assertions.*", "org.mockito.Mockito.*" },
          filteredTypes = { "com.sun.*", "sun.*", "jdk.*", "org.graalvm.*", "io.micrometer.shaded.*" },
          importOrder = { "java", "javax", "jakarta", "com", "org" },
        },
        signatureHelp = { enabled = false },
        referencesCodeLens = { enabled = false },
        implementationsCodeLens = { enabled = false },
        configuration = { updateBuildConfiguration = "interactive" },
        sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
      },
    },
  },
  tailwindcss = {
    cmd = { "tailwindcss-language-server", "--stdio" },
    ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
  },
}

local ft_to_servers = {}
for name, cfg in pairs(servers) do
  for _, ft in ipairs(cfg.ft) do
    ft_to_servers[ft] = ft_to_servers[ft] or {}
    table.insert(ft_to_servers[ft], name)
  end
end

local function on_attach(_, bufnr)
  if vim.lsp.inlay_hint then vim.lsp.inlay_hint.enable(true, { bufnr = bufnr }) end
  local map = function(m, l, r) vim.keymap.set(m, l, r, { buffer = bufnr }) end
  map("n", "K", vim.lsp.buf.hover)
  map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help)
  map("n", "gd", function()
    vim.lsp.buf.definition(); vim.schedule(function() vim.cmd("normal! zz") end)
  end)
  map("n", "<C-j>", function()
    vim.diagnostic.jump({ count = -1, float = true }); vim.cmd("normal! zz")
  end)
  map("n", "<C-l>", function()
    vim.diagnostic.jump({ count = 1, float = true }); vim.cmd("normal! zz")
  end)
  map("n", "<leader>ca", vim.lsp.buf.code_action)
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

local function start_lsp(bufnr)
  local ft = vim.bo[bufnr].filetype
  local names = ft_to_servers[ft]
  if not names then return end

  for _, name in ipairs(names) do
    local cfg = servers[name]
    if vim.fn.executable(cfg.cmd[1]) == 1 then
      vim.lsp.start({
        name = name,
        cmd = cfg.cmd,
        root_dir = vim.fs.root(bufnr, {
          ".git", "pom.xml", "build.gradle", "mvnw", "gradlew", "package.json", "Cargo.toml", "go.mod",
          "pyproject.toml", "setup.py", "requirements.txt", ".venv", ".luarc.json", "stylua.toml",
          "pnpm-workspace.yaml", "turbo.json",
        }),
        settings = cfg.settings,
        on_attach = on_attach,
        capabilities = capabilities,
        flags = { allow_incremental_sync = true },
      }, { bufnr = bufnr })
    end
  end
end

local group = vim.api.nvim_create_augroup("LspConfig", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args) start_lsp(args.buf) end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(args)
    local ft, b = vim.bo[args.buf].filetype, args.buf
    local n = organise_imports_client[ft]
    local c = n and vim.lsp.get_clients({ bufnr = b, name = n })[1]
    if c then
      if n == "jdtls" then
        c:exec_cmd({ command = "java.edit.organizeImports", arguments = { vim.uri_from_bufnr(b) } }, { bufnr = b })
      else
        local r = vim.lsp.buf_request_sync(b, "textDocument/codeAction", {
          textDocument = vim.lsp.util.make_text_document_params(b),
          context = { only = { "source.organizeImports" } },
        }, 1000)
        for _, res in pairs(r or {}) do
          for _, a in pairs(res.result or {}) do
            if a.edit then vim.lsp.util.apply_workspace_edit(a.edit, c.offset_encoding) end
            if a.command then c:exec_cmd(a.command, { bufnr = b }) end
          end
        end
      end
    end
    vim.lsp.buf.format({
      bufnr = b,
      filter = function(client) return not ft_formatter[ft] or client.name == ft_formatter[ft] end
    })
  end,
})
