require'hop'.setup()
local hop = require('hop')
local directions = require('hop.hint').HintDirection

vim.keymap.set('', 'f', function()
	hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
end, {remap=true})

vim.keymap.set('', 'F', function()
	hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
end, {remap=true})

vim.keymap.set('', 't', function()
	hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
end, {remap=true})

vim.keymap.set('', 'T', function()
	hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
end, {remap=true})

vim.api.nvim_command('highlight HopUnmatched guifg=none guibg=none guisp=none ctermfg=none')

vim.keymap.set('n', '<leader>s', '<cmd>HopChar1<cr>', {silent = true, noremap = true})
vim.keymap.set('v', '<leader>s', '<cmd>HopChar1<cr>', {silent = true, noremap = true})

vim.keymap.set('n', '<leader>S', '<cmd>HopLine<cr>', {silent = true, noremap = true})
vim.keymap.set('v', '<leader>S', '<cmd>HopLine<cr>', {silent = true, noremap = true})
