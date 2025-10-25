local M = {}

-- Paste clipboard image
function M.paste()
  local ft = vim.bo.filetype
  if ft ~= 'markdown' and ft ~= 'typst' then
    print("Error: Not a markdown or typst file.")
    return
  end

  local filename_base = vim.fn.input("Image filename (no extension): ")
  if filename_base == "" then
    print("Cancelled.")
    return
  end

  local filename = filename_base .. ".png"
  local current_dir = vim.fn.expand('%:p:h')
  local assets_dir = current_dir .. "/assets"
  local image_path = assets_dir .. "/" .. filename
  local relative_path = "./assets/" .. filename

  if vim.fn.isdirectory(assets_dir) == 0 then
    vim.fn.mkdir(assets_dir, "p")
  end

  local cmd
  if vim.fn.has('mac') == 1 then
    if vim.fn.executable('pngpaste') == 0 then
      print("Error: 'pngpaste' not found. Run 'brew install pngpaste'")
      return
    end
    cmd = "pngpaste " .. vim.fn.shellescape(image_path)
  elseif vim.fn.has('win32') == 1 then
    cmd =
        "powershell -NoProfile -Command \"Add-Type -AssemblyName System.Windows.Forms; if ([System.Windows.Forms.Clipboard]::ContainsImage()) { [System.Windows.Forms.Clipboard]::GetImage().Save('" ..
        image_path .. "', [System.Drawing.Imaging.ImageFormat]::Png) } else { throw 'No image in clipboard.' }\""
  elseif vim.fn.has('unix') == 1 then
    if os.getenv('WAYLAND_DISPLAY') and vim.fn.executable('wl-paste') == 1 then
      cmd = "wl-paste -t image/png > " .. vim.fn.shellescape(image_path)
    elseif vim.fn.executable('xclip') == 1 then
      cmd = "xclip -selection clipboard -t image/png -o > " .. vim.fn.shellescape(image_path)
    else
      print("Error: 'xclip' (X11) or 'wl-paste' (Wayland) not found.")
      return
    end
  else
    print("Error: Unsupported OS.")
    return
  end

  vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 or vim.fn.getfsize(image_path) <= 0 then
    print("Error: Failed to save image. Is an image in the clipboard?")
    if vim.fn.filereadable(image_path) == 1 then
      vim.fn.delete(image_path)
    end
    return
  end

  local line_to_insert
  if ft == 'markdown' then
    line_to_insert = "![" .. filename_base .. "](" .. relative_path .. ")"
  elseif ft == 'typst' then
    line_to_insert = "#image(\"" .. relative_path .. "\", width: 70%)"
  end

  vim.api.nvim_put({ line_to_insert }, 'c', true, true)
  print("Pasted " .. filename)
end

-- Delete image under cursor
function M.delete()
  local line = vim.api.nvim_get_current_line()
  local path

  -- Extract image path for markdown
  path = line:match("!%[.-%]%((.-)%)")
  -- Extract image path for typst
  if not path then
    path = line:match('#image%("(.+)"')
  end

  if not path then
    print("No image found on the current line.")
    return
  end

  local current_dir = vim.fn.expand('%:p:h')
  local image_path = current_dir .. "/" .. path:gsub("^%./", "")

  if vim.fn.filereadable(image_path) == 1 then
    vim.fn.delete(image_path)
    print("Deleted image: " .. image_path)
  else
    print("Image file does not exist: " .. image_path)
  end
end

vim.keymap.set('n', '<leader>p', M.paste, { desc = "Paste clipboard image" })
vim.keymap.set('n', '<leader>d', M.delete, { desc = "Delete image under cursor" })

return M
