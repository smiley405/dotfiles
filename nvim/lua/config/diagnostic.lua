local signs = { Error = 'E ', Warn = 'W ', Hint = 'H ', Info = 'I ' }

for type, icon in pairs(signs) do
	local hl = 'DiagnosticSign' .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
end

vim.diagnostic.config({
	virtual_text = false,
	update_in_insert = false,
	severity_sort = true,
	float = {
	  focused = false,
	  style = 'minimal',
	  border = 'rounded',
	  source = 'always',
	  header = '',
	  prefix = '',
	},
})

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })
