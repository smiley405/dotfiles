-- Pickers for files, buffers, windows, jumps and marks. Grep is deliberately
-- absent -- that is config/grugfar.lua, which owns the glob exclusion list.
local ok, telescope = pcall(require, 'telescope')
if not ok then
	vim.notify('telescope.nvim missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

-- -L follows symlinks, -H includes dotfiles, -I ignores .gitignore so vendored
-- files stay reachable by name
local find_command = { 'fd', '-L', '-t', 'f', '-H', '-I', '-E', 'node_modules', '-E', '.git' }

telescope.setup({
	defaults = {
		layout_strategy = 'horizontal',
		layout_config = {
			prompt_position = 'top',
			horizontal = { width = 0.9, height = 0.85, preview_width = 0.5 },
		},
		-- results grow downward from the prompt rather than up towards it
		sorting_strategy = 'ascending',
		path_display = { 'truncate' },
		mappings = {
			i = {
				-- The prompt opens in insert, so bare j/k type. <Esc> now leaves
				-- insert (j/k move, second <Esc> closes) instead of closing.
				-- <C-c> stays the one-keypress exit.
				['<Esc>'] = false,
				['<C-j>'] = actions.move_selection_next,
				['<C-k>'] = actions.move_selection_previous,
				-- result set into the quickfix list, where bqf takes over
				['<C-q>'] = actions.smart_send_to_qflist + actions.open_qflist,
			},
		},
	},
	pickers = {
		find_files = { find_command = find_command },
		buffers = {
			-- floats current + alternate to the top with the *alternate*
			-- preselected, so <leader>fb<CR> toggles in one keystroke
			sort_lastused = true,
			mappings = { i = { ['<C-d>'] = actions.delete_buffer } },
		},
	},
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
			case_mode = 'smart_case',
		},
	},
})

-- optional: needs a compile step, else telescope uses its Lua sorter
pcall(telescope.load_extension, 'fzf')

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Files' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fj', builtin.jumplist, { desc = 'Jumps' })
vim.keymap.set('n', '<leader>fm', builtin.marks, { desc = 'Marks' })
-- reopens the last picker, query and cursor intact
vim.keymap.set('n', '<leader>fl', builtin.resume, { desc = 'Resume last picker' })

-- No builtin for this: every window in the tabpage, select one to jump.
local function windows()
	local pickers = require('telescope.pickers')
	local finders = require('telescope.finders')
	local action_state = require('telescope.actions.state')
	local conf = require('telescope.config').values

	local entries = {}
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		-- floats have no winnr worth jumping to, and one is this picker
		if vim.api.nvim_win_get_config(win).relative == '' then
			local buf = vim.api.nvim_win_get_buf(win)
			local name = vim.api.nvim_buf_get_name(buf)
			table.insert(entries, {
				win = win,
				display = string.format('%d: %s', vim.api.nvim_win_get_number(win),
					name ~= '' and vim.fn.fnamemodify(name, ':~:.') or '[No Name]'),
				path = name ~= '' and name or nil,
				lnum = vim.api.nvim_win_get_cursor(win)[1],
			})
		end
	end

	pickers.new({}, {
		prompt_title = 'Windows',
		finder = finders.new_table({
			results = entries,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.display,
					ordinal = entry.display,
					-- lets the file previewer light up the cursor line
					filename = entry.path,
					lnum = entry.lnum,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		previewer = conf.file_previewer({}),
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection and vim.api.nvim_win_is_valid(selection.value.win) then
					vim.api.nvim_set_current_win(selection.value.win)
				end
			end)
			return true
		end,
	}):find()
end

vim.keymap.set('n', '<leader>fw', windows, { desc = 'Windows' })
