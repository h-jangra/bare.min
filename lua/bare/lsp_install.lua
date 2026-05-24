local servers = {
  lua_ls = "lua-language-server",
  pyright = "pyright",
  ts_ls = "typescript-language-server",
  rust_analyzer = "rust-analyzer",
  gopls = "gopls",
  clangd = "clang",
  html = "vscode-html-languageserver",
  cssls = "vscode-css-languageserver",
  jsonls = "vscode-json-languageserver",
  taplo = "taplo",
  bashls = "bash-language-server",
  tailwindcss = "tailwindcss-language-server",
  tinymist = "tinymist",
  jdtls = "jdtls",
}

local installed = {}
local missing = {}

for _, bin in pairs(servers) do
  if vim.fn.executable(bin) == 1 then
    installed[#installed + 1] = bin
  else
    missing[#missing + 1] = bin
  end
end

vim.api.nvim_create_user_command("LspInstall", function()
  if #missing == 0 then
    vim.notify("All LSPs installed")
    return
  end

  local cmd = "paru -S --needed " .. table.concat(missing, " ")

  vim.notify("Installing:\n" .. table.concat(missing, "\n"))

  vim.fn.termopen(cmd)
end, {})

vim.api.nvim_create_user_command("LspCheck", function()
  print("Installed:")
  for _, v in ipairs(installed) do
    print("  ✓ " .. v)
  end

  if #missing > 0 then
    print("\nMissing:")
    for _, v in ipairs(missing) do
      print("  ✗ " .. v)
    end
  end
end, {})
