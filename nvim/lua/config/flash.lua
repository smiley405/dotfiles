-- Replaces hop.nvim: flash routes jumps through 'operatorfunc', so f/F/t/T stay
-- real motions -- `df<char>` is dot-repeatable and `;`/`,` still repeat.
--
-- The maps below are global, so buffer-local ones still win (neo-tree keeps its
-- own f/t/T, netrw keeps t).
require('flash').setup({
	search = { multi_window = false },
	jump = { nohlsearch = true },
	highlight = { backdrop = false },
	modes = {
		-- labels on regular search is a bigger behaviour change than the rest
		search = { enabled = false },
		char = {
			enabled = true,
			jump_labels = true,
			multi_line = false,
			highlight = { backdrop = false },
		},
	},
})

local flash = require('flash')

vim.keymap.set({ 'n', 'x', 'o' }, '<leader>s', function()
	flash.jump()
end, { silent = true, desc = 'Flash to char' })

-- label every word start: zero-width match so labels appear before any search
-- char is typed, and max_length = 0 keeps the whole alphabet available
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>w', function()
	flash.jump({
		search = { mode = 'search', max_length = 0 },
		label = { after = { 0, 0 } },
		pattern = [[\<]],
	})
end, { silent = true, desc = 'Flash to word' })

-- same trick for lines; flash has no line mode
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>S', function()
	flash.jump({
		search = { mode = 'search', max_length = 0 },
		label = { after = { 0, 0 } },
		pattern = '^',
	})
end, { silent = true, desc = 'Flash to line' })
