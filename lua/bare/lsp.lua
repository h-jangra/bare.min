local ft_formatter = {
  html            = "html",
  css             = "cssls",
  scss            = "cssls",
  less            = "cssls",
  javascript      = "ts_ls",
  javascriptreact = "ts_ls",
  typescript      = "ts_ls",
  typescriptreact = "ts_ls",
}

local organise_imports_client = {
  javascript      = "ts_ls",
  javascriptreact = "ts_ls",
  typescript      = "ts_ls",
  typescriptreact = "ts_ls",
  java            = "jdtls",
}

local servers = {
  lua_ls        = {
    cmd = { "lua-language-server" },
    ft = { "lua" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        telemetry = { enable = false },
      }
    },
  },
  pyright       = {
    cmd = { "pyright-langserver", "--stdio" },
    ft = { "python" },
    settings = { python = { analysis = { autoImportCompletions = true } } },
  },
  ts_ls         = {
    cmd = { "typescript-language-server", "--stdio" },
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
  rust_analyzer = { cmd = { "rust-analyzer" }, ft = { "rust" } },
  gopls         = {
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
  clangd        = { cmd = { "clangd" }, ft = { "c", "cpp", "objc", "objcpp" } },
  html          = { cmd = { "vscode-html-language-server", "--stdio" }, ft = { "html" } },
  cssls         = { cmd = { "vscode-css-language-server", "--stdio" }, ft = { "css", "scss", "less" } },
  jsonls        = { cmd = { "vscode-json-language-server", "--stdio" }, ft = { "json" } },
  taplo         = { cmd = { "taplo", "lsp", "stdio" }, ft = { "toml" } },
  bash_lsp      = { cmd = { "bash-language-server", "start" }, ft = { "bash", "sh" } },
  tinymist      = {
    cmd = { "tinymist", "lsp" },
    ft = { "typst" },
    settings = { exportPdf = "onType", formatterMode = "typstyle" },
  },
  jdtls         = {
    cmd = { "jdtls" },
    ft = { "java" },

    settings = {
      java = {
        saveActions = { organizeImports = true, },

        completion = {
          enabled = true,
          guessMethodArguments = true,
          lazyResolveTextEdit = true,

          favoriteStaticMembers = { "org.junit.Assert.*", "org.junit.jupiter.api.Assertions.*", "org.mockito.Mockito.*", },
          filteredTypes = { "com.sun.*", "sun.*", "jdk.*", "org.graalvm.*", "io.micrometer.shaded.*", },
          importOrder = { "java", "javax", "jakarta", "com", "org", },
        },

        signatureHelp = { enabled = false, },
        referencesCodeLens = { enabled = false, },
        implementationsCodeLens = { enabled = false, },
        configuration = { updateBuildConfiguration = "interactive", },
        sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999, }, },
      },
    },
  },
  tailwindcss   = {
    cmd = { "tailwindcss-language-server", "--stdio" },
    ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
  },
}

-- Filetype - server name mapping
local ft_to_servers = {}
for name, cfg in pairs(servers) do
  for _, ft in ipairs(cfg.ft) do
    ft_to_servers[ft] = ft_to_servers[ft] or {}
    table.insert(ft_to_servers[ft], name)
  end
end

local function on_attach(_, bufnr)
  local function diag_jump(count)
    return function()
      vim.diagnostic.jump({ count = count, float = true })
      vim.cmd("normal! zz")
    end
  end

  local map = function(modes, lhs, rhs) vim.keymap.set(modes, lhs, rhs, { buffer = bufnr }) end
  map("n", "K", vim.lsp.buf.hover)
  map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help)
  map("n", "gd", function() 
    vim.lsp.buf.definition()
    vim.schedule(function() vim.cmd("normal! zz") end)
  end)
  map("n", "<C-j>", diag_jump(-1))
  map("n", "<C-l>", diag_jump(1))
  map("n", "<leader>ca", vim.lsp.buf.code_action)
end

local function get_capabilities()
  local cap = vim.lsp.protocol.make_client_capabilities()
  cap.textDocument.completion.completionItem = {
    snippetSupport = true,
    commitCharactersSupport = true,
    deprecatedSupport = true,
    preselectSupport = true,
    insertReplaceSupport = true,
  }
  cap.textDocument.completion.completionItem.insertTextModeSupport = {
    valueSet = { 1, 2 },
  }
  cap.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" },
  }
  return cap
end

local capabilities = get_capabilities()

local function start_lsp(bufnr)
  local names = ft_to_servers[vim.bo[bufnr].filetype]
  if not names then return end

  for _, name in ipairs(names) do
    local cfg = servers[name]
    if vim.fn.executable(cfg.cmd[1]) == 1 then
      vim.lsp.start({
        name         = name,
        cmd          = cfg.cmd,
        root_dir     = vim.fs.root(bufnr, { ".git", "pom.xml", "build.gradle", "mvnw", "gradlew", "package.json", "Cargo.toml", "go.mod" }),
        settings     = cfg.settings,
        on_attach    = on_attach,
        capabilities = capabilities,
        flags        = { allow_incremental_sync = true },
      }, { bufnr = bufnr })
    end
  end
end

local lsp_augroup = vim.api.nvim_create_augroup("LspConfig", { clear = true })

-- Auto-start LSP on FileType
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_augroup,
  callback = function(args)
    if ft_to_servers[vim.bo[args.buf].filetype] then
      start_lsp(args.buf)
    end
  end,
})

-- Format (+ organise imports) on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = lsp_augroup,
  callback = function(args)
    local bufnr   = args.buf
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if not clients[1] then return end

    local ft                 = vim.bo[bufnr].filetype
    local view               = vim.fn.winsaveview()

    -- Organise imports: only the designated client for this filetype
    local import_client_name = organise_imports_client[ft]
    if import_client_name then
      for _, client in ipairs(clients) do
        if client.name == import_client_name then
          -- jdtls exposes a dedicated command; other servers use codeAction
          if client.name == "jdtls" then
            client:exec_cmd({
              command = "java.edit.organizeImports",
              arguments = {
                vim.uri_from_bufnr(bufnr),
              },
            }, { bufnr = bufnr })
          elseif client:supports_method("textDocument/codeAction") then
            local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", {
              textDocument = vim.lsp.util.make_text_document_params(bufnr),
              context = {
                only = { "source.organizeImports" },
                diagnostics = {},
              },
            }, 1000)
            for _, res in pairs(result or {}) do
              for _, action in pairs(res.result or {}) do
                if action.edit then
                  vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
                end
                if action.command then
                  client:exec_cmd(action.command, { bufnr = bufnr })
                end
              end
            end
          end
          break
        end
      end
    end

    -- Format: prefer the pinned formatter for this ft, else first capable client
    local pinned = ft_formatter[ft]
    vim.lsp.buf.format({
      async      = false,
      timeout_ms = 1000,
      bufnr      = bufnr,
      filter     = pinned
          and function(c) return c.name == pinned end
          or function(c) return c:supports_method("textDocument/formatting") end,
    })

    vim.fn.winrestview(view)
  end,
})
