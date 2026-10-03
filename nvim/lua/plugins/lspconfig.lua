return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = false,
        typst_lsp = false,
        tinymist = {
          on_init = function(client)
            -- Tinymist may advertise tokens even with semanticTokens disabled.
            client.server_capabilities.semanticTokensProvider = nil
          end,
          settings = {
            -- Keep syntax highlighting under Treesitter/Markview's control.
            semanticTokens = "disable",
          },
        },
      },
    },
  },
}
