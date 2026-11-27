-- nvim-scrollbar v2 option shape; v1 tables (handle, handlers,
-- excluded_filetypes) fail setup. See the plugin's docs/migration.md.

-- false positive: lua_ls cannot see through this module's `local M = {}`
-- indirection. setup exists (scrollbar/init.lua).
---@diagnostic disable-next-line: undefined-field
require('scrollbar').setup({
	exclude = {
		-- keyed, not a list: a list would replace the plugin's defaults
		filetypes = {
			git = true,
			-- nvim as $EDITOR for `git commit`
			gitcommit = true,
			['no ft'] = true,
			netrw = true,
			undotree = true,
			qf = true,
			['vim-plug'] = true,
			snacks_picker_list = true,
		},
	},
	-- v2 turns cursor, diagnostic, search and marks on by default
	providers = {
		cursor = false,
		diagnostic = false,
		gitsigns = true, -- Requires gitsigns
		search = false,
		marks = false,
		ale = false, -- Requires ALE
	},
	marks = {
		GitAdd = {
			text = "│",
		},
		GitChange = {
			text = "│",
		},
		GitDelete = {
			text = "-",
		},
	},
	scrollbar = {
		thumb = {
			text = "┆",
		},
	},
})
