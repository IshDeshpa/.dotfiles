require('ishdeshpa/telescope')
require('ishdeshpa/cmp')
require('ishdeshpa/copilot')
require('ishdeshpa/lsp')

vim.diagnostic.config({
  virtual_text = true,  -- enable virtual text (inline errors/warnings)
  signs = true,         -- show signs in the gutter
  underline = true,     -- underline the offending code
  update_in_insert = false, -- don't show diagnostics while typing
  severity_sort = true, -- sort by severity
})
