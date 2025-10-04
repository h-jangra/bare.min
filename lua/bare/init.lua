local modules = { "buffer", "liveserver", "status", "snippets" }

for _, mod in ipairs(modules) do
    local ok, _ = pcall(require, "bare." .. mod)
    if not ok then
        vim.notify("Failed to load bare." .. mod, vim.log.levels.WARN)
    end
end
