vim.diagnostic.config({
		virtual_text = false,
		update_in_insert = false,
		severity_sort = true,
		float = {
			focused = false,
			style = 'minimal',
			border = 'rounded',
			-- 'always' was dropped in 0.11; the field is boolean|'if_many' now
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

-- Bordered hover/signature popups used to be wired up here by wrapping the
-- stock handlers with vim.lsp.with(). All three of those APIs (vim.lsp.with,
-- vim.lsp.handlers.hover, vim.lsp.handlers.signature_help) are deprecated and
-- go away in 0.13 -- calling them printed a deprecation notice on every start.
--
-- The border is passed per-call instead: hover at its keymap in config/lsp.lua,
-- and signature help by noice (presets.lsp_doc_border in config/noice.lua),
-- which is what actually renders both popups here anyway.
