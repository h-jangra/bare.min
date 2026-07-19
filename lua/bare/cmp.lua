vim.opt.pumheight = 10
vim.opt.shortmess:append("c")
vim.opt.completeopt = { "menuone", "noselect", "noinsert", "fuzzy" }
vim.opt.pumborder = "rounded"

local icons = {
  Text          = "󰉿",
  Method        = "󰆧",
  Function      = "󰊕",
  Constructor   = "",
  Field         = "󰜢",
  Variable      = "󰀫",
  Class         = "󰠱",
  Interface     = "",
  Module        = "󰕳",
  Property      = "󰜢",
  Unit          = "󰑭",
  Value         = "󰎠",
  Enum          = "",
  Keyword       = "󰌋",
  Snippet       = "",
  Color         = "󰏘",
  File          = "󰈙",
  Reference     = "󰈇",
  Folder        = "󰉋",
  EnumMember    = "󰒻",
  Constant      = "󰏿",
  Struct        = "󰙅",
  Event         = "",
  Operator      = "󰆕",
  TypeParameter = "󰊄",
}

-- Setup beautiful blink.cmp-like kind colors
local kind_colors = {
  Function = "#82a1ff",
  Method = "#82a1ff",
  Constructor = "#82a1ff",
  Select = "#82a1ff",
  
  Class = "#ffc777",
  Interface = "#ffc777",
  Struct = "#ffc777",
  Event = "#ffc777",
  
  Variable = "#4fd6be",
  Field = "#4fd6be",
  Property = "#4fd6be",
  
  Keyword = "#fc514e",
  Operator = "#fc514e",
  
  Constant = "#d18616",
  Enum = "#d18616",
  EnumMember = "#d18616",
  
  Snippet = "#c099ff",
  Text = "#a9b1d6",
  File = "#c0caf5",
  Folder = "#7aa2f7",
}

for kind, color in pairs(kind_colors) do
  vim.api.nvim_set_hl(0, "CmpKind" .. kind, { fg = color, default = true })
end
vim.api.nvim_set_hl(0, "CmpKindTextBuf", { fg = "#4fd6be", default = true })
vim.api.nvim_set_hl(0, "CmpKindPath", { fg = "#7aa2f7", default = true })

-- Helper to find path prefixes before cursor
local function get_path_prefix(line_to_cursor)
  return line_to_cursor:match("([%w_%.%~%-/]+/?[%w_%.%-]*)$")
end

-- Helper to scan directories for path completion natively
local function get_path_completions(path_str)
  local results = vim.fn.getcompletion(path_str, "file")
  local items = {}
  for _, path in ipairs(results) do
    local is_dir = path:sub(-1) == "/"
    local name = path:match("([^/]+/?)$") or path
    table.insert(items, {
      word = name,
      kind = is_dir and "Folder" or "File",
      menu = "[Path]",
    })
  end
  return items
end

-- Efficient helper to scan loaded buffers for word completions near the cursor
local function get_buffer_words(prefix)
  if #prefix < 2 then return {} end
  local words, seen = {}, { [prefix] = true }
  local count = 0
  local current_buf = vim.api.nvim_get_current_buf()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local is_current = (buf == current_buf)
      local lines
      if is_current then
        local line_count = vim.api.nvim_buf_line_count(buf)
        local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
        -- Scan 250 lines above and below cursor
        lines = vim.api.nvim_buf_get_lines(buf, math.max(0, cursor_row - 250), math.min(line_count, cursor_row + 250), false)
      else
        local line_count = vim.api.nvim_buf_line_count(buf)
        if line_count <= 500 then -- Skip huge background files to prevent lag
          lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        end
      end

      if lines then
        for _, line in ipairs(lines) do
          for word in line:gmatch("[%w_]+") do
            if #word > 2 and word:sub(1, #prefix):lower() == prefix:lower() and not seen[word] then
              seen[word] = true
              table.insert(words, {
                word = word,
                menu = is_current and "[Buf]" or "[Bufs]",
              })
              count = count + 1
              if count >= 30 then break end
            end
          end
          if count >= 30 then break end
        end
      end
    end
    if count >= 30 then break end
  end
  return words
end

local CompletionItemKind = vim.lsp.protocol.CompletionItemKind

-- Formatting completion items natively
local function format_completion(item)
  local kind = CompletionItemKind[item.kind] or "Unknown"
  local label = item.label
  return {
    abbr = (icons[kind] or "?") .. " " .. label,
    word = item.insertText or item.label,
    menu = item.detail or item.source or "",
    kind = kind,
    kind_hlgroup = "CmpKind" .. kind,
  }
end

