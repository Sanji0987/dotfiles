return {
  -- the colorscheme should be available when starting Neovim
  {
    "folke/tokyonight.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      -- load the colorscheme here
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
  -- Fuzzy finding
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Syntax / AST
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- LSP
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },

  -- Completion
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },

  -- File navigation
  { "theprimeagen/harpoon", branch = "harpoon2", dependencies = { "nvim-lua/plenary.nvim" } },
  { "stevearc/oil.nvim" },

  {
    "stevearc/oil.nvim",
    config = function()
      require("oil").setup()
    end,
  },
  { 
    "akinsho/toggleterm.nvim", config = function()
      require("toggleterm").setup({
	size = function(term)
	  if term.direction == "horizontal" then
	    return math.floor(vim.o.lines * 0.4)
	  elseif term.direction == "vertical" then
	    return math.floor(vim.o.columns * 0.3)
	  end
	end,
	start_in_insert = true,
	persist_size = true,
      })
    end 
  },
}
