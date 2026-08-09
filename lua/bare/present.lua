local M = {}

local ns = vim.api.nvim_create_namespace("present")
local state = { on = false, block = 0, blocks = {}, cursor = nil }

local function parse()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local blocks, start = {}, nil

  for i, line in ipairs(lines) do
    if line:find("%S") then
      start = start or i
    elseif start then
      blocks[#blocks + 1] = { start, i - 1 }
      start = nil
    end
  end

  if start then
    blocks[#blocks + 1] = { start, #lines }
  end

  return blocks
end

local function render()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.opt.guicursor = "n-v-c-sm:hor20,i-ci-ve:ver25"

  for i, block in ipairs(state.blocks) do
    if i > state.block then
      for line = block[1], block[2] do
        local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
        if text ~= "" then
          vim.api.nvim_buf_set_extmark(0, ns, line - 1, 0, {
            end_col = #text,
            hl_group = "NonText",
          })
        end
      end
    end
  end

  if state.block > 0 and state.blocks[state.block] then
    vim.api.nvim_win_set_cursor(0, {
      state.blocks[state.block][1],
      0,
    })
    vim.cmd("normal! zz")
  end
end

function M.start()
  state.cursor = vim.o.guicursor
  vim.o.guicursor = "n-v-c-sm:ver20,i-ci-ve:ver20"
  state.blocks = parse()
  state.block = 0
  state.on = true
  render()
end

function M.stop()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.o.guicursor = state.cursor
  state.cursor = nil
  state.on = false
end

function M.toggle()
  if state.on then M.stop() else M.start() end
end

function M.next()
  if not state.on then M.start() end
  state.block = math.min(#state.blocks, state.block + 1)
  render()
end

function M.prev()
  if not state.on then return end
  state.block = math.max(0, state.block - 1)
  render()
end

function M.reveal()
  state.block = #state.blocks
  render()
end

function M.setup()
  vim.keymap.set("n", "<M-n>", M.next, { silent = true })
  vim.keymap.set("n", "<M-p>", M.prev, { silent = true })
  vim.keymap.set("n", "pt", M.toggle, { silent = true })
  vim.keymap.set("n", "pr", M.reveal, { silent = true })
end

return M
