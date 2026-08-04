local M = {}
local api, fs, fn, notify, log = vim.api, vim.fs, vim.fn, vim.notify, vim.log.levels

local FILETYPES = {
  markdown = { insert = "![%s](%s)", pattern = "!%[.-%]%((.-)%)" },
  typst = { insert = '#image("%s", width: 70%%)', pattern = '#image%("(.+)"' },
}

local function doc_dir()
  return fs.dirname(api.nvim_buf_get_name(0))
end

local function err(msg)
  notify(msg, log.ERROR)
end

local function get_clipboard_cmd(image_path)
  if fn.has("unix") ~= 1 then
    return nil, "Error: Unsupported OS."
  end

  local escaped = fn.shellescape(image_path)
  if os.getenv("WAYLAND_DISPLAY") and fn.executable("wl-paste") == 1 then
    return { "sh", "-c", "wl-paste -t image/png > " .. escaped }
  end

  if fn.executable("xclip") == 1 then
    return { "sh", "-c", "xclip -selection clipboard -t image/png -o > " .. escaped }
  end

  return nil, "Error: 'xclip' (X11) or 'wl-paste' (Wayland) not found."
end

function M.paste()
  local ft = vim.bo.filetype
  local config = FILETYPES[ft]
  if not config then
    err("Error: Not a markdown or typst file.")
    return
  end

  local filename_base = fn.input("Image filename (no extension): ")
  if filename_base == "" then
    notify("Cancelled.", log.INFO)
    return
  end

  local filename = filename_base .. ".png"
  local current_dir = doc_dir()
  local assets_dir = fs.joinpath(current_dir, "assets")
  local image_path = fs.joinpath(assets_dir, filename)
  local relative_path = "./assets/" .. filename

  if not vim.uv.fs_stat(assets_dir) then
    vim.uv.fs_mkdir(assets_dir, 493) -- 0755 permissions
  end

  local cmd, cmd_err = get_clipboard_cmd(image_path)
  if not cmd then
    err(cmd_err)
    return
  end

  local res = vim.system(cmd):wait()

  local stat = vim.uv.fs_stat(image_path)
  if res.code ~= 0 or not stat or stat.size <= 0 then
    err("Error: Failed to save image. Is an image in the clipboard?")
    if stat then
      vim.uv.fs_unlink(image_path)
    end
    return
  end

  local line = (ft == "markdown")
      and config.insert:format(filename_base, relative_path)
      or config.insert:format(relative_path)

  api.nvim_put({ line }, "c", true, true)
  notify("Pasted " .. filename, log.INFO)
end

function M.delete()
  local line = api.nvim_get_current_line()
  local path

  for _, cfg in next, FILETYPES do
    path = line:match(cfg.pattern)
    if path then
      break
    end
  end

  if not path then
    notify("No image found on the current line.", log.WARN)
    return
  end

  local current_dir = doc_dir()
  local image_path = fs.normalize(fs.joinpath(current_dir, path))

  -- Check that the target path resides inside the document's directory tree to prevent traversal deletion
  if not vim.startswith(image_path, current_dir) then
    err("Error: Blocked attempt to delete file outside the document directory.")
    return
  end

  if vim.uv.fs_stat(image_path) then
    vim.uv.fs_unlink(image_path)
    notify("Deleted image: " .. image_path, log.INFO)
  else
    notify("Image file does not exist: " .. image_path, log.WARN)
  end
end

function M.setup()
  vim.keymap.set("n", "<leader>p", M.paste, { desc = "Paste clipboard image" })
  vim.keymap.set("n", "<leader>d", M.delete, { desc = "Delete image under cursor" })
end

return M
