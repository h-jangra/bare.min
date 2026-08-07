local M = {}

local ns_id = vim.api.nvim_create_namespace("bare_present")

M.config = {
  mode = "reveal",
  dim_hl_group = "PresentDim",
  auto_center = true,
  notify = true,
  cursor = "hor20",
}

local state = { enabled = false, current_block = 0, blocks = {}, orig_guicursor = nil }

local function parse_blocks(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local blocks, in_block, block_start = {}, false, 1

  for i, line in ipairs(lines) do
    local is_blank = not line:find("%S")
    if not is_blank and not in_block then
      in_block, block_start = true, i
    elseif is_blank and in_block then
      in_block = false
      blocks[#blocks + 1] = { start_line = block_start, end_line = i - 1 }
    end
  end

  if in_block then
    blocks[#blocks + 1] = { start_line = block_start, end_line = #lines }
  end

  if #blocks <= 1 and #lines > 5 then
    blocks = {}
    local current_start = 1
    for i = 2, #lines do
      local line = lines[i]
      if line:match("^%s*end%s*$")
          or line:match("^local function")
          or line:match("^function")
          or line:match("^class")
          or line:match("^def ")
          or line:match("^#")
          or line:match("^%-%-") then
        blocks[#blocks + 1] = { start_line = current_start, end_line = i }
        current_start = i + 1
      end
    end
    if current_start <= #lines then
      blocks[#blocks + 1] = { start_line = current_start, end_line = #lines }
    end
  end

  if #blocks == 0 and #lines > 0 then
    blocks[1] = { start_line = 1, end_line = #lines }
  end

  return blocks
end

local function render_presentation()
  if not state.enabled or #state.blocks == 0 then return end
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then return end

  local cfg = M.config
  local hl = vim.api.nvim_get_hl(0, { name = "NonText", link = false })
  vim.api.nvim_set_hl(0, cfg.dim_hl_group, {
    fg = hl.fg and string.format("#%06x", hl.fg) or "#6c7086",
    italic = hl.italic or false,
  })

  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local mode, cur = cfg.mode, state.current_block

  for i, block in ipairs(state.blocks) do
    if (mode == "reveal" and i > cur) or (mode == "spotlight" and i ~= cur) then
      for line_idx = block.start_line, block.end_line do
        local line_str = lines[line_idx] or ""
        if #line_str > 0 then
          vim.api.nvim_buf_set_extmark(buf, ns_id, line_idx - 1, 0, {
            end_row = line_idx - 1,
            end_col = #line_str,
            hl_group = cfg.dim_hl_group,
            hl_mode = "combine",
            priority = 10000,
          })
        end
      end
    end
  end

  if cfg.auto_center and cur > 0 and cur <= #state.blocks then
    pcall(vim.api.nvim_win_set_cursor, 0, { state.blocks[cur].start_line, 0 })
    pcall(vim.cmd, "normal! zz")
  end
end

function M.start()
  if not state.enabled then
    state.orig_guicursor = vim.o.guicursor
    if M.config.cursor then
      vim.o.guicursor = "n-v-c-sm:" .. M.config.cursor .. ",i-ci-ve:ver25"
    end
  end
  state.blocks = parse_blocks()
  state.current_block = 0
  state.enabled = true
  render_presentation()
end

function M.stop()
  local buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  end
  if state.orig_guicursor then
    vim.o.guicursor = state.orig_guicursor
    state.orig_guicursor = nil
  end
  state.enabled = false
end

function M.toggle()
  if state.enabled then M.stop() else M.start() end
end

local function step_block(delta)
  if not state.enabled then M.start() end
  if #state.blocks == 0 then return end
  state.current_block = math.max(0, math.min(#state.blocks, state.current_block + delta))
  render_presentation()
end

function M.next_block() step_block(1) end

function M.prev_block() step_block(-1) end

function M.reset_colors()
  if not state.enabled then M.start() end
  state.current_block = #state.blocks
  render_presentation()
  if M.config.notify then
    vim.notify("Presentation Mode: All colors revealed!", vim.log.levels.INFO, { title = "Presentation Mode" })
  end
end

function M.toggle_mode()
  M.config.mode = M.config.mode == "reveal" and "spotlight" or "reveal"
  if state.enabled then
    render_presentation()
  else
    local mode_name = M.config.mode == "reveal" and "Progressive Reveal" or "Spotlight Focus"
    vim.notify("Presentation Mode set to: " .. mode_name, vim.log.levels.INFO, { title = "Presentation Mode" })
  end
end

function M.setup(opts)
  if opts then M.config = vim.tbl_deep_extend("force", M.config, opts) end

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("BarePresentColorScheme", { clear = true }),
    callback = function()
      if state.enabled then render_presentation() end
    end,
  })

  for _, km in ipairs({
    { "<leader>pt", M.toggle,       "Toggle Presentation Mode" },
    { "<leader>ps", M.start,        "Start Presentation (Dim All)" },
    { "<leader>pn", M.next_block,   "Next Code Block" },
    { "<leader>pp", M.prev_block,   "Previous Code Block" },
    { "<leader>pr", M.reset_colors, "Reset/Reveal All Colors" },
    { "<leader>pm", M.toggle_mode,  "Toggle Mode (Reveal/Spotlight)" },
    { "<A-n>",      M.next_block,   "Next Code Block (Alt+n)" },
    { "<A-p>",      M.prev_block,   "Previous Code Block (Alt+p)" },
  }) do
    vim.keymap.set("n", km[1], km[2], { desc = km[3], silent = true })
  end
end

return M
