-- Popup listing what is reachable from a prefix. Loaded last (see init.lua) so
-- every mapping already exists. Entries carry no rhs -- they only label
-- mappings defined elsewhere, so this file never changes what a key does.
--
-- vim.keymap.set mappings with a `desc` are picked up automatically; only
-- vimscript ones (no desc field) need an entry here.
local ok, wk = pcall(require, 'which-key')
if not ok then
	vim.notify('which-key.nvim missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

wk.setup({
	preset = 'classic',
	-- idle ms before the popup opens; independent of 'timeoutlen'
	delay = 300,
	win = {
		border = 'rounded',
	},
	-- built-in help entries at the bottom are noise once the bindings are known
	show_help = false,
})

wk.add({
	-- prefixes
	{ '<leader>b',  group = 'buffer' },
	{ '<leader>c',  group = 'code' },
	{ '<leader>f',  group = 'find / file' },
	{ '<leader>g',  group = 'git' },
	{ '<leader>t',  group = 'tab' },
	{ '<leader>v',  group = 'lsp / hunk' },
	-- without this the popup shows a bare '+1 keymap' for <leader>vrn
	{ '<leader>vr', group = 'rename' },
	{ '<leader>x',  group = 'diagnostics' },

	-- config/keymap.lua
	{ '<leader>r',  desc = 'Toggle relative line numbers' },
	{ '<leader>p',  desc = 'Copy cwd to clipboard' },
	-- <leader>, . and / are absent on purpose: netrw shadows them buffer-locally
	-- and an entry here would override that desc. See keymap.lua / netrw.lua.
	{ '<leader>tN', desc = 'New tab' },
	{ '<leader>tn', desc = 'Tab split (current buffer)' },
	{ '<leader>tc', desc = 'Close tab' },
	{ '<leader>to', desc = 'Close tabs to the right' },
	{ '<leader>tO', desc = 'Close tabs to the left' },

	-- config/telescope.lua
	{ '<leader>ff', desc = 'Files' },
	{ '<leader>fb', desc = 'Buffers' },
	{ '<leader>fw', desc = 'Windows' },
	{ '<leader>fj', desc = 'Jumps' },
	{ '<leader>fm', desc = 'Marks' },
	{ '<leader>fg', desc = 'Search panel (grug-far)',       mode = { 'n', 'x' } },
	{ '<leader>fs', desc = 'Search in this file' },
	{ '<leader>fp', desc = 'Projects (recent)' },
	{ '<leader>fl', desc = 'Resume last picker' },

	-- config/commands.lua
	{ '<leader>m',  desc = 'Command palette' },

	-- config/rooter.lua, config/qf.lua
	{ '<leader>a',  desc = 'Set scope (cwd) to an ancestor' },
	-- <leader>q is labelled in config/qf.lua, next to the mapping itself

	-- config/flash.lua
	{ '<leader>s',  desc = 'Flash to char',                     mode = { 'n', 'x', 'o' } },
	{ '<leader>w',  desc = 'Flash to word',                     mode = { 'n', 'x', 'o' } },
	{ '<leader>S',  desc = 'Flash to line',                     mode = { 'n', 'x', 'o' } },
	{ 'f',          desc = 'Flash char forward (line)',         mode = { 'n', 'x', 'o' } },
	{ 'F',          desc = 'Flash char backward (line)',        mode = { 'n', 'x', 'o' } },
	{ 't',          desc = 'Flash till char forward (line)',    mode = { 'n', 'x', 'o' } },
	{ 'T',          desc = 'Flash till char backward (line)',   mode = { 'n', 'x', 'o' } },
	-- flash keeps these working as repeat-last-char-motion
	{ ';',          desc = 'Repeat flash char motion' },
	{ ',',          desc = 'Repeat flash char motion (reverse)' },

	-- Comment.nvim (config/comment.lua -- default mappings)
	{ 'gc',         desc = 'Comment (linewise)',                mode = { 'n', 'x' } },
	{ 'gb',         desc = 'Comment (blockwise)',               mode = { 'n', 'x' } },
	{ 'gcc',        desc = 'Toggle comment line' },
	{ 'gbc',        desc = 'Toggle comment block' },
	{ 'gco',        desc = 'Comment line below' },
	{ 'gcO',        desc = 'Comment line above' },
	{ 'gcA',        desc = 'Comment at end of line' },

	-- built-ins worth labelling
	{ '-',          desc = 'Open parent directory (netrw)' },
	{
		'<leader>?',
		function() wk.show({ global = false }) end,
		desc = 'Buffer-local keymaps'
	},
})
