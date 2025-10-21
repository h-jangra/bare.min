# bare.nvim

A collection of minimal, modular Neovim Lua plugins.

```lua
-- load theme first otherwise bufferline colors wont work
require("bare.theme").setup()
require("bare.buffer") -- Bufferline
require("bare.status") -- Statusline
require("bare.cmp") -- LSP code completion
require("bare.lsp") -- Native lsp setup
require("bare.fzf").setup() -- Fuzzy finder with fzf & ripgrep
require("bare.netrw") -- Better netrw settings
require("bare.filetree").setup()
require("bare.liveserver").setup() -- Liveserver for html & typst
require("bare.marks").setup() -- Visual marks in sign column
require("bare.surround").setup() -- Surround text objects
require("bare.pairs").setup() -- Auto bracket pairing
```

- Load everything at once with `require("bare")`
- Load only what you need with `require("bare.module")`

