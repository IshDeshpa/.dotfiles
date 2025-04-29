local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

-- Add LSP capabilities to enable completion
local capabilities = cmp_nvim_lsp.default_capabilities()

-- clangd setup
lspconfig.clangd.setup({
  capabilities = capabilities,
})

