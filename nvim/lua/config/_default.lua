vim.opt.encoding = 'utf-8'
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.number = true
vim.opt.relativenumber = false

-- dont wrap lines
vim.opt.wrap = true
-- wrap lines at convenient points
vim.opt.linebreak = true
-- wrap lines such that vertical indent is not broken
vim.opt.breakindent = true

vim.o.formatoptions = 'jcroql'
vim.opt.ts = 4
vim.opt.sw = 4
vim.opt.re = 0
-- vim.opt.cursorline = true

vim.opt.backupdir = vim.fn.expand('~/.vim/backup')
vim.opt.directory = vim.fn.expand('~/.vim/swp')
vim.opt.shadafile = 'NONE'

-- Some servers have issues with backup files, see #649.
vim.opt.backup = false
vim.opt.writebackup = false

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 100

-- Always show the signcolumn, otherwise it would shift the text each time
-- diagnostics appear/become resolved.
vim.opt.signcolumn = 'yes'

vim.opt.foldmethod = 'manual'
vim.opt.foldenable = true

vim.opt.termguicolors = true
-- vim.opt.clipboard:append { 'unnamed', 'unnamedplus' }

vim.cmd([[
	let mapleader = "\<Space>"
	set nofixendofline

	augroup highlight_yank
		autocmd!
		autocmd TextYankPost * silent! lua vim.highlight.on_yank {higroup="IncSearch", timeout=150}
	augroup END
]])

