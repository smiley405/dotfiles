-- made it similar to vscode tree explorer and features
require("neo-tree").setup({
	-- General
	close_if_last_window = true,
	popup_border_style = "rounded",

	enable_git_status = true,
	enable_diagnostics = true,

	open_files_do_not_replace_types = {
		"terminal",
		"trouble",
		"qf",
	},

	-- Sources
	sources = {
		"filesystem",
		"buffers",
		"git_status",
		"document_symbols",
	},

	-- Source selector
	source_selector = {
		winbar = true,
		statusline = false,

		content_layout = "center",
		tabs_layout = "equal",

		sources = {
			{
				source = "filesystem",
				display_name = "󰉓 Files",
			},
			{
				source = "buffers",
				display_name = "󰈔 Buffers",
			},
			{
				source = "git_status",
				display_name = "󰊢 Git",
			},
			{
				source = "document_symbols",
				display_name = "󰌗 Symbols",
			},
		},
	},

	-- Filesystem
	filesystem = {
		-- Follow the file currently being edited
		follow_current_file = {
			enabled = true,
			leave_dirs_open = false,
		},

		-- Automatically update when files change
		use_libuv_file_watcher = true,

		-- Replace netrw
		hijack_netrw_behavior = "open_default",

		-- Explorer filtering
		filtered_items = {
			visible = false,
			hide_dotfiles = false,
			hide_gitignored = true,
			hide_hidden = false,
		},

		window = {
			position = "left",
			width = 35,

			mappings = {
				-- Navigation
				["<cr>"] = "open",
				["o"] = "open",
				["<2-LeftMouse>"] = "open",
				["<space>"] = "toggle_node",
				["-"] = "navigate_up",

				-- Open in splits
				["<C-v>"] = "open_vsplit",
				["<C-x>"] = "open_split",

				-- Preview
				["P"] = "toggle_preview",

				-- Explorer
				["R"] = "refresh",
				["H"] = "toggle_hidden",

				-- Switch between sources
				["<"] = "prev_source",
				[">"] = "next_source",

				-- File operations
				["a"] = "add",
				["A"] = "add_directory",
				["d"] = "delete",
				["r"] = "rename",
				["c"] = "copy",
				["m"] = "move",

				-- Clipboard
				["y"] = "copy_to_clipboard",
				["x"] = "cut_to_clipboard",
				["p"] = "paste_from_clipboard",

				-- Window
				["q"] = "close_window",
				["<esc>"] = "close_window",
			},
		},
	},

	-- Buffers
	buffers = {
		follow_current_file = {
			enabled = true,
			leave_dirs_open = false,
		},

		group_empty_dirs = true,

		window = {
			position = "left",
			width = 35,
		},
	},

	-- Git status
	git_status = {
		window = {
			position = "left",
			width = 35,
		},
	},

	-- Document symbols
	document_symbols = {
		follow_cursor = true,

		window = {
			position = "left",
			width = 35,
		},
	},

	-- Visual components
	default_component_configs = {
		-- Indentation
		indent = {
			indent_size = 2,
			padding = 1,
			with_markers = true,

			indent_marker = "│",
			last_indent_marker = "└",

			expander_collapsed = "",
			expander_expanded = "",
		},

		-- Icons
		icon = {
			folder_closed = "",
			folder_open = "",
			folder_empty = "",
			default = "",
		},

		-- Modified files
		modified = {
			symbol = "●",
		},

		-- Git
		git_status = {
			symbols = {
				added = "✚",
				modified = "●",
				deleted = "✖",
				renamed = "➜",
				untracked = "★",
				ignored = "◌",
				unstaged = "✗",
				staged = "✓",
				conflict = "",
			},
		},

		-- Diagnostics
		diagnostics = {
			symbols = {
				hint = "󰌵",
				info = "",
				warn = "",
				error = "",
			},
		},

		-- Use Git colors for filenames
		name = {
			use_git_status_colors = true,
		},
	},
})

-- Neo-tree keymaps

-- Toggle Explorer
vim.keymap.set("n", "<leader>n", "<cmd>Neotree toggle<CR>", {
	silent = true,
	desc = "Neo-tree: toggle explorer",
})

-- Reveal current file
vim.keymap.set("n", "<leader>nf", "<cmd>Neotree reveal<CR>", {
	silent = true,
	desc = "Neo-tree: reveal current file",
})

-- Focus Explorer
vim.keymap.set("n", "<leader>no", "<cmd>Neotree focus<CR>", {
	silent = true,
	desc = "Neo-tree: focus explorer",
})
