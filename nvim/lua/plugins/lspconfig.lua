return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable pyright
        pyright = false,
        -- Disable basedpyright if you have it
        basedpyright = false,
      },
    },
  },
}
