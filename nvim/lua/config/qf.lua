vim.cmd([[
    hi BqfPreviewBorder guifg=#3e8e2d ctermfg=71
    hi BqfPreviewTitle guifg=#3e8e2d ctermfg=71
    hi BqfPreviewThumb guibg=#3e8e2d ctermbg=71
    hi link BqfPreviewRange Search

	augroup quickfix
		autocmd!
		autocmd FileType qf setlocal wrap | wincmd J
	augroup END
]])

-- Lua rather than `noremap` in the block above so it can carry a desc: oil
-- shadows this key buffer-locally, and which-key gives a wk.add() spec entry
-- precedence over a mapping's own desc -- so a spec label here would show
-- 'Close quickfix' inside oil buffers too. Mode '' matches :noremap (n/v/o).
vim.keymap.set('', '<leader>q', '<cmd>ccl<CR>',
	{ silent = true, desc = 'Close quickfix' })

require('bqf').setup({
	auto_enable = true,
	auto_resize_height = true, -- highly recommended enable
	preview = {
		win_height = 12,
		win_vheight = 12,
		delay_syntax = 80,
		border = { '┏', '━', '┓', '┃', '┛', '━', '┗', '┃' },
		show_title = false,
		should_preview_cb = function(bufnr, qwinid)
			local ret = true
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			local fsize = vim.fn.getfsize(bufname)
			if fsize > 100 * 1024 then
				-- skip file size greater than 100k
				ret = false
			elseif bufname:match('^fugitive://') then
				-- skip fugitive buffer
				ret = false
			end
			return ret
		end
	},
})
