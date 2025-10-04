local modules = { "buffer", "icons", "liveserver", "snippets", "status" }

for _, mod in ipairs(modules) do
    local ok, _ = pcall(require, "bare." .. mod)
    if not ok then
        vim.notify("Failed to load bare.nvim module: " .. mod, vim.log.levels.WARN)
    end
end
