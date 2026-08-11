require('plug')

local config = {
	'_default',
	'netrw',
	'diagnostic',
	'keymap',
	'colorscheme',
	-- snacks first: noice uses its notifier as the toast backend
	'snacks',
	'noice',
	'hardmode',
	'menu',
	'rooter',
	'lualine',
	'autopairs',
	'completion',
	'undotree',
	'comment',
	'fzf',
	'qf',
	'flash',
	'scrollview',
	'colorizer',
	'oil',
	'outline',
	'git',
	'lsp',
	'neotree',
	-- last: its spec only labels mappings the entries above have defined
	'whichkey'
}

for _, name in ipairs(config) do
	require('config.' .. name)
end
