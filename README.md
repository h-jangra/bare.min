# bare.min
A collection of minimal, modular Neovim Lua plugins.

```lua
vim.pack.add({ "https://github.com/h-jangra/bare.min" })

require("bare")
```

Load individual modules:
```lua
require("bare.lsp")
require("bare.fzf")
```

## Requirements
- NVIM v12+
- fzf & ripgrep for fuzzy finder
- Busybox, Tinymist, and grip for Typst/Markdown/HTML Preview

## Features

| Module            | Description                                                               |
|-------------------|---------------------------------------------------------------------------|
| `bare.buffer`     | Enhanced buffer management.                                               |
| `bare.cmp`        | Native completion using LSP setup.                                        |
| `bare.files`      | Minimal Oil-like file editing.                                            |
| `bare.filetree`   | File explorer integration.                                                |
| `bare.fzf`        | Fuzzy file finder using FZF.                                              |
| `bare.git`        | Lightweight Git indicators + hunk navigation + preview + revert.          |
| `bare.img`        | Paste/Delete images from clipboard into Markdown/Typst files.             |
| `bare.lsp`        | Native LSP setup.                                                         |
| `bare.marks`      | Manage marks in buffers.                                                  |
| `bare.netrw`      | Short config for better Netrw.                                            |
| `bare.pairs`      | Automatic pairs insertion for `()`, `{}`, `[]`, `''`, `""`, and `` ` ``.  |
| `bare.picker`     | Wildmenu auto trigger and file picker with find.                          |
| `bare.present`    | Presentation mode with dimmed code.                                       |
| `bare.preview`    | Preview HTML, Markdown, and Typst files in browser.                       |
| `bare.status`     | Minimal status line.                                                      |
| `bare.surround`   | Easily add/change/delete surrounding characters.                          |
| `bare.theme`      | Catppuccin-Frappé inspired minimal theme for Neovim.                      |

## Git Keybindings

- `]h`: Jump to next hunk
- `[h`: Jump to previous hunk
- `<leader>gp`: Preview hunk diff in floating window
- `<leader>gr`: Revert hunk under cursor
- `<leader>gR`: Revert whole file (with confirmation)

## Presentation Mode Keybindings

- `<Alt-n>`: Focus Next code block.
- `<Alt-p>`: Focus Previous code block.
- `pt`: Toggle Presentation

