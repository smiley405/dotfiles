require('plug')

-- Split so only the first list blocks the first paint; the rest loads on the
-- next event-loop tick. Everything still loads on every start -- it is a
-- reordering, not lazy-loading.

-- Needed before the first buffer is drawn: options and mappings you can hit
-- immediately, g:netrw_*/'undofile' (read when a file loads), rooter's cwd,
-- and the first frame itself.
local eager = {
	'_default',
	'netrw',
	'diagnostic',
	'keymap',
	'colorscheme',
	-- snacks first: noice uses its notifier as the toast backend
	'snacks',
	'noice',
	'hardmode',
	'rooter',
	'lualine',
	'undotree',
}

-- Loaded on the next tick. Order within the list is preserved.
local deferred = {
	'menu',
	'autopairs',
	'completion',
	'comment',
	'fzf',
	'qf',
	'flash',
	'scrollview',
	'colorizer',
	-- safe to defer: neo-tree is the directory handler here
	-- (oil has default_file_explorer = false)
	'oil',
	'outline',
	'git',
	'lsp',
	'neotree',
	-- last: its spec only labels mappings the entries above have defined
	'whichkey',
}

local function load(names)
	for _, name in ipairs(names) do
		require('config.' .. name)
	end
end

load(eager)

vim.schedule(function()
	load(deferred)
	vim.api.nvim_exec_autocmds('User', { pattern = 'ConfigLoaded', modeline = false })
end)
