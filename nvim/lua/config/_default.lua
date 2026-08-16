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

vim.opt.backupdir = vim.fn.expand('~/.vim/backup')
vim.opt.directory = vim.fn.expand('~/.vim/swp')

vim.opt.backup = false
vim.opt.writebackup = false

-- default is 4000ms, which makes CursorHold-driven UI feel dead
vim.opt.updatetime = 100

-- always on, so text does not shift when diagnostics appear
vim.opt.signcolumn = 'yes'

vim.opt.foldmethod = 'manual'
vim.opt.foldenable = true

vim.opt.termguicolors = true

-- Name the buffer in the terminal's tab, the way an editor tab names a file.
-- The `nvim: ` prefix is a contract with wezterm/wezterm.lua, which reads it
-- for the tab icon: under WSL every pane reports wslhost.exe, so the title is
-- the only thing that says what is actually running in there.
vim.opt.title = true
vim.opt.titlestring = 'nvim: %t'

-- WSL only: nvim's clipboard probe scans $PATH for every tool it misses, and
-- the /mnt/c entries make that ~190ms of every startup. Naming the provider
-- skips the probe (`:h g:clipboard`). Gated, because elsewhere the probe is
-- cheap and right -- Fedora wants wl-copy on wayland, Windows win32yank. Name
-- 'wl-copy' here instead if wl-clipboard ever lands on this box.
if vim.fn.has('wsl') == 1
	and (vim.env.DISPLAY or '') ~= ''
	and vim.fn.executable('xclip') == 1 then
	vim.g.clipboard = 'xclip'
end

vim.opt.clipboard = "unnamedplus"

vim.cmd([[
	let mapleader = "\<Space>"
	set nofixendofline

	augroup highlight_yank
		autocmd!
		autocmd TextYankPost * silent! lua vim.hl.on_yank {higroup="IncSearch", timeout=150}
	augroup END
]])
