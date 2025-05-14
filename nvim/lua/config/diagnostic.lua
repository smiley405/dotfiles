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

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })
