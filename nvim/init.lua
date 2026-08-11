require('plug')

-- Startup used to be one flat list of 26 requires, all of it blocking the
-- first paint. Most of those modules only matter once you actually interact
-- with the editor -- entering insert mode, running a command, pressing a
-- keymap -- so they are split off below and loaded on the first event-loop
-- tick instead.
--
-- This is a reordering, not lazy-loading: everything still loads, on every
-- start, unconditionally. Total work is unchanged; what changes is that the
-- UI is drawn and interactive before the expensive half runs.

-- Has to be in place before the first buffer is drawn.
--   _default/keymap  -- options and mappings you can hit immediately
--   netrw/undotree   -- set g:netrw_* and 'undofile', both read when a file is
--                       loaded, so they are too late on the next tick
--   rooter           -- picks the cwd off the first buffer
--   colorscheme/lualine/snacks/noice -- the first frame itself
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
	-- safe to defer: it is not the directory handler here
	-- (default_file_explorer = false), neo-tree is, and neo-tree registers that
	-- hijack from its own plugin file rather than from setup()
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
	-- lets a config or a plugin hook the point where the editor is fully set up
	vim.api.nvim_exec_autocmds('User', { pattern = 'ConfigLoaded', modeline = false })
end)
