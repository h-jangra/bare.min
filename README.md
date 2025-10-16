# bare.nvim

A collection of minimal, modular Neovim Lua plugins.

```lua
-- load theme first otherwise bufferline colors wont work
require("bare.theme").setup()
require("bare.buffer")
require("bare.status")
require("bare.cmp")
require("bare.lsp")
require("bare.fzf").setup()
require("bare.netrw")
require("bare.filetree").setup()
require("bare.liveserver").setup()
require("bare.marks").setup()
require("bare.surround").setup()
require("bare.pairs").setup()
````

- Load everything at once with `require("bare")`
- Load only what you need with `require("bare.module")`

