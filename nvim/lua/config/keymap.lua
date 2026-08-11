function map(mode, shortcut, command)
	vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = true, silent = true })
end

map('n', '<leader>h', '<cmd>noh<CR>')

vim.cmd([[
	"@see: https://balazshobbies.wordpress.com/vim-jegyzetek/napi-vim-bemelegito/vim-map-remap-nnoremap/

	function! CopyEchoCWD()
		" copy & display pwd to clipboard
		let l:cwd = getcwd()
		echo 'Copied! ' .. l:cwd | let @+=getcwd()
	endfunction

	function! CopyEchoFullOpenedFilePath()
		let l:dir = expand('%:p')

		if l:dir !=''
			echo 'Copied! ' .. expand('%:p')
			let @+=expand('%:p')
		endif
	endfunction

	function! CopyEchoFullDirPath()
		let l:dir = expand('%:p:h')
		echo 'Copied! ' .. l:dir
		let @+=l:dir
	endfunction

	function! CopyEchoOpenedFileName()
		let l:fileName = expand('%:t')

		if l:fileName !=''
			echo 'Copied! ' .. l:fileName
			let @+=l:fileName
		endif
	endfunction

	nnoremap <silent> <leader>p :call CopyEchoCWD()<CR>
	nnoremap <silent> <leader>tN :tabnew<CR>
	nnoremap <silent> <leader>tn :tab split<CR>
	nnoremap <silent> <leader>tc :tabc<CR>
	" close tabs to the right
	nnoremap <silent> <leader>to :.+1,$tabdo :tabc<CR>
	nnoremap <silent> <leader>tO :.-1,1tabdo :tabc<CR>
	nnoremap <silent> <leader>r :set relativenumber!<CR>
	" search pattern and add it quick fix list ie. :vimgrep /pattern/ % | copen
	nnoremap <silent> <leader>fs :vimgrep // % <bar> copen<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><C-n>

	" return to previous tab on close
	augroup tabc-behaviour
		autocmd! *
		autocmd TabClosed * tabprevious
	augroup END
]])

-- Lua rather than `nnoremap` in the block above so these can carry a desc:
-- netrw shadows all three buffer-locally with an under-the-cursor variant, and
-- which-key gives a wk.add() spec entry precedence over a mapping's own desc --
-- so a spec label here would describe the wrong behaviour inside netrw.
vim.keymap.set('n', '<leader>,', '<cmd>call CopyEchoOpenedFileName()<CR>',
	{ silent = true, desc = 'Copy file name' })
vim.keymap.set('n', '<leader>.', '<cmd>call CopyEchoFullOpenedFilePath()<CR>',
	{ silent = true, desc = 'Copy full file path' })
vim.keymap.set('n', '<leader>/', '<cmd>call CopyEchoFullDirPath()<CR>',
	{ silent = true, desc = 'Copy directory path' })
