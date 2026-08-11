vim.diagnostic.config({
	virtual_text = false,
	update_in_insert = false,
	severity_sort = true,
	float = {
		focused = false,
		style = 'minimal',
		border = 'rounded',
		-- 'always' was dropped in 0.11; boolean|'if_many' now
		source = true,
		header = '',
		prefix = '',
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = 'E',
			[vim.diagnostic.severity.WARN] = 'W',
			[vim.diagnostic.severity.INFO] = 'I',
			[vim.diagnostic.severity.HINT] = 'H',
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = '',
			[vim.diagnostic.severity.WARN] = '',
			[vim.diagnostic.severity.HINT] = '',
			[vim.diagnostic.severity.INFO] = '',
		},
	},
})

-- Diagnostics as a list. virtual_text is off above, so <leader>e -- one float
-- at a time -- was the only way to read them. Built-ins, landing in the
-- quickfix window nvim-bqf already styles (config/qf.lua). Both are snapshots,
-- and long ts_ls messages are cut to their first line.
vim.keymap.set('n', '<leader>xx', vim.diagnostic.setqflist,
	{ desc = 'Diagnostics (workspace) -> quickfix' })
vim.keymap.set('n', '<leader>xX', vim.diagnostic.setloclist,
	{ desc = 'Diagnostics (buffer) -> loclist' })

-- No vim.lsp.with() handler wrappers here -- deprecated, gone in 0.13. Popup
-- borders come from the hover keymap (config/lsp.lua) and noice's
-- lsp_doc_border preset (config/noice.lua) instead.
