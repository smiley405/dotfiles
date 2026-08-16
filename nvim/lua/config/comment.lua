-- nvim has built-in gc/gcc since 0.10 and picks the commentstring from the
-- treesitter language under the cursor, so no plugin is involved. Only the
-- filetypes nvim ships no ftplugin for need one set by hand.
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'haxe', 'actionscript' },
	desc = 'commentstring for filetypes nvim does not ship one for',
	callback = function()
		vim.bo.commentstring = '// %s'
	end,
})