-- LSP Attach Hook
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    -- Intercept completion requests to merge buffer & path sources
    if not client._completion_intercepted then
      client._completion_intercepted = true
      local orig_request = client.request
      client.request = function(self, method, params, handler, bufnr)
        if method == "textDocument/completion" then
          local wrapped_handler = function(err, result, ctx, config)
            if not err and result then
              local line = vim.api.nvim_get_current_line()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local line_to_cursor = line:sub(1, col)

              local start_col = vim.fn.match(line_to_cursor, '\\k*$')
              local prefix = line_to_cursor:sub(start_col + 1)

              local seen = {}
              local lsp_buf_items = {}

              -- Deduplicate based on LSP items already present
              if type(result) == "table" then
                local items_list = result.items or result
                if type(items_list) == "table" then
                  for _, item in ipairs(items_list) do
                    local word = item.insertText or item.label
                    seen[word] = true
                  end
                end
              end

              -- Get buffer items
              local buf_items = get_buffer_words(prefix)
              for _, item in ipairs(buf_items) do
                if not seen[item.word] then
                  seen[item.word] = true
                  table.insert(lsp_buf_items, {
                    label = item.word,
                    insertText = item.word,
                    kind = vim.lsp.protocol.CompletionItemKind.Text,
                    detail = item.menu,
                  })
                end
              end

              -- Get path items
              local path_prefix = get_path_prefix(line_to_cursor)
              if path_prefix and path_prefix:find("/") then
                local path_items = get_path_completions(path_prefix)
                for _, item in ipairs(path_items) do
                  table.insert(lsp_buf_items, {
                    label = item.word,
                    insertText = item.word,
                    kind = item.kind == "Folder" and vim.lsp.protocol.CompletionItemKind.Folder or vim.lsp.protocol.CompletionItemKind.File,
                    detail = item.menu,
                  })
                end
              end

              -- Merge into the LSP result
              if type(result) == "table" then
                local items_list = result.items or result
                if type(items_list) == "table" then
                  for _, item in ipairs(lsp_buf_items) do
                    table.insert(items_list, item)
                  end
                end
              end
            end
            handler(err, result, ctx, config)
          end
          return orig_request(self, method, params, wrapped_handler, bufnr)
        end
        return orig_request(self, method, params, handler, bufnr)
      end
    end

    if client:supports_method("textDocument/completion") then
      local chars = {}
      for c in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"):gmatch(".") do
        table.insert(chars, c)
      end
      client.server_capabilities.completionProvider.triggerCharacters = chars

      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
        convert = format_completion,
        ghost_text = true,
      })
    end
  end,
})

-- Autocommands for triggers
local just_completed = false

vim.api.nvim_create_autocmd("CompleteDone", {
  callback = function()
    just_completed = true
    vim.schedule(function()
      just_completed = false
    end)
  end,
})

vim.api.nvim_create_autocmd("TextChangedI", {
  callback = function()
    if just_completed then return end

    local mode = vim.api.nvim_get_mode().mode
    if mode ~= "i" and mode ~= "ic" then return end

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local line_to_cursor = line:sub(1, col)

    local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" })
    if #clients > 0 then
      -- If LSP is active, trigger native completion manually on backspace or typing a word
      if vim.fn.pumvisible() == 0 and line_to_cursor:match("[%w_%.%/]$") then
        local start_col = vim.fn.match(line_to_cursor, '\\k*$')
        local prefix = line_to_cursor:sub(start_col + 1)
        if #prefix >= 2 or line_to_cursor:match("[%/]$") then
          vim.lsp.completion.get()
        end
      end
      return
    end

    -- If no LSP clients, run fallback autocomplete
    if line_to_cursor:match("[%w_%.%/]$") then
      local path_prefix = get_path_prefix(line_to_cursor)
      if path_prefix and path_prefix:find("/") then
        local path_items = get_path_completions(path_prefix)
        if #path_items > 0 then
          local path_start_col = col - #path_prefix:match("[^/]*$")
          local formatted_path_items = {}
          for _, item in ipairs(path_items) do
            local kind = item.kind
            local icon = icons[kind] or "?"
            table.insert(formatted_path_items, {
              word = item.word,
              abbr = icon .. " " .. item.word,
              kind = kind,
              kind_hlgroup = "CmpKindPath",
              menu = item.menu,
              dup = 0,
            })
          end
          vim.fn.complete(path_start_col + 1, formatted_path_items)
          return
        end
      end

      local start_col = vim.fn.match(line_to_cursor, '\\k*$')
      local prefix = line_to_cursor:sub(start_col + 1)
      if #prefix >= 2 then
        local buf_items = get_buffer_words(prefix)
        if #buf_items > 0 then
          local formatted_buf_items = {}
          for _, item in ipairs(buf_items) do
            table.insert(formatted_buf_items, {
              word = item.word,
              abbr = "󰬞 " .. item.word,
              kind = "Text",
              kind_hlgroup = "CmpKindTextBuf",
              menu = item.menu,
              dup = 0,
            })
          end
          vim.fn.complete(start_col + 1, formatted_buf_items)
        end
      end
    else
      if vim.fn.pumvisible() == 1 then
        vim.fn.complete(col + 1, {})
      end
    end
  end,
})

-- Keymaps
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then return vim.keycode("<C-e>") end
  local text_before = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
  if text_before:match("%([^)]*$") then
    vim.lsp.buf.signature_help()
  else
    vim.lsp.completion.get()
  end

  return vim.keycode("")
end, { expr = true, silent = true, desc = "Completion or signature help" })

vim.keymap.set("i", "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.schedule(function() vim.snippet.jump(1) end)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<Tab>"
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.schedule(function() vim.snippet.jump(-1) end)
    return ""
  elseif vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<S-Tab>"
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info().selected ~= -1 then
    return vim.keycode("<C-y>")
  end
  return vim.keycode("<CR>")
end, { expr = true, silent = true })
