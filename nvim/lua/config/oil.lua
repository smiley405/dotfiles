-- delete_to_trash needs a trash CLI: `trash-put` on linux, npm `trash` on
-- windows (https://www.npmjs.com/package/trash). Set trash_command to match.

require("oil").setup({
	-- :help oil-columns (id and name are always present)
	columns = {
		-- "icon",
		-- "permissions",
		-- "size",
		-- "mtime",
	},
	buf_options = {
		buflisted = false,
		bufhidden = "hide",
	},
	win_options = {
		wrap = false,
		signcolumn = "no",
		cursorcolumn = false,
		foldcolumn = "0",
		spell = false,
		list = false,
		conceallevel = 3,
		concealcursor = "n",
	},
	-- false: neo-tree handles directory buffers (`vim .`, `:e src/`)
	default_file_explorer = false,
	restore_win_options = true,
	skip_confirm_for_simple_edits = false,
	delete_to_trash = true,
	-- trash_command = "trash",
	prompt_save_on_select_new_entry = true,
	-- :help oil-actions for the full list
	keymaps = {
		["g?"] = "actions.show_help",
		-- ["<CR>"] = "actions.select",
		["<C-s>"] = "actions.select_vsplit",
		["<C-h>"] = "actions.select_split",
		["<C-t>"] = "actions.select_tab",
		["<C-p>"] = "actions.preview",
		["<C-c>"] = "actions.close",
		["<C-l>"] = "actions.refresh",
		-- ["-"] = "actions.parent",
		-- ["_"] = "actions.open_cwd",
		["cd"] = "actions.cd",
		["~"] = "actions.tcd", -- use :e afterwards to refresh changes relative to pwd
		["g."] = "actions.toggle_hidden",
		["y."] = "actions.copy_entry_path",
		--["!"] = "actions.open_cmdline",
		-- ["q"] = "actions.close",
	},
	use_default_keymaps = true,
	view_options = {
		show_hidden = false,
		is_hidden_file = function(name, bufnr)
			return vim.startswith(name, ".")
		end,
		-- never shown, even when show_hidden is set
		is_always_hidden = function(name, bufnr)
			return false
		end,
	},
	-- oil.open_float
	float = {
		padding = 2,
		max_width = 0,
		max_height = 0,
		border = "rounded",
		win_options = {
			winblend = 10,
		},
	},
	-- Sizes are columns when >= 1, a fraction of the screen when < 1. A pair
	-- {40, 0.4} means "the greater of the two" for min_*, "the lesser" for max_*.
	preview = {
		max_width = 0.9,
		min_width = { 40, 0.4 },
		width = nil,
		max_height = 0.9,
		min_height = { 5, 0.1 },
		height = nil,
		border = "rounded",
		win_options = {
			winblend = 0,
		},
	},
	progress = {
		max_width = 0.9,
		min_width = { 40, 0.4 },
		width = nil,
		max_height = { 10, 0.9 },
		min_height = { 5, 0.1 },
		height = nil,
		border = "rounded",
		minimized_border = "none",
		win_options = {
			winblend = 0,
		},
	},
})

-- vim.keymap.set("n", "_", require("oil").open, { desc = "Open parent directory" })

require("oil").toggle_hidden()

vim.cmd [[
	"--- use only on ft=oil

	function! OpenOil()
		let s:file = expand('<cfile>')

		exe 'lua require("oil").open()'

		" highlight file_name
		let @/ = s:file
		call feedkeys(":let &hlsearch=1 \| echo \<CR>", "n")

	endfunction

	function! QuitOil()
		let s:oil_full_path = expand('%:p')
		let s:raw_full_path = substitute(s:oil_full_path, 'oil:\/\/', '', '')

		let s:file = expand('<cfile>')

		exe 'lua require("oil").close()'

		" restore netrw to current oil browsed directory path before exit
		if &ft ==# 'netrw'
			exe 'Explore' s:raw_full_path

			"-- @see: https://superuser.com/questions/578231/vim-how-do-you-highlight-a-search-pattern-from-script
			"-- @see: https://stackoverflow.com/questions/63669165/how-to-vim-script-to-execute-commands-in-function
			"-- search "let" word: exe "normal! \/let\<CR>"
			"-- or, search "let" word: exe "normal! \/let\<CR>"
			"-- or, search "let" word: exe "normal! \/"."let"."\<CR>"
			"-- jump back to same cursor line on netrw
			exe "normal! \/".s:file."\<CR>"
			call feedkeys(":set nohlsearch \| echo \<CR>", "n")
		endif
	endfunction

]]

-- Buffer-local, not `nnoremap` inside a FileType autocmd -- those were global
-- maps rebound on every oil buffer, so opening oil once left <leader>q calling
-- QuitOil() everywhere else. The desc makes which-key show the oil meaning.
local group = vim.api.nvim_create_augroup('set_oil_key_map', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
	group = group,
	pattern = 'oil',
	callback = function(event)
		local opts = { buffer = event.buf, silent = true }

		vim.keymap.set('n', '.', function()
			print(require('oil').get_current_dir())
		end, vim.tbl_extend('force', opts, { desc = 'Print oil directory' }))

		vim.keymap.set('n', '<leader>q', '<cmd>call QuitOil()<CR>',
			vim.tbl_extend('force', opts, { desc = 'Close oil' }))
	end,
})

vim.api.nvim_create_autocmd('FileType', {
	group = group,
	pattern = 'netrw',
	callback = function(event)
		vim.keymap.set('n', '_', '<cmd>call OpenOil()<CR>',
			{ buffer = event.buf, silent = true, desc = 'Open oil here' })
	end,
})
