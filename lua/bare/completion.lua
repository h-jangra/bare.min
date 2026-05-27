-- Ultra-Performance Completion (Blink-inspired, E565 Fixed)
local api = vim.api
local lsp = vim.lsp

-- UI Configuration
vim.opt.pumheight = 12
vim.opt.shortmess:append("c")
vim.opt.completeopt = { "menuone", "noselect", "noinsert" }
vim.opt.pumborder = "rounded"

local icons = {
  Text = "󰉿", Method = "󰆧", Function = "󰊕", Constructor = "󰒓",
  Field = "󰜢", Variable = "󰀫", Class = "󰠱", Interface = "󰁔",
  Module = "󰕳", Property = "󰜢", Unit = "󰑭", Value = "󰎠",
  Enum = "󰦨", Keyword = "󰌋", Snippet = "󰘦", Color = "󰏘",
  File = "󰈙", Reference = "󰈇", Folder = "󰉋", EnumMember = "󰒻",
  Constant = "󰏿", Struct = "󰙅", Event = "󱐋", Operator = "󰆕",
  TypeParameter = "󰊄",
}

local kind_scores = {
  Snippet = 100, Variable = 90, Field = 90, Property = 90,
  Method = 85, Function = 85, Keyword = 80, Constant = 75,
}

local state = {
  timer = vim.uv.new_timer(),
  request_id = 0,
  cached_items = {},
  is_incomplete = false,
  start_col = -1,
  doc_win = nil,
}

