# bare.min
A collection of minimal, modular Neovim Lua plugins.

Load all modules with: `require("bare")`

Or load a single module: `require("bare.module")`

## Requirements
- NVIM v12+
- fzf & ripgrep for fuzzy finder
- Busybox, Tinymist, and grip for Typst/Markdown/HTML Preview

## Features

| Module | Description |
|---------|-------------|
| `bare.buffer` | Enhanced buffer management. |
| `bare.cmp` | Native completion using LSP setup. |
| `bare.filetree` | File explorer integration. |
| `bare.fzf` | Fuzzy file finder using FZF. |
| `bare.imgPaste` | Paste/Delete images from clipboard into Markdown/Typst files. |
| `bare.lsp` | Native LSP setup. |
| `bare.marks` | Manage marks in buffers. |
| `bare.md` | Markdown styles inside Neovim. |
| `bare.netrw` | Short config for better Netrw. |
| `bare.pairs` | Automatic pairs insertion for `()`, `{}`, `[]`, `''`, `""`, and `` ` ``. |
| `bare.picker` | Wildmenu auto trigger and file picker with find. |
| `bare.preview` | Preview HTML, Markdown, and Typst files in browser. |
| `bare.status` | Minimal status line. |
| `bare.surround` | Easily add/change/delete surrounding characters. |
| `bare.theme` | Catppuccin-Mocha inspired minimal theme for Neovim. |
