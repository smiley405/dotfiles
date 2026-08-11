-- flash.nvim -- replaces hop.nvim.
--
-- The reason for the swap: hop mapped f/F/t/T to plain function calls, which
-- cost them their status as motions -- `df<char>` was not dot-repeatable and
-- `;`/`,` no longer repeated anything. flash routes the jump through
-- 'operatorfunc' instead, so `.` replays it and `;`/`,` work again, which is
-- what vim-hardtime is training towards.
--
-- These maps are global, so a buffer-local mapping still wins: neo-tree keeps
-- its own f/t/T, netrw keeps t. That was equally true of the hop config.
require('flash').setup({
	-- only the current window, like hop's defaults
	search = { multi_window = false },
	jump = { nohlsearch = true },
	-- hop cleared HopUnmatched to keep unmatched text at normal colours;
	-- the flash equivalent is not dimming the buffer at all
	highlight = { backdrop = false },
	-- Labels stay mixed case, unlike hop's. flash only ever draws one char per
	-- label, so limiting them to lower case halves the pool to 26 and the
	-- furthest matches simply go unlabelled. hop got lower case everywhere by
	-- falling back to two-char labels, which flash has no equivalent for.
	modes = {
		-- leave `/` and `?` alone -- hop never touched them, and labels on
		-- regular search is a bigger behaviour change than the rest of this
		search = { enabled = false },
		-- f/F/t/T: hop hinted a single char on the current line only
		char = {
			enabled = true,
			jump_labels = true,
			multi_line = false,
			highlight = { backdrop = false },
		},
	},
})

local flash = require('flash')

-- HopChar1 equivalent (whole window). Typing one char and picking a label is
-- the same keystroke count as before; typing more narrows the matches first,
-- which HopChar1 could not do. Also mapped in operator-pending so `d<leader>s`
-- works -- hop was only set up for normal and visual.
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>s', function()
	flash.jump()
end, { silent = true, desc = 'Flash to char' })

-- HopWord equivalent: match zero width at every word start so the labels are
-- there before any search char is typed, and draw each one over the word's
-- first column. `max_length = 0` also stops flash reserving labels for a
-- possible next char, so the whole alphabet stays available.
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>w', function()
	flash.jump({
		search = { mode = 'search', max_length = 0 },
		label = { after = { 0, 0 } },
		pattern = [[\<]],
	})
end, { silent = true, desc = 'Flash to word' })

-- HopLine equivalent: flash has no line mode, so match zero width at the start
-- of every line and draw the label on the first column rather than after the
-- match.
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>S', function()
	flash.jump({
		search = { mode = 'search', max_length = 0 },
		label = { after = { 0, 0 } },
		pattern = '^',
	})
end, { silent = true, desc = 'Flash to line' })
