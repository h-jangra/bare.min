local M = {}
local ui = require("bare.ui")

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
  javascript = "ts_ls", javascriptreact = "ts_ls", typescript = "ts_ls", typescriptreact = "ts_ls", java = "jdtls",
}

local servers = {
  luals = {
    cmd = { "lua-language-server" },
    ft = { "lua" },
    settings = { Lua = { runtime = { version = "LuaJIT" }, diagnostics = { globals = { "vim" }, disable = { "undefined-global" } }, workspace = { checkThirdParty = false }, telemetry = { enable = false } } },
  },
  pyright = { cmd = { "pyright-langserver", "--stdio" }, ft = { "python" }, settings = { python = { analysis = { autoImportCompletions = true } } } },
  tsls = { cmd = { "typescript-language-server", "--stdio" }, ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" }, settings = { typescript = { suggest = { autoImports = true } }, javascript = { suggest = { autoImports = true } } } },
  rust_analyzer = { cmd = { "rust-analyzer" }, ft = { "rust" }, settings = { ["rust-analyzer"] = { cargo = { allFeatures = true }, checkOnSave = true, procMacro = { enable = true } } } },
  gopls = { cmd = { "gopls" }, ft = { "go", "gomod", "gowork", "gotmpl" }, settings = { gopls = { completeUnimported = true, gofumpt = true, staticcheck = true, analyses = { unusedparams = true } } } },
  clangd = { cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed", "--header-insertion=iwyu" }, ft = { "c", "cpp", "objc", "objcpp" } },
  html = { cmd = { "vscode-html-language-server", "--stdio" }, ft = { "html" } },
  cssls = { cmd = { "vscode-css-language-server", "--stdio" }, ft = { "css", "scss", "less" } },
  jsonls = { cmd = { "vscode-json-language-server", "--stdio" }, ft = { "json" } },
  taplo = { cmd = { "taplo", "lsp", "stdio" }, ft = { "toml" } },
  bash_ls = { cmd = { "bash-language-server", "start" }, ft = { "bash", "sh" } },
  ansiblels = { cmd = { "ansible-language-server", "--stdio" }, ft = { "yaml", "yml" } },
  tinymist = { cmd = { "tinymist", "lsp" }, ft = { "typst" }, settings = { exportPdf = "onType", formatterMode = "typstyle" } },
  jdtls = {
    cmd = { "jdtls" },
    ft = { "java" },
    settings = { java = { saveActions = { organizeImports = true }, completion = { enabled = true, guessMethodArguments = true, lazyResolveTextEdit = true }, signatureHelp = { enabled = false }, configuration = { updateBuildConfiguration = "interactive" } } },
  },
  tailwindcss = { cmd = { "tailwindcss-language-server", "--stdio" }, ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" } },
  qmlls = { cmd = { "qml-language-server" }, ft = { "qml" } },
}

local sym_icons = {
  Class = "󰠱",
  Constructor = "",
  Enum = "",
  Field = "󰜢",
  Function = "󰊕",
  Interface = "",
  Method = "󰆧",
  Module = "󰕳",
  Property = "󰜢",
  Struct = "󰙅",
  Variable = "󰀫",
  Constant = "󰏿",
  String = "󰀬",
  Number = "󰎠",
  Boolean = "◩",
}

local function flatten_symbols(symbols, depth, list)
  list, depth = list or {}, depth or 0
  for _, s in ipairs(symbols) do
    local kind = vim.lsp.protocol.SymbolKind[s.kind] or "Unknown"
    local r = s.range or (s.location and s.location.range) or s.selectionRange
    table.insert(list, {
      name = s.name,
      kind = kind,
      depth = depth,
      lnum = r and (r.start.line + 1) or 1,
      col = r and r.start.character or 0,
    })
    if s.children and #s.children > 0 then flatten_symbols(s.children, depth + 1, list) end
  end
  return list
end

local function open_picker(title, items, on_select)
  if #items == 0 then return vim.notify("No symbols found", vim.log.levels.INFO) end
  local orig_win, lines = vim.api.nvim_get_current_win(), {}
  for _, it in ipairs(items) do
    local icon = sym_icons[it.kind] or "󰈤"
    local indent = it.depth and string.rep("  ", it.depth) or ""
    local extra = it.loc or ("line " .. it.lnum)
    table.insert(lines, string.format("%s%s %-30s  %s", indent, icon, it.name, extra))
  end

  local buf, win = ui.float({
    width = math.min(math.floor(vim.o.columns * 0.85), 80),
    height = math.min(#lines, math.floor(vim.o.lines * 0.6)),
    title = string.format(" %s (%d) ", title, #items),
    enter = true,
  })

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable, vim.bo[buf].buftype, vim.bo[buf].filetype = false, "nofile", "bare_symbols"
  vim.wo[win].cursorline = true

  local function choose(cmd)
    local idx = vim.api.nvim_win_get_cursor(win)[1]
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if vim.api.nvim_win_is_valid(orig_win) then vim.api.nvim_set_current_win(orig_win) end
    if items[idx] then on_select(items[idx], cmd or "edit") end
  end

  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>", function() choose("edit") end, opts)
  vim.keymap.set("n", "v", function() choose("vsplit") end, opts)
  vim.keymap.set("n", "s", function() choose("split") end, opts)
  vim.keymap.set("n", "<C-t>", function() choose("tabedit") end, opts)
  for _, k in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", k, function() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end,
      opts)
  end
end

function M.document_symbols()
  local b = vim.api.nvim_get_current_buf()
  vim.lsp.buf_request(b, "textDocument/documentSymbol", { textDocument = vim.lsp.util.make_text_document_params(b) },
    function(err, res)
      if err or not res or #res == 0 then return vim.notify("No document symbols found", vim.log.levels.INFO) end
      open_picker("Document Symbols", flatten_symbols(res), function(it)
        vim.api.nvim_win_set_cursor(0, { it.lnum, it.col })
        vim.cmd("normal! zz")
      end)
    end)
end

function M.workspace_symbols(query)
  local function fetch(q)
    vim.lsp.buf_request(0, "workspace/symbol", { query = q or "" }, function(err, res)
      if err or not res or #res == 0 then return vim.notify("No workspace symbols found", vim.log.levels.INFO) end
      local items = {}
      for _, s in ipairs(res) do
        local loc = s.location
        local uri = loc and (loc.uri or loc.targetUri)
        local r = loc and (loc.range or loc.targetSelectionRange or loc.targetRange)
        local path = uri and vim.uri_to_fname(uri) or ""
        local lnum = r and (r.start.line + 1) or 1
        table.insert(items, {
          name = s.name,
          kind = vim.lsp.protocol.SymbolKind[s.kind] or "Unknown",
          path = path,
          loc = (path ~= "" and vim.fs.relpath(vim.fn.getcwd(), path) or path) .. ":" .. lnum,
          lnum = lnum,
          col = r and r.start.character or 0,
        })
      end
      open_picker("Workspace Symbols", items, function(it, cmd)
        if it.path ~= "" then vim.cmd((cmd or "edit") .. " " .. vim.fn.fnameescape(it.path)) end
        vim.api.nvim_win_set_cursor(0, { it.lnum, it.col })
        vim.cmd("normal! zz")
      end)
    end)
  end
  if query then fetch(query) else vim.ui.input({ prompt = "Workspace Symbol: " }, function(i) if i then fetch(i) end end) end
end

local function on_attach(_, bufnr)
  if vim.lsp.inlay_hint then vim.lsp.inlay_hint.enable(true, { bufnr = bufnr }) end
  local map = function(m, l, r, desc) vim.keymap.set(m, l, r, { buffer = bufnr, silent = true, desc = desc }) end
  map("n", "gd", function()
    vim.lsp.buf.definition(); vim.schedule(function() vim.cmd("normal! zz") end)
  end, "Definition")
  map("n", "gD", vim.lsp.buf.declaration, "Declaration")
  map("n", "gr", vim.lsp.buf.references, "References")
  map("n", "gi", vim.lsp.buf.implementation, "Implementation")
  map("n", "gy", vim.lsp.buf.type_definition, "Type Definition")
  map("n", "K", vim.lsp.buf.hover, "Hover")
  map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
  map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
  map("n", "<leader>ds", M.document_symbols, "Document Symbols")
  map("n", "<leader>ws", M.workspace_symbols, "Workspace Symbols")
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
  ".git", "pom.xml", "build.gradle", "mvnw", "gradlew", "package.json", "Cargo.toml", "go.mod",
  "pyproject.toml", "setup.py", "requirements.txt", ".venv", ".luarc.json", "stylua.toml",
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
  if not names then return end
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
  vim.api.nvim_create_autocmd("FileType", { group = group, callback = function(a) start_lsp(a.buf) end })
end

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
    vim.lsp.buf.format({ bufnr = b, filter = function(cl) return not ft_formatter[ft] or cl.name == ft_formatter[ft] end })
  end,
})

return M
