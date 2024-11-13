vim.cmd([[
	let g:netrw_banner = 0
	let g:netrw_sizestyle= 'h'

	"@see: fern.vim for more customization

	function! CopyEchoCursorFile()
		let l:file = expand('<cfile>')

		echo 'Copied! ' .. l:file
		let @+=l:file
	endfunction

	function! CopyEchoFullFilePath()
		let l:cwd = getcwd()
		let l:dir = expand('%:p')

		" current file at cursor
		let l:file = expand('<cfile>')
		let l:full_path = l:dir != '' ? l:dir .. l:file : l:cwd .. '\' .. l:file

		echo 'Copied! ' .. l:full_path
		let @+=l:full_path
	endfunction

	function! EchoFullDirPath()
		let l:cwd = getcwd()
		let l:dir = expand('%:p')
		let l:out = l:dir != '' ? l:dir : l:cwd
		echo l:out
	endfunction

	function! CopyEchoFullDirPath()
		let l:cwd = getcwd()
		let l:dir = expand('%:p')
		let l:out = l:dir != '' ? l:dir : l:cwd
		echo 'Copied! ' .. l:out
		let @+=l:out
	endfunction

	" highlight current opened file in netrw with quich search
	"
	" with highlighting
	" nnoremap <silent> _ :Ex <bar> :sil! /<C-R>=expand("%:t")<CR><CR>

	" without highlight
	nnoremap <silent> - :Ex <bar> :sil! /<C-R>=expand("%:t")<CR><CR><bar>:noh<CR><bar>:call EchoFullDirPath()<CR>

	"https://vi.stackexchange.com/questions/22653/explicitly-call-netrw-function-in-binding
	" nmap <expr> = &ft ==# 'netrw' ? "\<Plug>NetrwBrowseUpDir" : '='

	function! s:init_netrw() abort
		"@see: https://github.com/vim/vim/blob/v8.2.0/runtime/autoload/netrw.vim#L6377

		nmap <buffer> - <Plug>NetrwBrowseUpDir <bar> :call EchoFullDirPath()<CR>
		nmap <buffer> <CR> <Plug>NetrwLocalBrowseCheck <bar> :call EchoFullDirPath()<CR>
		nnoremap <buffer> <silent> <leader>, :call CopyEchoCursorFile()<CR>
		nnoremap <buffer> <silent> <leader>. :call CopyEchoFullFilePath()<CR>
		nnoremap <buffer> <silent> <leader>/ :call CopyEchoFullDirPath()<CR>
	endfunction

	augroup my-netrw
		autocmd! *
		autocmd FileType netrw call s:init_netrw()
	augroup END
]])
