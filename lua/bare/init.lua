local modules = { "status", "buffer"}

for _, mod in ipairs(modules) do
  local ok, plugin = pcall(require, "bare." .. mod)
  if ok and plugin.setup then
    plugin.setup()
  elseif not ok then
    vim.notify("Failed to load bare.nvim module: " .. mod, vim.log.levels.WARN)
  end
end
