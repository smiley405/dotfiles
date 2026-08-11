-- noice.nvim: used only for the UI that nvim-cmp does not cover -- the
-- command line and the LSP popups. Ordinary vim messages are deliberately
-- left alone (messages.enabled = false) so they keep going to the cmdline
-- as before; that avoids turning routine chatter into toasts and removes
-- any need to blacklist it. vim.notify() still renders as a toast, so
-- plugins that raise something genuinely important are still seen.

-- bail out quietly on a fresh clone, before :PlugInstall has run, instead of
-- aborting the whole init.lua with a module-not-found error
local ok_noice, noice = pcall(require, 'noice')
if not ok_noice then
	vim.notify('noice.nvim missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

-- toasts are rendered by the snacks notifier, configured in config/snacks.lua

noice.setup({
	-- leave :messages, echo and friends to vim
	messages = { enabled = false },

	lsp = {
		-- render LSP markdown through noice so hover, signature help and the
		-- cmp documentation window share one look instead of three
		override = {
			['vim.lsp.util.convert_input_to_markdown_lines'] = true,
			['vim.lsp.util.stylize_markdown'] = true,
			['cmp.entry.get_documentation'] = true,
		},
		hover = {
			enabled = true,
			-- noice replaces the hover handler with a per-client one, so every
			-- attached server with no hover data adds its own 'No information
			-- available' - that is the 'x2' on ts_ls + eslint buffers
			silent = true,
		},
		signature = { enabled = true },
		progress = { enabled = true },
	},

	views = {
		-- the 'mini' float (used by lsp.progress) anchors to row -1, which lands
		-- on the lualine statusline and blends over it -- 'Loading workspace'
		-- printed on top of the status bar on every LSP start. Lift it clear.
		mini = {
			position = { row = -2 },
		},
	},

	presets = {
		-- centered command palette, the most recognisably VSCode bit
		command_palette = true,
		-- bordered hover/signature windows, matching the completion popup
		lsp_doc_border = true,
	},
})
