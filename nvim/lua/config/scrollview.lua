local excluded_filetypes = {
	'git',
	'fugitive',
	'no ft',
	'netrw',
	'undotree',
	'qf',
	'vim-plug',
	'oil',
}

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

