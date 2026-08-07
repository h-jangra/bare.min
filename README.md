# bare.min
A collection of minimal, modular Neovim Lua plugins.

Load all modules with: `require("bare")`

Or load a single module: `require("bare.module")`

## Requirements
- NVIM v12+
- fzf & ripgrep for fuzzy finder
- Busybox, Tinymist, and grip for Typst/Markdown/HTML Preview

## Language Servers (LSP)
Install supported language servers using `paru` or your system package manager:

```bash
paru -S --needed \
  lua-language-server \
  pyright \
  typescript-language-server \
  vscode-html-languageserver \
  vscode-css-languageserver \
  vscode-json-languageserver \
  taplo \
  bash-language-server \
  yaml-language-server \
  tailwindcss-language-server \
  tinymist
```

Optional language servers:
- `rust-analyzer` (Rust)
- `gopls` (Go)
- `clang` (C/C++)
- `jdtls` (Java)

## Features

| Module            | Description                                                               |
|-------------------|---------------------------------------------------------------------------|
| `bare.buffer`     | Enhanced buffer management.                                               |
| `bare.cmp`        | Native completion using LSP setup.                                        |
| `bare.filetree`   | File explorer integration.                                                |
| `bare.fzf`        | Fuzzy file finder using FZF.                                              |
| `bare.imgPaste`   | Paste/Delete images from clipboard into Markdown/Typst files.             |
| `bare.lsp`        | Native LSP setup.                                                         |
| `bare.marks`      | Manage marks in buffers.                                                  |
| `bare.netrw`      | Short config for better Netrw.                                            |
| `bare.pairs`      | Automatic pairs insertion for `()`, `{}`, `[]`, `''`, `""`, and `` ` ``.  |
| `bare.picker`     | Wildmenu auto trigger and file picker with find.                          |
| `bare.present`    | Presentation mode with dimmed code and progressive block reveal. |
| `bare.preview`    | Preview HTML, Markdown, and Typst files in browser.                       |
| `bare.status`     | Minimal status line.                                                      |
| `bare.surround`   | Easily add/change/delete surrounding characters.                          |
| `bare.theme`      | Catppuccin-Frappé inspired minimal theme for Neovim.                      |

## Presentation Mode Keybindings

Designed for code walkthroughs:

- `<leader>ps`: Start presentation mode (Dims all code blocks to subtle grey).
- `<leader>pn` or `<Alt-n>`: Reveal / Focus **Next** code block.
- `<leader>pp` or `<Alt-p>`: Un-reveal / Focus **Previous** code block.
- `<leader>pr`: **Reset** / Reveal all colors in current buffer.
- `<leader>pm`: Toggle mode between **Progressive Reveal** & **Spotlight Focus**.
- `<leader>pt`: Toggle Presentation Mode on/off.

