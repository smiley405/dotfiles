local Plug = vim.fn['plug#']

vim.call('plug#begin')

-- colorscheme
Plug 'folke/tokyonight.nvim'

-- vim utils
-- maps globally, so plugin buffers keep their own hjkl. Needs nui.
Plug 'm4xshen/hardtime.nvim'
Plug 'mbbill/undotree'
-- auto-cd to project root; cached history + picker
Plug 'wsdjeg/rooter.nvim'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
-- No Haxe syntax plugin here: .hx highlighting comes from haxe_language_server
-- alone, and .hxsl/.hxml have no filetype at all.

-- nvim utils
Plug 'nvim-lua/plenary.nvim'
-- parsers only; nvim 0.12 does highlighting and context-aware commentstring
-- itself. master is frozen, main is the 0.12-compatible rewrite. Needs the
-- tree-sitter CLI on PATH to build.
Plug('nvim-treesitter/nvim-treesitter', { branch = 'main', ['do'] = ':TSUpdate' })
-- fuzzy finder; needs plenary above
Plug 'nvim-telescope/telescope.nvim'
-- C matcher, the only thing here that compiles. Loaded under pcall, so a failed
-- build just means telescope's slower Lua sorter.
Plug('nvim-telescope/telescope-fzf-native.nvim', {
	['do'] = vim.fn.has('win32') == 1
		and 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release'
		.. ' && cmake --build build --config Release'
		.. ' && cmake --install build --prefix build'
		or 'make'
})
Plug 'windwp/nvim-autopairs'
-- maintained fork; upstream norcalli/ still calls vim.tbl_flatten (gone in 0.13)
Plug 'catgoose/nvim-colorizer.lua'
Plug 'lewis6991/gitsigns.nvim'
Plug 'kevinhwang91/nvim-bqf'
-- search/replace panel: rg args as editable buffer lines. Needs rg 14+.
Plug 'MagicDuck/grug-far.nvim'
-- label-based motions: enhances f/F/t/T and adds a window-wide jump
Plug 'folke/flash.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'petertriho/nvim-scrollbar'
Plug 'hedyhli/outline.nvim'
-- popup listing the keymaps behind whatever prefix was typed
Plug 'folke/which-key.nvim'

-- vscode-like ui: cmdline popup and lsp hover/docs styling (needs nui.nvim)
Plug 'folke/noice.nvim'
-- modular qol collection; see config/snacks.lua for what is switched on
Plug 'folke/snacks.nvim'

-- No in-editor tree: yazi in a wezterm split is the explorer (config/yazi.lua),
-- and netrw handles `nvim <dir>` and `-`. These two stay as libraries -- noice
-- needs nui, lualine and outline need devicons.
Plug 'MunifTanjim/nui.nvim'
Plug 'nvim-tree/nvim-web-devicons'

-- lsp
Plug 'neovim/nvim-lspconfig'
Plug 'mason-org/mason.nvim'
Plug 'mason-org/mason-lspconfig.nvim'
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

-- formatter; runs the project's own binary and falls back to the LSP
Plug 'stevearc/conform.nvim'

vim.call('plug#end')
