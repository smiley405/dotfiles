-- made it similar to vscode tree explorer and features
require("neo-tree").setup({
	-- General
	close_if_last_window = true,
	popup_border_style = "rounded",

	enable_git_status = true,
	enable_diagnostics = true,

	-- Update imports on move/rename. snacks sends workspace/willRenameFiles so
	-- the language server rewrites every import before the file moves.
	event_handlers = {
		{
			event = "file_moved",
			handler = function(data)
				Snacks.rename.on_rename_file(data.source, data.destination)
			end,
		},
		{
			event = "file_renamed",
			handler = function(data)
				Snacks.rename.on_rename_file(data.source, data.destination)
			end,
		},
	},

	open_files_do_not_replace_types = {
		"terminal",
		"trouble",
		"qf",
	},

	-- Base mappings; the per-source `window.mappings` below merge over these.
	window = {
		mappings = {
			-- Unbind source switching: filesystem is the only source, so these
			-- just rebuild it from scratch onto itself. Must be overridden --
			-- deleting the entries leaves neo-tree's defaults in place.
			["<"] = "noop",
			[">"] = "noop",

			-- Free up <space>: neo-tree binds it to toggle_node, which shadows
			-- every <leader> mapping inside the tree. Nothing replaces it --
			-- o and <cr> already expand folders.
			["<space>"] = "noop",

			-- Hand z back to vim. neo-tree binds bare z to close_all_nodes, so the
			-- first keystroke of zz collapses the whole tree and the scroll never
			-- happens. "noop" skips the keymap entirely rather than binding an
			-- empty function, so z stays a native prefix and zz/zt/zb behave as in
			-- any other buffer. close_all_nodes moves to Z, which ships unbound.
			["z"] = "noop",
			["Z"] = "close_all_nodes",
		},
	},

	-- Sources: file tree only. The other three are covered better elsewhere
	-- (<leader>o symbols, <leader>fb buffers, <leader>gc git), and switching
	-- rebuilt the target source from scratch on every press.
	--
	-- source_selector omitted, so no winbar is drawn. enable_git_status above
	-- is unrelated -- that is the git symbol per file, not a tab.
	sources = {
		"filesystem",
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
			-- Show gitignored/.ignore/.DS_Store from the start, but dimmed.
			-- H toggles them back off for the session.
			visible = true,
			hide_dotfiles = false,
			hide_gitignored = true,
			hide_hidden = false,
		},

		window = {
			position = "left",
			width = 35,

			mappings = {
				-- Navigation (open toggles directories -- see window.mappings)
				["<cr>"] = "open",
				["o"] = "open",
				["<2-LeftMouse>"] = "open",
				["-"] = "navigate_up",

				-- Open in splits
				["<C-v>"] = "open_vsplit",
				["<C-x>"] = "open_split",

				-- Preview
				["P"] = "toggle_preview",

				-- Explorer
				["R"] = "refresh",
				["H"] = "toggle_hidden",

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

-- Toggle Explorer.
--
-- <leader>nn, not <leader>n: a mapping on the same key as the nf/no prefix
-- would fire on 'timeoutlen' while the which-key popup is still being read.
-- Keeping <leader>n a pure prefix makes the popup wait for the next key.
vim.keymap.set("n", "<leader>nn", "<cmd>Neotree toggle<CR>", {
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