-- Fast & Smart Scoring
local function calculate_score(item, query, query_lower)
  local label = item.label
  local filterText = item.filterText or label
  local text_lower = item._text_lower or filterText:lower()
  item._text_lower = text_lower

  if #query == 0 then return 1 end
  if filterText == query then return 10000 end
  if text_lower == query_lower then return 9000 end

  local start_idx = text_lower:find(query_lower, 1, true)
  if start_idx == 1 then
    local boost = (filterText:sub(1, #query) == query) and 1000 or 0
    return 8000 + boost - #label
  end

  -- Fuzzy Subsequence with Word-Boundary Boosting
  local score, j = 0, 1
  for i = 1, #text_lower do
    local char = text_lower:sub(i, i)
    if char == query_lower:sub(j, j) then
      score = score + (100 / i) + (j * 50)
      -- Word boundary boost (CamelCase, snake_case, etc.)
      if i == 1 or text_lower:sub(i-1, i-1):match("[^%a]") or (filterText:sub(i, i):match("[%A]") and filterText:sub(i, i) ~= char) then
        score = score + 300
      end
      j = j + 1
      if j > #query_lower then break end
    end
  end

  return j > #query_lower and (score - #label) or nil
end

local function close_doc()
  if state.doc_win and api.nvim_win_is_valid(state.doc_win) then
    api.nvim_win_close(state.doc_win, true)
  end
  state.doc_win = nil
end

local function show_doc(item)
  close_doc()
  local lsp_item = item.user_data
  if not (lsp_item and lsp_item.label) then return end

  local function display(docs)
    if not docs or docs == "" or vim.fn.mode() ~= "i" or vim.fn.pumvisible() == 0 then return end
    local pum = vim.fn.pum_getpos()
    if not (pum and pum.row ~= -1) then return end
    state.doc_win, _ = lsp.util.open_floating_preview(
      lsp.util.convert_input_to_markdown_lines(docs), "markdown", 
      { border = "rounded", focus = false, relative = "editor",
        row = pum.row, col = pum.col + pum.width + (pum.scrollbar and 1 or 0),
        anchor = "NW", zindex = 1001 }
    )
  end

  if lsp_item.documentation then
    display(lsp_item.documentation)
  elseif lsp.get_clients({ bufnr = 0 })[1] then
    lsp.get_clients({ bufnr = 0 })[1].request("completionItem/resolve", lsp_item, function(err, result)
      if not err and result and result.documentation then display(result.documentation) end
    end)
  end
end

local function process_and_show(items, start_col, prefix)
  local query_lower = prefix:lower()
  local filtered = {}

  for _, item in ipairs(items) do
    local score = calculate_score(item, prefix, query_lower)
    if score then
      local kind = lsp.protocol.CompletionItemKind[item.kind] or "Text"
      local weight = kind_scores[kind] or 0
      local word = (item.textEdit and item.textEdit.newText) or item.insertText or item.label
      word = word:gsub("%$%b{}", ""):gsub("%$%d+", "")
      
      table.insert(filtered, {
        word = word,
        abbr = (icons[kind] or "  ") .. " " .. item.label,
        kind = kind,
        menu = item.detail or "",
        user_data = item,
        score = score + (weight * 10)
      })
    end
  end

  table.sort(filtered, function(a, b) return a.score > b.score end)
  local result = {}
  for i = 1, math.min(#filtered, 30) do result[i] = filtered[i] end

  if #result > 0 then
    state.start_col = start_col
    vim.fn.complete(start_col + 1, result)
  end
end

local function get_context()
  local cursor = api.nvim_win_get_cursor(0)
  local line = api.nvim_get_current_line()
  local col = cursor[2]
  local start = vim.fn.match(line:sub(1, col), "\\k*$")
  return start, line:sub(start + 1, col)
end

local function trigger_completion()
  local id = state.request_id + 1
  state.request_id = id
  
  local start_col, prefix = get_context()
  local params = lsp.util.make_position_params(0, "utf-8")
  
  lsp.buf_request_all(0, "textDocument/completion", params, function(results)
    if id ~= state.request_id or vim.fn.mode() ~= "i" then return end

    local all_items = {}
    local incomplete = false
    for _, res in pairs(results) do
      if res.result then
        local r = res.result
        vim.list_extend(all_items, r.items or r)
        if r.isIncomplete then incomplete = true end
      end
    end

    state.cached_items = all_items
    state.is_incomplete = incomplete
    state.start_col = start_col
    process_and_show(all_items, start_col, prefix)
  end)
end

local group = api.nvim_create_augroup("BareCompletion", { clear = true })

-- Safe & Fast Event Handling
api.nvim_create_autocmd("InsertCharPre", {
  group = group,
  callback = function() state.timer:stop() end,
})

api.nvim_create_autocmd("TextChangedI", {
  group = group,
  callback = function()
    local start_col, prefix = get_context()
    if #prefix == 0 then 
      state.cached_items = {}
      return 
    end

    -- Immediate Filter (Safe in TextChangedI)
    if #state.cached_items > 0 and start_col == state.start_col and not state.is_incomplete then
      process_and_show(state.cached_items, start_col, prefix)
    end

    -- Background Sync
    state.timer:stop()
    state.timer:start(35, 0, vim.schedule_wrap(function()
      if vim.fn.mode() ~= "i" then return end
      trigger_completion()
    end))
  end,
})

api.nvim_create_autocmd("CompleteChanged", {
  group = group,
  callback = function()
    local item = vim.v.event.completed_item
    if item and item.user_data then show_doc(item) else close_doc() end
  end,
})

api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(args)
    local client = lsp.get_client_by_id(args.data.client_id)
    if client then lsp.completion.enable(false, client.id, args.buf, { autotrigger = false }) end
  end,
})

-- Keymaps
vim.keymap.set("i", "<CR>", function()
  return (vim.fn.pumvisible() == 1 and vim.fn.complete_info().selected ~= -1) and vim.keycode("<C-y>") or vim.keycode("<CR>")
end, { expr = true })

vim.keymap.set("i", "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.schedule(function() vim.snippet.jump(1) end)
    return ""
  end
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-n>") or vim.keycode("<Tab>")
end, { expr = true })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.schedule(function() vim.snippet.jump(-1) end)
    return ""
  end
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-p>") or vim.keycode("<S-Tab>")
end, { expr = true })

vim.keymap.set("i", "<C-Space>", trigger_completion)

return { trigger = trigger_completion }
