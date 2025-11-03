return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- default
    },
    config = function(_, opts)
      local catppuccin = require("catppuccin")

      -- Setup and load the default colorscheme
      catppuccin.setup(opts)
      vim.cmd.colorscheme("catppuccin")

      -- Helper function to find index of value in a table
      local function index_of(tbl, val)
        for i, v in ipairs(tbl) do
          if v == val then
            return i
          end
        end
        return nil
      end

      -- List of flavours
      local flavours = { "latte", "frappe", "macchiato", "mocha" }
      local current_index = index_of(flavours, opts.flavour) or 4

      -- Keymap to cycle flavours
      vim.keymap.set("n", "<leader>ut", function()
        current_index = (current_index % #flavours) + 1
        local flavour = flavours[current_index]
        catppuccin.setup({ flavour = flavour })
        vim.cmd.colorscheme("catppuccin")
        vim.notify("Catppuccin theme: " .. flavour, vim.log.levels.INFO)
      end, { desc = "Cycle Catppuccin theme" })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
