vim.keymap.set('n', '<leader>ff', '<cmd>Files<CR>', {})
vim.keymap.set('n', '<leader>fb', '<cmd>Buffers<CR>', {})
vim.keymap.set('n', '<leader>fw', '<cmd>Windows<CR>', {})
vim.keymap.set('n', '<leader>fj', '<cmd>Jumps<CR>', {})
vim.keymap.set('n', '<leader>fm', '<cmd>Marks<CR>', {})

vim.cmd([[
	let g:fzf_preview_window = []
	let $FZF_DEFAULT_COMMAND='fd -L -t f -H -I -E "{node_modules,.git}"'
	let g:fzf_layout = { 'down': '40%' }
	command! -bang -nargs=* Rg call fzf#vim#grep("rg --column --line-number --no-heading --color=always ".<q-args>, 1, <bang>0)

	" to disable .gitignore or .ignore files add -u
	" see: https://github.com/BurntSushi/ripgrep/issues/23

	" to debug rg, see: https://github.com/BurntSushi/ripgrep/issues/1927

	nnoremap <Leader>fg :Rg -g "!{*-lock.json,*.lock.json,*.lock,*.log,*.min.js,*.map,*.csv,temp,builds,build,Export,out}" -S<Space>
]])
