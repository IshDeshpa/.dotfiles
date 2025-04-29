local telescope = require('telescope')
local builtin = require('telescope.builtin')

telescope.setup({
  defaults = {
    prompt_prefix = '🔍 ',
    selection_caret = '➤ ',
    sorting_strategy = 'ascending',
    layout_config = {
      horizontal = {
        mirror = false,
      },
      vertical = {
        mirror = true,
      },
    },
    file_ignore_patterns = { "node_modules", ".git/" },
  },
  pickers = {
    find_files = {
      hidden = true,  -- Show hidden files
    }
  },
  extensions = {
    fzf = {
      fuzzy = true,             -- fuzzy matching
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case", -- ignore case unless there's a capital letter
    }
  }
})

-- Load the fzf extension
telescope.load_extension('fzf')

-- Keymaps
vim.keymap.set('n', 'ff', builtin.find_files, { noremap = true, silent = true, desc = 'Find Files' })
vim.keymap.set('n', 'fg', builtin.live_grep, { noremap = true, silent = true, desc = 'Live Grep' })
vim.keymap.set('n', 'fb', builtin.buffers, { noremap = true, silent = true, desc = 'Buffers' })
vim.keymap.set('n', 'fh', builtin.help_tags, { noremap = true, silent = true, desc = 'Help Tags' })
vim.keymap.set('n', 'fc', builtin.commands, { noremap = true, silent = true, desc = 'Commands' })
vim.keymap.set('n', 'fs', builtin.current_buffer_fuzzy_find, { noremap = true, silent = true, desc = 'Fuzzy Search in Buffer' })

