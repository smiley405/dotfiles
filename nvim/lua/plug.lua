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
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug('junegunn/fzf', {
	['do'] = function()
		vim.fn['fzf#install']()
	end
})
Plug 'junegunn/fzf.vim'
-- vim-polyglot was here, and is gone entirely. It sourced ~5.5ms of ftdetect
-- for ~600 languages on every start, and Nvim 0.12 now ships *more* syntax
-- than it does (771 files vs 648). Haxe was the only pack still earning its
-- keep; haxe_language_server (config/lsp.lua) covers that instead.
--
-- Worth knowing if a .hx file ever looks unhighlighted: nothing in this config
-- provides Haxe *syntax* any more. Nvim maps .hx -> haxe but ships no
-- syntax/haxe.vim, and there is no treesitter haxe parser installed either, so
-- highlighting comes solely from the language server's semantic tokens. Nvim
-- has no rule for .hxsl or .hxml at all -- those open as plain text.
Plug 'samoshkin/vim-mergetool'
Plug 'justinmk/vim-gtfo'

-- nvim utils
Plug 'nvim-lua/plenary.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'lewis6991/gitsigns.nvim'
Plug 'numToStr/Comment.nvim'
Plug 'kevinhwang91/nvim-bqf'
-- label-based motions: enhances f/F/t/T and adds a window-wide jump
Plug 'folke/flash.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'petertriho/nvim-scrollbar'
Plug 'stevearc/oil.nvim'
Plug 'hedyhli/outline.nvim'
-- popup listing the keymaps behind whatever prefix was typed
-- (uses nvim-web-devicons, declared below, for the per-mapping icons)
Plug 'folke/which-key.nvim'

-- vscode-like ui: cmdline popup and lsp hover/docs styling
-- (needs MunifTanjim/nui.nvim, declared below)
Plug 'folke/noice.nvim'
-- modular qol collection; only indent guides, symbol highlighting, the
-- vim.ui.input box and the notifier are switched on (see config/snacks.lua).
-- also provides the notification backend noice renders toasts through.
Plug 'folke/snacks.nvim'

-- tree file explorer
Plug 'nvim-neo-tree/neo-tree.nvim'
Plug 'MunifTanjim/nui.nvim'
Plug 'nvim-tree/nvim-web-devicons'

-- lsp
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'

-- cmp
--
-- `on = {}` is vim-plug for "never load this on your own" -- the plugin is
-- registered but kept out of 'runtimepath' until something calls plug#load().
-- config/completion.lua does exactly that, from the deferred half of init.lua.
--
-- Without it these load during startup no matter how late the config module
-- runs: cmp-buffer, cmp_luasnip and LuaSnip all ship after/plugin/ files, and
-- those are sourced before the first paint and drag the whole cmp + LuaSnip
-- require chain in with them. None of it is needed until insert mode.
local lazy = { on = {} }

Plug('hrsh7th/nvim-cmp', lazy)
Plug('hrsh7th/cmp-nvim-lsp', lazy)
Plug('hrsh7th/cmp-buffer', lazy)
Plug('hrsh7th/cmp-path', lazy)
Plug('hrsh7th/cmp-nvim-lsp-signature-help', lazy)
Plug('L3MON4D3/LuaSnip', lazy)
Plug('saadparwaiz1/cmp_luasnip', lazy)
-- snippet data only, but it still has to be in 'runtimepath' before
-- luasnip's from_vscode loader can find it
Plug('rafamadriz/friendly-snippets', lazy)

-- formatter
Plug 'sbdchd/neoformat'

-- actionscript
-- Plug 'jeroenbourgois/vim-actionscript'

vim.call('plug#end')
