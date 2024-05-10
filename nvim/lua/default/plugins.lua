-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use 'wbthomason/packer.nvim'

	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.6',
		-- or                            , branch = '0.1.x',
		requires = { 
      {'nvim-lua/plenary.nvim'},
      { "nvim-telescope/telescope-live-grep-args.nvim" }
    },
    config = function ()
      require("telescope").load_extension("live_grep_args")
    end
	} 

	use({
		'rose-pine/neovim',
		as = 'rose-pine',
		config = function()
			vim.cmd('colorscheme rose-pine')
		end
	})

	use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
	use {
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		requires = { {"nvim-lua/plenary.nvim"} }
	}
	use('mbbill/undotree')
	use('tpope/vim-fugitive')

  --  use({
  --  'linrongbin16/gitlinker.nvim',
  --  config = function()
  --    require('gitlinker').setup()
  --  end
  --})

	use {
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v3.x',
		requires = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},
			{'williamboman/mason.nvim'},
			{'williamboman/mason-lspconfig.nvim'},

			-- Autocompletion
			{'hrsh7th/nvim-cmp'},
			{'hrsh7th/cmp-nvim-lsp'},
			{'hrsh7th/cmp-path'},
      {'saadparwaiz1/cmp_luasnip'},
			{'hrsh7th/cmp-nvim-lsp'},
			{'hrsh7th/cmp-nvim-lua'},

      -- Snippets
			{'L3MON4D3/LuaSnip'},
      {'rafamadriz/friendly-snippets'}
		}
	}

	use {"akinsho/toggleterm.nvim", tag = '*', config = function()
		require("toggleterm").setup()
	end}

  use('tpope/vim-rhubarb')

  use({
    "aserowy/tmux.nvim",
    config = function() return require("tmux").setup() end
  })

  use("christoomey/vim-tmux-navigator")

  use("marko-cerovac/material.nvim")

end)
