-- Used only for the cmdline and LSP popups. Ordinary vim messages are left
-- alone (messages.enabled = false); vim.notify() still renders as a toast.
local noice = require('noice')

-- toasts render through the snacks notifier (config/snacks.lua)

noice.setup({
	-- leave :messages, echo and friends to vim
	messages = { enabled = false },

	lsp = {
		-- one look across hover, signature help and the cmp docs window
		override = {
			['vim.lsp.util.convert_input_to_markdown_lines'] = true,
			['vim.lsp.util.stylize_markdown'] = true,
			['cmp.entry.get_documentation'] = true,
		},
		hover = {
			enabled = true,
			-- else every attached server with no hover data adds its own
			-- 'No information available' (the 'x2' on ts_ls + eslint buffers)
			silent = true,
		},
		signature = { enabled = true },
		progress = { enabled = true },
	},

	views = {
		-- row -1 lands on the lualine statusline; lift it clear
		mini = {
			position = { row = -2 },
		},

		-- Native ins-completion (<C-n>, <C-p>, <C-x>...) renders through this
		-- view. It ships border padding but no style, so nui drew it flat; only
		-- cmdline_popupmenu got a border, from the command_palette preset.
		popupmenu = {
			border = {
				style = 'rounded',
				padding = { 0, 1 },
			},
		},
	},

	presets = {
		-- centered command palette
		command_palette = true,
		-- bordered hover/signature windows, matching the completion popup
		lsp_doc_border = true,
	},
})
