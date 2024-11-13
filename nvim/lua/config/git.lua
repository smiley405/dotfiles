require('gitsigns').setup({
	current_line_blame = true,
	--current_line_blame_formatter = '<author>, <committer_time:%R>, <author_time:%Y-%m-%d> - <summary>',
	current_line_blame_formatter = '<author>, <author_time:%R> • <summary>',
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navigation
		map('n', ']c', function()
			if vim.wo.diff then return ']c' end
			vim.schedule(function() gs.next_hunk() end)
			return '<Ignore>'
		end, {expr=true})

		map('n', '[c', function()
			if vim.wo.diff then return '[c' end
			vim.schedule(function() gs.prev_hunk() end)
			return '<Ignore>'
		end, {expr=true})

		-- Actions
		map('n', '<leader>vh', gs.preview_hunk)
	end
})

vim.cmd([[
let g:fugitive_summary_format = "%s --> %an ( %cr, %cD )"
noremap <silent> <leader>gd :Gvdiffsplit<CR>
noremap <silent> <leader>gb :G blame<CR>
noremap <silent> <leader>gc :G<CR>

augroup au_git
	autocmd!
	autocmd Filetype git silent! setlocal foldmethod=syntax
augroup END

let g:mergetool_layout = 'rl,m'
let g:mergetool_prefer_revision = 'local'
nmap <leader>gm <plug>(MergetoolToggle)

" to resolve merge, use :diffget or :diffput
" to resolve only selected line or range,
" y to yank and p to paste the selected commit line or range
]])
