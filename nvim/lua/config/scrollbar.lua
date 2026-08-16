local excluded_filetypes = {
	'git',
	-- nvim as $EDITOR for `git commit`
	'gitcommit',
	'no ft',
	'netrw',
	'undotree',
	'qf',
	'vim-plug',
	'snacks_picker_list',
}

-- false positive: lua_ls cannot see through this module's `local M = {}`
-- indirection. setup exists (scrollbar/init.lua).
---@diagnostic disable-next-line: undefined-field
require('scrollbar').setup({
	excluded_filetypes = excluded_filetypes,
	handle = {
		text = "┆",
	},
	handlers = {
		cursor = false,
		diagnostic = false,
		gitsigns = true, -- Requires gitsigns
		handle = true,
		search = false, -- Requires hlslens
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
	}
})
