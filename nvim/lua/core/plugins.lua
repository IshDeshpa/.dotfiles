local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  -- My plugins here
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    requires = { {'nvim-lua/plenary.nvim'} }
  } 
  use { "catppuccin/nvim", as = "catppuccin" }
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}
  use { 
    'neovim/nvim-lspconfig',
    config = function()
      local lspconfig = require("lspconfig")

      -- Optional: define common capabilities and on_attach
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local on_attach = function(client, bufnr)
	-- e.g., key mappings or diagnostics setup
      end

      -- Clangd LSP
      lspconfig.clangd.setup({
	capabilities = capabilities,
	on_attach = on_attach,
      })

      -- HTML LSP
      lspconfig.html.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	init_options = {
	  configurationSection = { "html", "css", "javascript" },
	  embeddedLanguages = {
	    css = true,
	    javascript = true,
	  },
	  provideFormatter = true,
	},
      })
    end
  }
  use { 'hrsh7th/cmp-nvim-lsp' }
  use { 'hrsh7th/nvim-cmp' }
  use { 'L3MON4D3/LuaSnip' }
  use { 'saadparwaiz1/cmp_luasnip' }
  use { 'mechatroner/rainbow_csv' }
  use({
      "kylechui/nvim-surround",
      tag = "*", -- Use for stability; omit to use `main` branch for the latest features
      config = function()
	  require("nvim-surround").setup({
	      -- Configuration here, or leave empty to use defaults
	  })
      end
  })
  -- use 'foo1/bar1.nvim'
  -- use 'foo2/bar2.nvim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)


