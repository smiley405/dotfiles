-- Auto-cd to the project root, plus a cached project history picker.
local rooter = require('rooter')

-- trailing slash = must be a directory
local root_patterns = {
	'.git/', '_darcs/', '.hg/', '.bzr/', '.svn/',
	'Makefile', 'package.json',
}

-- kept so the scope picker can always offer a way back out
local origin = vim.fn.getcwd()

rooter.setup({
	root_patterns = root_patterns,
	-- nearest, not outermost: roots at games/claw, not the monorepo
	outermost = false,
	-- window-local, not global
	command = 'lcd',
	enable_cache = true,
	-- '' leaves the cwd alone for files outside any project
	project_non_root = '',
})

-- Roots come back absolute but not symlink-resolved, so a project reached via a
-- link would root to the link path.
rooter.reg_callback(function()
	local cwd = vim.fn.getcwd()
	local real = vim.fn.resolve(cwd)
	if real ~= cwd then
		vim.cmd('lcd ' .. vim.fn.fnameescape(real))
	end
end, 'resolve symlinked project roots')

-- Markers present in a directory, for the picker label.
local function markers_at(dir)
	local found = {}
	for _, pattern in ipairs(root_patterns) do
		local name = pattern:gsub('/$', '')
		if vim.uv.fs_stat(dir .. '/' .. name) then
			table.insert(found, name)
		end
	end
	return found
end

-- Every directory from the current file up to /, nearest first.
local function ancestors()
	local dir = vim.fn.expand('%:p:h')
	if dir == '' then
		dir = vim.fn.getcwd()
	end
	dir = vim.fn.resolve(dir)

	local list = {}
	while true do
		table.insert(list, dir)
		local parent = vim.fs.dirname(dir)
		if not parent or parent == dir then
			break
		end
		dir = parent
	end

	-- the cwd nvim started in, if the walk did not already pass through it
	if not vim.tbl_contains(list, origin) then
		table.insert(list, origin)
	end
	return list
end

-- :cd inside a window also clears that window's local dir, so rooter's lcds
-- cannot shadow the pick.
local function set_scope(dir)
	local cmd = 'cd ' .. vim.fn.fnameescape(dir)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		vim.api.nvim_win_call(win, function()
			vim.cmd(cmd)
		end)
	end
	vim.cmd(cmd)
end

local pin = vim.api.nvim_create_augroup('scope-pin', { clear = true })

-- Rooter re-cds on every BufEnter -- the picker closing is one -- so a widened
-- scope collapsed before any search read it. Mute it until a real file opens;
-- buftype and buflisted are what tell a file from a prompt or preview.
local function pin_scope(dir, from)
	vim.api.nvim_clear_autocmds({ group = pin })
	rooter.disable()
	set_scope(dir)

	vim.api.nvim_create_autocmd('BufEnter', {
		group = pin,
		callback = function(e)
			if e.buf == from or vim.api.nvim_buf_get_name(e.buf) == ''
				or vim.bo[e.buf].buftype ~= '' or not vim.bo[e.buf].buflisted then
				return
			end
			vim.api.nvim_clear_autocmds({ group = pin })
			rooter.enable()
			rooter.current_root()
		end,
	})
end

-- Rooting picks one directory; this picks any ancestor. Renders through
-- vim.ui.select, which config/snacks.lua points at the snacks picker.
vim.keymap.set('n', '<leader>a', function()
	local dirs = ancestors()
	local cwd = vim.fn.getcwd()
	-- before the picker's own buffer becomes current
	local from = vim.api.nvim_get_current_buf()

	vim.ui.select(dirs, {
		prompt = 'Scope (cwd):',
		format_item = function(dir)
			local label = vim.fn.fnamemodify(dir, ':~')
			local notes = markers_at(dir)
			if dir == cwd then
				table.insert(notes, 1, 'current')
			end
			if dir == origin then
				table.insert(notes, 'origin')
			end
			return #notes > 0 and (label .. '   ' .. table.concat(notes, ' ')) or label
		end,
	}, function(choice)
		if not choice then
			return
		end
		pin_scope(choice, from)
		vim.notify('cwd: ' .. vim.fn.fnamemodify(choice, ':~'))
	end)
end, { desc = 'Set scope (cwd) to an ancestor' })

-- Cached projects, most recently opened first; <CR> opens one in a new tab.
vim.keymap.set('n', '<leader>fp', '<cmd>Telescope project<CR>',
	{ desc = 'Projects (recent)' })
