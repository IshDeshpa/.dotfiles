require("core.plugins")
require("core.mappings")

vim.cmd.colorscheme "catppuccin"

vim.opt.number = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.shiftwidth = 2

vim.g.clipboard = {
  name = "wl-clipboard",
  copy = {
    ["+"] = "wl-copy --foreground --type text/plain",
    ["*"] = "wl-copy --foreground --type text/plain",
  },
  paste = {
    ["+"] = "wl-paste --no-newline",
    ["*"] = "wl-paste --no-newline",
  },
  cache_enabled = true,
}

vim.opt.number = true         -- Show absolute line number on the current line
vim.opt.relativenumber = true -- Show relative line numbers on all other lines

vim.g.mapleader = ' '
vim.keymap.set('n', '<Space>', '<Nop>', { noremap = true, silent = true })

-- LSP navigation and actions
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
vim.keymap.set('n', 'K',  vim.lsp.buf.hover, opts)
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)


-- Keybindings and on_attach for LSP
local on_attach = function(_, bufnr)
local opts = { noremap=true, silent=true, buffer=bufnr }

end
