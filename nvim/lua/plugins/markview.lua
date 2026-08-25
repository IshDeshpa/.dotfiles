return {
  "OXY2DEV/markview.nvim",
  lazy = false,

  opts = {
    typst = {
      math_blocks = { enable = false },
      math_spans = { enable = false },
      symbols = { enable = false },
    },
    latex = {
      blocks = { enable = false },
      inlines = { enable = false },
    },
  },

  -- For blink.cmp's completion
  -- source
  -- dependencies = {
  --     "saghen/blink.cmp"
  -- },
};
