-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = false -- Omarchy default

-- macOS: the system clipboard is pbcopy/pbpaste, which Neovim finds on its own.
-- (Omarchy's remote_clipboard.lua is Wayland/Linux-only and is left out.)
vim.opt.clipboard = "unnamedplus"
