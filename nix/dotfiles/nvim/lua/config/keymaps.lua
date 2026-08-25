-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader><leader>", function()
  Snacks.picker.files({
    cwd = vim.uv.cwd(),   -- IMPORTANT: use uv.cwd()
    root = false,         -- disables root detection
  })
end)
