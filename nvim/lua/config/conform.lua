local conform = require('conform')

conform.setup({
		formatters_by_ft = {
			-- lua = { "stylua" },
			-- Conform will run multiple formatters sequentially
			-- python = { "isort", "black" },
			-- Use a sub-list to run only the first available formatter
			javascript = { "eslint", },
			javascriptreact = { "eslint", },
			typescript = { "eslint", "tsserver",},
			typescriptreact = { "eslint", "tsserver", },
			lua =  { 'lua-ls' }
		},
		notify_on_error = true,
	})

vim.keymap.set({ 'n', 'v' }, ',fc', function()
	conform.format({ async = true, lsp_fallback = false })
end)
