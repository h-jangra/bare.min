-- Press <C-k> to expand snippets or jump between placeholders.
--
-- Usage in your init.lua:
--   local snippets = require("snippet")
--   snippets.setup()
--
--   -- Add snippets using simple key = value syntax
--   snippets.add("lua", {
--     fn = "function ${1:name}($2)\n\t$0\nend",
--     req = "local $1 = require('$2')",
--     ["if"] = "if $1 then\n\t$0\nend",
--     ["for"] = "for ${1:i} = ${2:1}, ${3:10} do\n\t$0\nend",
--     local_fn = "local function ${1:name}($2)\n\t$0\nend",
--   })
--
--   snippets.add("python", {
--     def = "def ${1:function}($2):\n\t$0",
--     ["class"] = "class ${1:Name}:\n\tdef __init__(self$2):\n\t\t$0",
--   })
--
-- Snippet Syntax:
--   $1, $2, $3, ... - Tab stops (press <C-k> to jump between them)
--   $0              - Final cursor position
--   ${1:default}    - Placeholder with default text
--   \n              - New line
--   \t              - Tab character
--
-- Keymaps:
--   <C-k>     - Expand snippet or jump to next placeholder
--   <S-Tab>   - Jump to previous placeholder
-- ============================================================================

local M = {}

-- Storage for all snippets, organized by filetype
M.snippets = {}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

--- Get the word before the cursor (used for snippet expansion)
--- @return string word The word before cursor
--- @return number row The row number (0-indexed)
--- @return number col The column where the word starts
local function get_word_before_cursor()
  local row, col = (table.unpack or unpack)(vim.api.nvim_win_get_cursor(0))

  -- Nothing before cursor if we're at column 0
  if col == 0 then
    return "", row - 1, 0
  end

  local line = vim.api.nvim_get_current_line()
  local start_col = col

  -- Walk backwards to find the start of the word
  while start_col > 0 do
    local ch = line:sub(start_col, start_col)
    if ch:match("[%w_]") then
      start_col = start_col - 1
    else
      break
    end
  end

  local word = line:sub(start_col + 1, col)
  return word, row - 1, start_col
end

--- Delete a range of text in the buffer
--- @param bufnr number Buffer number
--- @param row number Row number (0-indexed)
--- @param start_col number Starting column
--- @param end_col number Ending column
local function delete_range(bufnr, row, start_col, end_col)
  vim.api.nvim_buf_set_text(bufnr, row, start_col, row, end_col, { "" })
end

--- Try to expand a snippet based on the word before cursor
--- @param filetype string The current buffer's filetype
--- @return boolean success True if a snippet was expanded
local function try_expand_snippet(filetype)
  local word, row, start_col = get_word_before_cursor()

  if word == "" then
    return false
  end

  local snippets = M.snippets[filetype]
  if not snippets then
    return false
  end

  -- Look for a matching snippet trigger
  for _, snippet in ipairs(snippets) do
    if snippet.trigger == word then
      -- Delete the trigger word
      delete_range(0, row, start_col, start_col + #word)

      -- Expand the snippet
      vim.snippet.expand(snippet.body)
      return true
    end
  end

  return false
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Add snippets for a specific filetype
--- @param filetype string The filetype (e.g., "lua", "python", "javascript")
--- @param snippet_list table List of snippets (can be shorthand or full format)
---
--- Shorthand format (recommended):
---   snippets.add("lua", {
---     fn = "function $1($2)\n\t$0\nend",
---     req = "local $1 = require('$2')",
---     ["if"] = "if $1 then\n\t$0\nend",  -- Use ["key"] for Lua keywords
---   })
---
--- Full format (for advanced usage):
---   snippets.add("lua", {
---     { trigger = "fn", body = "function $1($2)\n\t$0\nend" },
---   })
function M.add(filetype, snippet_list)
  M.snippets[filetype] = M.snippets[filetype] or {}

  -- Convert shorthand format to full format if needed
  local processed = {}
  for k, v in pairs(snippet_list) do
    if type(k) == "number" then
      -- Already in full format: { trigger = "...", body = "..." }
      table.insert(processed, v)
    else
      -- Shorthand format: key = trigger, value = body
      table.insert(processed, { trigger = k, body = v })
    end
  end

  vim.list_extend(M.snippets[filetype], processed)
end

--- Set up the snippet expansion keymap (<C-k>)
--- This keymap will:
---   1. Jump to next placeholder if inside a snippet
---   2. Try to expand a snippet if the word before cursor matches a trigger
---   3. Fall back to <Tab> behavior if neither applies
function M.setup_keymap()
  vim.keymap.set({ "i", "s" }, "<C-k>", function()
    -- First, check if we're already in a snippet and can jump forward
    if vim.snippet.active({ direction = 1 }) then
      vim.schedule(function()
        vim.snippet.jump(1)
      end)
      return
    end

    -- Try to expand a snippet
    if try_expand_snippet(vim.bo.filetype) then
      return
    end

    -- Fallback: behave like <Tab>
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Tab>", true, false, true),
      "i",
      true
    )
  end, {
    desc = "Expand snippet or jump to next placeholder",
    silent = true,
    noremap = true
  })

  -- Optional: Add backward jump with Shift+Tab
  vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
    if vim.snippet.active({ direction = -1 }) then
      vim.schedule(function()
        vim.snippet.jump(-1)
      end)
    end
  end, {
    desc = "Jump to previous snippet placeholder",
    silent = true,
    noremap = true
  })
end

--- Complete setup: set up keymaps
--- Call this in your init.lua to get started
function M.setup()
  M.setup_keymap()
end

return M
