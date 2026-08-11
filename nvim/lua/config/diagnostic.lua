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

-- No vim.lsp.with() handler wrappers here -- deprecated, gone in 0.13. Popup
-- borders come from the hover keymap (config/lsp.lua) and noice's
-- lsp_doc_border preset (config/noice.lua) instead.
