return {
  'chomosuke/typst-preview.nvim',
  ft = 'typst', -- load only for Typst files
  version = '1.*',
  opts = {}, -- lazy.nvim will call setup{}

  keys = {
    {
      '<leader>tp',
      function()
        vim.cmd('TypstPreviewToggle')
      end,
      desc = 'Toggle Typst Preview',
    },
  },
}
