local Plug = vim.fn['plug#']

vim.call('plug#begin')

-- colorscheme
Plug 'Mofiqul/vscode.nvim'

-- vim utils
Plug 'takac/vim-hardtime'
Plug 'dstein64/vim-menu'
Plug 'mbbill/undotree'
Plug 'airblade/vim-rooter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug('junegunn/fzf', { ['do'] = function()
  vim.fn['fzf#install']()
end })
Plug 'junegunn/fzf.vim'
Plug 'sheerun/vim-polyglot'
Plug 'samoshkin/vim-mergetool'
Plug 'justinmk/vim-gtfo'

-- nvim utils
Plug 'nvim-lua/plenary.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'lewis6991/gitsigns.nvim'
Plug 'numToStr/Comment.nvim'
Plug 'kevinhwang91/nvim-bqf'
Plug 'smoka7/hop.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'petertriho/nvim-scrollbar'
Plug 'stevearc/oil.nvim'
Plug 'hedyhli/outline.nvim'

-- lsp
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'

-- cmp
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'rafamadriz/friendly-snippets'

-- formatter
Plug 'sbdchd/neoformat'

-- actionscript
-- Plug 'jeroenbourgois/vim-actionscript'

vim.call('plug#end')

