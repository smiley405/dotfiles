vim.opt.encoding = 'utf-8'
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.number = true
vim.opt.relativenumber = false

-- soft wrap, breaking at word boundaries and keeping the indent
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

vim.o.formatoptions = 'jcroql'
vim.opt.ts = 4
vim.opt.sw = 4
vim.opt.re = 0
-- vim.opt.cursorline = true

vim.opt.backupdir = vim.fn.expand('~/.vim/backup')
vim.opt.directory = vim.fn.expand('~/.vim/swp')
-- vim.opt.shadafile = 'NONE'

-- Some servers have issues with backup files, see #649.
vim.opt.backup = false
vim.opt.writebackup = false

-- default is 4000ms, which makes CursorHold-driven UI feel dead
vim.opt.updatetime = 100

-- always on, so text does not shift when diagnostics appear
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
		autocmd TextYankPost * silent! lua vim.hl.on_yank {higroup="IncSearch", timeout=150}
	augroup END
]])
