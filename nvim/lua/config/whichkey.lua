-- which-key.nvim -- after <leader> (or any other prefix) is pressed and
-- nothing follows within `delay`, a popup lists everything reachable from it.
--
-- Loaded last (see init.lua) so every mapping the other config files define
-- already exists when the spec below is registered. Entries here carry no rhs:
-- they only attach a group name or a description to a mapping that is defined
-- elsewhere, so this file never changes what a key does.
--
-- Mappings created with vim.keymap.set + `desc` (config/lsp.lua,
-- config/git.lua, config/snacks.lua, config/neotree.lua, ...) are picked up
-- automatically and are not repeated here -- only the ones defined in
-- vimscript, which has no desc field, need an entry.
local ok, wk = pcall(require, 'which-key')
if not ok then
	vim.notify('which-key.nvim missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

wk.setup({
	preset = 'classic',
	-- ms of idle time before the popup opens. Independent of 'timeoutlen',
	-- so multi-key mappings keep their normal timeout.
	delay = 300,
	win = {
		border = 'rounded',
	},
	-- the built-in help entries at the bottom of the popup are noise once
	-- the bindings are known
	show_help = false,
})

wk.add({
	-- ------------------------------------------------------------------
	-- prefixes
	-- ------------------------------------------------------------------
	{ '<leader>b',  group = 'buffer' },
	{ '<leader>c',  group = 'code' },
	{ '<leader>f',  group = 'find / file' },
	{ '<leader>g',  group = 'git' },
	{ '<leader>n',  group = 'neo-tree' },
	{ '<leader>t',  group = 'tab' },
	{ '<leader>v',  group = 'lsp / hunk' },
	-- <leader>vrn (rename) is the only mapping below <leader>vr; without this
	-- the popup shows a bare '+1 keymap' for it
	{ '<leader>vr', group = 'rename' },

	-- ------------------------------------------------------------------
	-- config/keymap.lua
	-- ------------------------------------------------------------------
	{ '<leader>h',  desc = 'Clear search highlight' },
	{ '<leader>r',  desc = 'Toggle relative line numbers' },
	{ '<leader>p',  desc = 'Copy cwd to clipboard' },
	-- <leader>, . and / are deliberately absent: netrw shadows them
	-- buffer-locally, and an entry here would win over the buffer-local desc
	-- and describe the wrong behaviour there. They carry their own desc in
	-- config/keymap.lua and config/netrw.lua instead.
	{ '<leader>tN', desc = 'New tab' },
	{ '<leader>tn', desc = 'Tab split (current buffer)' },
	{ '<leader>tc', desc = 'Close tab' },
	{ '<leader>to', desc = 'Close tabs to the right' },
	{ '<leader>tO', desc = 'Close tabs to the left' },

	-- ------------------------------------------------------------------
	-- config/fzf.lua
	-- ------------------------------------------------------------------
	{ '<leader>ff', desc = 'Files' },
	{ '<leader>fb', desc = 'Buffers' },
	{ '<leader>fw', desc = 'Windows' },
	{ '<leader>fj', desc = 'Jumps' },
	{ '<leader>fm', desc = 'Marks' },
	{ '<leader>fg', desc = 'Grep (ripgrep)' },
	-- config/keymap.lua, grouped with the other searches
	{ '<leader>fs', desc = 'Search in file -> quickfix' },

	-- ------------------------------------------------------------------
	-- config/git.lua
	-- ------------------------------------------------------------------
	{ '<leader>gd', desc = 'Diff split' },
	{ '<leader>gb', desc = 'Blame' },
	{ '<leader>gc', desc = 'Fugitive status' },
	{ '<leader>gm', desc = 'Toggle mergetool' },

	-- ------------------------------------------------------------------
	-- config/rooter.lua, config/qf.lua
	-- ------------------------------------------------------------------
	{ '<leader>a',  desc = 'Toggle rooter (auto cwd)' },
	-- <leader>q likewise: oil shadows it, so its desc lives in config/qf.lua

	-- ------------------------------------------------------------------
	-- config/flash.lua
	-- ------------------------------------------------------------------
	{ '<leader>s',  desc = 'Flash to char',                     mode = { 'n', 'x', 'o' } },
	{ '<leader>w',  desc = 'Flash to word',                     mode = { 'n', 'x', 'o' } },
	{ '<leader>S',  desc = 'Flash to line',                     mode = { 'n', 'x', 'o' } },
	{ 'f',          desc = 'Flash char forward (line)',         mode = { 'n', 'x', 'o' } },
	{ 'F',          desc = 'Flash char backward (line)',        mode = { 'n', 'x', 'o' } },
	{ 't',          desc = 'Flash till char forward (line)',    mode = { 'n', 'x', 'o' } },
	{ 'T',          desc = 'Flash till char backward (line)',   mode = { 'n', 'x', 'o' } },
	-- flash reclaims these as repeat-last-char-motion (hop broke them)
	{ ';',          desc = 'Repeat flash char motion' },
	{ ',',          desc = 'Repeat flash char motion (reverse)' },

	-- ------------------------------------------------------------------
	-- Comment.nvim (config/comment.lua -- default mappings)
	-- ------------------------------------------------------------------
	{ 'gc',         desc = 'Comment (linewise)',                mode = { 'n', 'x' } },
	{ 'gb',         desc = 'Comment (blockwise)',               mode = { 'n', 'x' } },
	{ 'gcc',        desc = 'Toggle comment line' },
	{ 'gbc',        desc = 'Toggle comment block' },
	{ 'gco',        desc = 'Comment line below' },
	{ 'gcO',        desc = 'Comment line above' },
	{ 'gcA',        desc = 'Comment at end of line' },

	-- ------------------------------------------------------------------
	-- built-ins worth labelling
	-- ------------------------------------------------------------------
	{ '-',          desc = 'Open parent directory (netrw)' },
	{ '_',          desc = 'Open parent directory (oil)' },
	{
		'<leader>?',
		function() wk.show({ global = false }) end,
		desc = 'Buffer-local keymaps'
	},
})
