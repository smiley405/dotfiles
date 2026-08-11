-- Collection of independent modules, all off by default; only the ones below
-- are enabled. Must load before config/noice.lua -- noice picks the snacks
-- notifier as its toast backend when it is available.
local ok, snacks = pcall(require, 'snacks')
if not ok then
	vim.notify('snacks.nvim missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

snacks.setup({
	indent = {
		enabled = true,
		indent = { char = '│' },
		scope = { char = '│' },
		-- the animated variant redraws on every cursor move
		animate = { enabled = false },
	},

	-- words = off on purpose: its LspReference highlights are brighter than
	-- Visual under tokyonight, so moving the cursor makes the file look selected.

	-- floating vim.ui.input, used by <leader>vrn (rename)
	input = { enabled = true },

	-- vim.ui.select, used by <space>ca (code action). ui_select hook only --
	-- fzf.vim still handles file/grep search.
	picker = { enabled = true, ui_select = true },

	notifier = {
		enabled = true,
		timeout = 2500,
		style = 'compact',
	},

	-- disables LSP, syntax and matchparen past 1.5MB or a 1000-char average
	-- line; without it, minified bundles lock the editor up
	bigfile = { enabled = true },

	-- statuscolumn = off on purpose: signcolumn = 'yes' plus gitsigns already
	-- draw the marks, and the fold column stays empty under foldmethod=manual.

	-- set vim.g.snacks_scroll = false to disable at runtime if it feels sluggish
	scroll = { enabled = true },

	-- image = off on purpose: the ImageMagick `identify` step hangs on this setup.
})

-- On-demand modules -- no setup() entry, loaded on first use of the mapping.

-- sends workspace/willRenameFiles first, so ts_ls rewrites imports before the
-- file moves (the neo-tree side is wired in config/neotree.lua)
vim.keymap.set('n', '<leader>fr', function() Snacks.rename.rename_file() end,
	{ desc = 'Rename file (update LSP imports)' })

vim.keymap.set('n', '<leader>z', function() Snacks.zen() end, { desc = 'Zen mode' })
vim.keymap.set('n', '<leader>Z', function() Snacks.zen.zoom() end, { desc = 'Zoom window' })

-- unlike :bd, leaves the window layout alone
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>bo', function() Snacks.bufdelete.other() end,
	{ desc = 'Delete other buffers' })
