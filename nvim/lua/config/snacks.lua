-- snacks.nvim is a collection of independent modules, all disabled by
-- default. Only the ones below are switched on -- the ones that close a
-- genuine gap against VSCode. Everything else stays off on purpose.
--
-- Loaded before config/noice.lua, because noice picks the snacks notifier as
-- its toast backend when it is available (noice/config/views.lua:
-- notify.backend = { 'snacks', 'notify' }).
local ok, snacks = pcall(require, 'snacks')
if not ok then
	vim.notify('snacks.nvim missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

snacks.setup({
	-- indent guides, plus a highlighted guide for the enclosing scope.
	-- Nothing was drawing these before: config/indent.lua referenced
	-- indent-blankline, which was never installed or loaded.
	indent = {
		enabled = true,
		indent = { char = '│' },
		scope = { char = '│' },
		-- static guides; the animated variant redraws on every cursor move
		animate = { enabled = false },
	},

	-- words = deliberately left off. It highlighted every occurrence of the
	-- symbol under the cursor via LSP documentHighlight, which paints
	-- LspReference{Text,Read,Write} -- and tokyonight gives those a #3B4261
	-- background, brighter than Visual's #283457. So from the moment a server
	-- finished initializing, moving the cursor made the file look selected,
	-- more strongly than an actual selection. Keeping it meant overriding
	-- those highlight groups on every colorscheme; not worth it for the
	-- feature.

	-- floating prompt for vim.ui.input, which is what <leader>vrn
	-- (vim.lsp.buf.rename) goes through -- closer to VSCode's F2 box than
	-- the default cmdline prompt
	input = { enabled = true },

	-- the counterpart for vim.ui.select: <space>ca (vim.lsp.buf.code_action)
	-- hands its list to vim.ui.select, which `input` does not touch. Enabling
	-- picker swaps in a floating, filterable list -- VSCode's lightbulb menu.
	-- Only the ui_select hook is used; fzf.vim still handles file/grep search,
	-- and the picker core is required lazily on first use.
	picker = { enabled = true, ui_select = true },

	-- toast backend; replaces nvim-notify
	notifier = {
		enabled = true,
		timeout = 2500,
		style = 'compact',
	},

	-- VSCode's 'tokenization skipped, file too large'. Turns off LSP, syntax
	-- and matchparen past 1.5MB or a 1000-char average line, which is what a
	-- minified bundle looks like. Without it those files lock the editor up.
	bigfile = { enabled = true },

	-- statuscolumn = deliberately left off. signcolumn = 'yes' (_default.lua)
	-- plus gitsigns already draw the git marks; it would only move them to the
	-- right of the line number, and its fold column stays empty under
	-- foldmethod = 'manual'. Not worth a per-line callback on every redraw.

	-- smooth scrolling. Purely cosmetic, and it animates through redraws --
	-- if it feels sluggish over WSL, set `vim.g.snacks_scroll = false` to
	-- switch it off at runtime without touching this file.
	scroll = { enabled = true },

	-- image = deliberately left off. It renders via the Kitty graphics
	-- protocol, which wezterm speaks, but the ImageMagick `identify` step
	-- hangs on this setup and the previews are not worth the stalls.
})

-- The modules below are on-demand -- they have no setup() entry and are
-- loaded the first time the mapping is used.

-- LSP-integrated file rename. Sends workspace/willRenameFiles first, so
-- ts_ls rewrites every import of the file before it moves. This is VSCode's
-- 'update imports on rename'; the neo-tree side is wired in config/neotree.lua.
vim.keymap.set('n', '<leader>fr', function() Snacks.rename.rename_file() end,
	{ desc = 'Rename file (update LSP imports)' })

-- distraction-free writing, and zoom the current window to fill the tab
-- (VSCode's Zen Mode and 'maximize editor group')
vim.keymap.set('n', '<leader>z', function() Snacks.zen() end, { desc = 'Zen mode' })
vim.keymap.set('n', '<leader>Z', function() Snacks.zen.zoom() end, { desc = 'Zoom window' })

-- close a buffer the way VSCode closes a tab: the split it was in stays put,
-- instead of :bd collapsing the window layout
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>bo', function() Snacks.bufdelete.other() end,
	{ desc = 'Delete other buffers' })
