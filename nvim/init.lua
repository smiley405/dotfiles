require('plug')

local config = {
	'_default',
	'netrw',
	'diagnostic',
	'keymap',
	'colorscheme',
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
	'hop',
	'scrollview',
	'colorizer',
	'oil',
	'outline',
	'git',
	'lsp'
}

for _, name in ipairs(config) do
	require('config.' .. name)
end
