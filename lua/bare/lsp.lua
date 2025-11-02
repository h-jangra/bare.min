local servers = {
  lua_ls = {
    cmd = { "lua-language-server" },
    ft = { "lua" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
        telemetry = { enable = false }
      }
    }
  },
  pyright = { cmd = { "pyright-langserver", "--stdio" }, ft = { "python" } },
  ts_ls =
  {
    cmd = { "typescript-language-server", "--stdio" },
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" }
  },
  rust_analyzer = { cmd = { "rust-analyzer" }, ft = { "rust" } },
  gopls = { cmd = { "gopls" }, ft = { "go", "gomod", "gowork", "gotmpl" } },
  clangd = { cmd = { "clangd" }, ft = { "c", "cpp", "objc", "objcpp" } },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, ft = { "html" } },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, ft = { "css", "scss", "less" } },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, ft = { "json" } },
  taplo = { cmd = { "taplo", "lsp", "stdio" }, ft = { "toml" } },
  bash_lsp = { cmd = { "bash-language-server", "start" }, ft = { "bashrc", "sh" } },
  tinymist =
  {
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
  local opts = { buffer = bufnr }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<C-l>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "<C-j>", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
  vim.keymap.set("n", "<C-k>", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
end

local function get_capabilities()
  local cap = vim.lsp.protocol.make_client_capabilities()
  cap.textDocument.completion.completionItem =
  {
    snippetSupport = true,
    commitCharactersSupport = true,
    deprecatedSupport = true,
    preselectSupport = true,
    insertReplaceSupport = true
  }
  cap.textDocument.codeAction = {
    codeActionLiteralSupport = {
      codeActionKind = {
        valueSet = {
          "",
          "quickfix",
          "refactor",
          "refactor.extract",
          "refactor.inline",
          "refactor.rewrite",
          "source",
          "source.organizeImports",
          "source.fixAll"
        }
      }
    }
  }
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
    capabilities = get_capabilities()
  })
end

vim.api.nvim_create_autocmd("FileType",
  { callback = function(args) if ft_to_server[vim.bo[args.buf].filetype] then start_lsp(args.buf) end end })

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    local bufnr = args.buf
    local view = vim.fn.winsaveview()

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if client:supports_method("textDocument/codeAction") then
        local params =
        {
          textDocument = vim.lsp.util.make_text_document_params(bufnr),
          range =
          {
            start = { line = 0, character = 0 },
            ["end"] =
            { line = vim.api.nvim_buf_line_count(bufnr), character = 0 }
          },
          context = { only = { "source.organizeImports" } }
        }
        local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
        if result then
          for _, res in pairs(result) do
            for _, action in pairs(res.result or {}) do
              if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding) end
            end
          end
        end
      end
    end

    if vim.lsp.get_clients({ bufnr = bufnr })[1] and vim.lsp.get_clients({ bufnr = bufnr })[1]:supports_method("textDocument/formatting") then
      vim.lsp.buf.format({ async = false, timeout_ms = 1000 })
    else
      vim.cmd("silent normal! gg=G")
    end

    vim.fn.winrestview(view)
  end,
})
