-- made it similar to vscode tree explorer and features
require("neo-tree").setup({
	-- General
	close_if_last_window = true,
	popup_border_style = "rounded",

	enable_git_status = true,
	enable_diagnostics = true,

	-- renaming or moving a file in the tree used to silently break every
	-- import of it. Hand the old/new path to snacks, which sends
	-- workspace/willRenameFiles so the language server rewrites those imports
	-- first -- VSCode's 'update imports on file move'.
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

	-- Applies to the file tree, which the per-source `window.mappings`
	-- below are merged over.
	window = {
		mappings = {
			-- filesystem is the only source now, but neo-tree's own defaults
			-- still bind these -- and with nothing to switch to they just
			-- re-navigate filesystem onto itself, i.e. a full rebuild for
			-- nothing. Deleting our entries was not enough; they have to be
			-- overridden.
			["<"] = "noop",
			[">"] = "noop",

			-- neo-tree binds <space> to toggle_node by default, and <space>
			-- is the leader key -- so inside the tree it shadowed every
			-- <leader> mapping and which-key's popup never opened there.
			--
			-- Nothing replaces it: `open` calls toggle_node for directory
			-- nodes (sources/common/commands.lua), so o and <cr> already
			-- expand and collapse folders. This only removes the duplicate,
			-- and leaves neo-tree's <Tab> (multi-select) alone.
			["<space>"] = "noop",
		},
	},

	-- Sources
	--
	-- Just the file tree, no tab bar. Switching sources was never cheap:
	-- < and > rebuild the target source from scratch every press
	-- (sources/common/commands.lua), and document_symbols additionally
	-- blocked on a textDocument/documentSymbol request, rendering nothing
	-- until the server answered. The other three are covered better
	-- elsewhere -- <leader>o for symbols (outline.nvim), <leader>fb for
	-- buffers (fzf), <leader>gc for git (fugitive).
	--
	-- source_selector is omitted entirely, so no winbar is drawn.
	-- enable_git_status above is unrelated and stays: that is the git
	-- symbol next to each file, not a tab.
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
			-- show filtered items (gitignored, .ignore matches, .DS_Store)
			-- from the start, dimmed rather than as normal entries so they
			-- still read as ignored. H toggles them back off per session.
			visible = true,
			hide_dotfiles = false,
			hide_gitignored = true,
			hide_hidden = false,
		},

		window = {
			position = "left",
			width = 35,

			mappings = {
				-- Navigation
				-- open toggles the node when it is a directory, so these
				-- cover what <space> used to do (see window.mappings above)
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

-- Toggle Explorer
--
-- <leader>nn, not <leader>n: a mapping sitting on the same key as the nf/no
-- prefix means which-key's popup opens at 300ms and then 'timeoutlen' fires
-- the toggle out from under it while you are still reading. With <leader>n
-- left as a pure prefix, the popup waits for the next key instead.
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
