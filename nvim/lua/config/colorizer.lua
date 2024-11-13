require('colorizer').setup()

vim.cmd([[
	augroup colorizer
		autocmd!
		autocmd BufEnter * ColorizerToggle
	augroup END
]])
