local Plug = vim.fn['plug#']

vim.call('plug#begin')

-- colorscheme
-- Plug 'Mofiqul/vscode.nvim'
Plug 'folke/tokyonight.nvim'

-- vim utils
Plug 'takac/vim-hardtime'
Plug 'dstein64/vim-menu'
Plug 'mbbill/undotree'
Plug 'airblade/vim-rooter'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug('junegunn/fzf', {
	['do'] = function()
		vim.fn['fzf#install']()
	end
})
Plug 'junegunn/fzf.vim'
-- vim-polyglot removed: ~5.5ms of ftdetect per start, and nvim 0.12 ships more
-- syntax than it does. Note nothing provides Haxe *syntax* now -- .hx
-- highlighting comes solely from haxe_language_server, and .hxsl/.hxml have no
-- filetype at all.
Plug 'justinmk/vim-gtfo'

-- nvim utils
Plug 'nvim-lua/plenary.nvim'
Plug 'windwp/nvim-autopairs'
-- maintained fork; upstream norcalli/ still calls vim.tbl_flatten (gone in 0.13)
Plug 'catgoose/nvim-colorizer.lua'
Plug 'lewis6991/gitsigns.nvim'
-- diff, file history, and the 3-way merge tool (see config/git.lua)
Plug 'sindrets/diffview.nvim'
Plug 'numToStr/Comment.nvim'
Plug 'kevinhwang91/nvim-bqf'
-- label-based motions: enhances f/F/t/T and adds a window-wide jump
Plug 'folke/flash.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'petertriho/nvim-scrollbar'
Plug 'stevearc/oil.nvim'
Plug 'hedyhli/outline.nvim'
-- popup listing the keymaps behind whatever prefix was typed
Plug 'folke/which-key.nvim'

-- vscode-like ui: cmdline popup and lsp hover/docs styling (needs nui.nvim)
Plug 'folke/noice.nvim'
-- modular qol collection; see config/snacks.lua for what is switched on
Plug 'folke/snacks.nvim'

-- tree file explorer
Plug 'nvim-neo-tree/neo-tree.nvim'
Plug 'MunifTanjim/nui.nvim'
Plug 'nvim-tree/nvim-web-devicons'

-- lsp
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
-- feeds lua_ls only the plugin dirs this config require()s
Plug 'folke/lazydev.nvim'

-- cmp
--
-- `on = {}` keeps these out of 'runtimepath' until config/completion.lua calls
-- plug#load(). Without it they load during startup regardless of config order:
-- cmp-buffer, cmp_luasnip and LuaSnip ship after/plugin/ files that pull in the
-- whole cmp + LuaSnip chain before the first paint.
local lazy = { on = {} }

Plug('hrsh7th/nvim-cmp', lazy)
Plug('hrsh7th/cmp-nvim-lsp', lazy)
Plug('hrsh7th/cmp-buffer', lazy)
Plug('hrsh7th/cmp-path', lazy)
Plug('L3MON4D3/LuaSnip', lazy)
Plug('saadparwaiz1/cmp_luasnip', lazy)
-- data only, but must be in 'runtimepath' for luasnip's from_vscode loader
Plug('rafamadriz/friendly-snippets', lazy)

-- formatter
Plug 'sbdchd/neoformat'

-- actionscript
-- Plug 'jeroenbourgois/vim-actionscript'

vim.call('plug#end')
