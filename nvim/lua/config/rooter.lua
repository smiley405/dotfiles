-- Auto-cd to the project root, plus a cached project history with a telescope
-- picker -- what makes a monorepo of sibling apps navigable.
local ok, rooter = pcall(require, 'rooter')
if not ok then
	vim.notify('rooter.nvim missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

-- trailing slash = must be a directory
local root_patterns = {
	'.git/', '_darcs/', '.hg/', '.bzr/', '.svn/',
	'Makefile', 'package.json',
}

-- kept so the scope picker can always offer a way back out
local origin = vim.fn.getcwd()

rooter.setup({
	root_patterns = root_patterns,
	-- nearest, not outermost: roots at .../games/claw, not the monorepo. Narrow
	-- suits editing; <leader>a widens when needed.
	outermost = false,
	-- window-local, as g:rooter_cd_cmd was
	command = 'lcd',
	enable_cache = true,
	-- '' leaves the cwd alone for files outside any project
	project_non_root = '',
})

-- Restores g:rooter_resolve_links = 1: this plugin makes roots absolute but not
-- symlink-resolved, so a project reached via a link would root to the link path.
rooter.reg_callback(function()
	local cwd = vim.fn.getcwd()
	local real = vim.fn.resolve(cwd)
	if real ~= cwd then
		vim.cmd('lcd ' .. vim.fn.fnameescape(real))
	end
end, 'resolve symlinked project roots')

-- Which of the markers above exist in a directory, for labelling the picker.
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

-- Rooting picks one directory; this picks any ancestor. Everything reading the
-- cwd follows -- grug-far's scope, telescope's file list. Renders through
-- vim.ui.select, which config/snacks.lua points at the snacks picker.
vim.keymap.set('n', '<leader>a', function()
	local dirs = ancestors()
	local cwd = vim.fn.getcwd()

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
		vim.cmd('lcd ' .. vim.fn.fnameescape(choice))
		vim.notify('cwd: ' .. vim.fn.fnamemodify(choice, ':~'))
	end)
end, { desc = 'Set scope (cwd) to an ancestor' })

-- Cached projects, most recently opened first; <CR> opens one in a new tab.
vim.keymap.set('n', '<leader>fp', '<cmd>Telescope project<CR>',
	{ desc = 'Projects (recent)' })
