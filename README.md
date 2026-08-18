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
- `fzf` & `ripgrep` for fuzzy finder
- `busybox`, `tinymist`, and `grip` for Typst/Markdown/HTML preview
- `wl-paste` (Wayland) or `xclip` (X11) for image pasting

## Features

| Module | Description |
|---|---|
| `bare.buffer` | Enhanced buffer management with interactive winbar tabline. |
| `bare.cmp` | Fast native completion using LSP setup. |
| `bare.diagnostics` | Floating diagnostics picker, severity navigation, and quickfix/loclist integration. |
| `bare.files` | Minimal Oil-like editable buffer file manager with batch edits & visual actions. |
| `bare.floaterm` | Toggleable lightweight floating terminal. |
| `bare.fzf` | Fuzzy file finder and live grep powered by fzf and ripgrep. |
| `bare.git` | Lightweight Git status indicators, hunk navigation, inline preview, and revert. |
| `bare.hints` | Interactive keybinding hints popup (which-key / clue style). |
| `bare.img` | Paste and delete clipboard images in Markdown and Typst files. |
| `bare.lsp` | Native LSP client setup, symbol pickers, code actions, and formatting. |
| `bare.marks` | Sign column indicators and floating viewer for buffer/global marks. |
| `bare.netrw` | Optimized defaults and bindings for netrw. |
| `bare.notify` | Floating notification popups and persistent notification history viewer. |
| `bare.pairs` | Automatic bracket and quote pairing with smart backspace and deletion. |
| `bare.picker` | Wildmenu command line autocomplete and buffer switcher. |
| `bare.present` | Presentation mode with dimmed non-focused code blocks. |
| `bare.preview` | Buffer-local preview for Typst, Markdown, and HTML documents (`after/ftplugin/`). |
| `bare.status` | Ultra-clean minimal status line. |
| `bare.surround` | Add, change, and delete surrounding pairs (`()`, `{}`, `[]`, `""`, `''`, ` `` `). |
| `bare.theme` | Catppuccin-Frappé inspired minimal theme for Neovim. |

---

## Keybindings

### File Explorer (`bare.files`)

- `<leader>e`: Toggle file explorer
- `<CR>` / `l`: Open file / Enter directory
- `h` / `-`: Go to parent directory
- `v` / `<C-v>`: Open in vertical split
- `s` / `<C-x>`: Open in horizontal split
- `<C-t>`: Open in new tab
- `:w` / `<C-s>`: Save & synchronize filesystem changes (create, rename, delete)
- `y` / `yy`: Copy (yank) selected file/directory path
- `p` / `P`: Paste copied files to target directory
- `g.` / `H`: Toggle hidden files
- `R`: Refresh directory
- `~`: Jump to workspace root
- `q` / `<Esc>`: Close explorer

### Fuzzy Finder & Search (`bare.fzf`)

- `<leader><leader>`: Find files (FZF)
- `<leader>fg`: Live grep with ripgrep (FZF)
- `<leader>fr`: Buffer find and replace

### Git (`bare.git`)

- `]h`: Jump to next hunk
- `[h`: Jump to previous hunk
- `<leader>gp`: Preview hunk diff in floating window
- `<leader>gr`: Revert hunk under cursor
- `<leader>gR`: Revert whole file (with confirmation)

### LSP & Symbol Navigation (`bare.lsp`)

- `gd`: Go to Definition
- `gD`: Go to Declaration
- `gr`: LSP References
- `gi`: Go to Implementation
- `gy`: Go to Type Definition
- `K`: Hover Documentation
- `<C-k>`: Signature Help
- `<leader>ca`: Code Action
- `<leader>rn`: Rename Symbol
- `<leader>lf`: Format Buffer
- `<leader>ds`: Document Symbols (Floating Picker)
- `<leader>ws`: Workspace Symbols (Search Picker)

### Diagnostics & Quickfix (`bare.diagnostics`)

- `gl`: Line Diagnostics (Floating popup)
- `]d`: Next Diagnostic
- `[d`: Prev Diagnostic
- `]e`: Next Error
- `[e`: Prev Error
- `]w`: Next Warning
- `[w`: Prev Warning
- `<leader>cd`: Copy Line Diagnostics to Clipboard
- `<leader>xx`: Workspace Diagnostics Picker
- `<leader>xX`: Buffer Diagnostics Picker
- `<leader>xq`: Toggle Quickfix Window
- `<leader>xl`: Toggle Location List
- `<leader>xt`: Toggle Diagnostics On/Off

### Surround (`bare.surround`)

- `sa` (Normal): Surround word under cursor with pair
- `sa` (Visual): Surround visual selection with pair
- `sd`: Delete surrounding characters
- `sc` / `sr`: Change surrounding characters

### Floating Terminal & Notifications

- `<leader>t`: Toggle Floating Terminal (`bare.floaterm`)
- `<leader>n`: Show Notification History (`bare.notify`)

### Image Management (`bare.img`)

- `<leader>p`: Paste clipboard image into Markdown/Typst
- `<leader>d`: Delete image under cursor

### Preview & Presentation

- `:Preview [port]`: Start browser preview for HTML/Markdown/Typst (buffer-local)
- `:PreviewStop`: Stop active preview servers
- `pt`: Toggle Presentation Mode (`bare.present`)
- `<Alt-n>`: Focus Next code block in presentation
- `<Alt-p>`: Focus Previous code block in presentation
