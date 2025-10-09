-- load onedark first otherwise bufferline colors wont work
require("bare.onedark")
require("bare.buffer")
require("bare.status")
require("bare.cmp")
require("bare.lsp")

require("bare.marks").setup()
require("bare.fzf").setup()
require("bare.liveserver").setup({ default_port = 8080 })
require("bare.netrw")
require("bare.filetree").setup()
require("bare.pairs").setup()
