local gs = require('gitsigns')

gs.setup({
	current_line_blame = true,
	--current_line_blame_formatter = '<author>, <committer_time:%R>, <author_time:%Y-%m-%d> - <summary>',
	current_line_blame_formatter = '<author>, <author_time:%R> • <summary>',
	on_attach = function(bufnr)
		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navigation
		map('n', ']c', function()
			if vim.wo.diff then return ']c' end
			vim.schedule(function() gs.nav_hunk('next') end)
			return '<Ignore>'
		end, { expr = true, desc = 'Next hunk' })

		map('n', '[c', function()
			if vim.wo.diff then return '[c' end
			vim.schedule(function() gs.nav_hunk('prev') end)
			return '<Ignore>'
		end, { expr = true, desc = 'Previous hunk' })

		-- Actions
		map('n', '<leader>vh', gs.preview_hunk, { desc = 'Preview hunk' })
	end
})

-- Above the hunk, git belongs to lazygit; conflicts to meld. No plugin for
-- either -- a terminal tab is enough. Commands, not just keymaps, so
-- config/menu.lua calls these instead of repeating them.

-- A checkout or stash pop under a running nvim leaves stale buffers, hence
-- the checktime on the way out.
local function in_tab(build, missing)
	return function()
		local cmd = build()
		if not cmd then return end
		if vim.fn.executable(cmd[1]) == 0 then
			vim.notify(missing, vim.log.levels.WARN)
			return
		end

		vim.cmd('tabnew')
		local buf = vim.api.nvim_get_current_buf()
		vim.fn.jobstart(cmd, {
			term = true,
			on_exit = function()
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end
				vim.cmd('checktime')
			end,
		})
		vim.cmd('startinsert')
	end
end

local no_lazygit = 'lazygit is not installed'

-- lazygit opens on a panel: status, branch, log, stash
local function lazygit_panel(panel)
	return in_tab(function()
		return panel and { 'lazygit', panel } or { 'lazygit' }
	end, no_lazygit)
end

local function command(name, fn, opts)
	vim.api.nvim_create_user_command(name, fn, opts or {})
end

command('LazyGit', lazygit_panel(), { desc = 'lazygit' })
command('LazyGitLog', lazygit_panel('log'), { desc = 'lazygit: commit history' })
command('LazyGitStash', lazygit_panel('stash'), { desc = 'lazygit: stashes' })

-- --filter narrows commits, reflog and stash to one path
command('LazyGitFile', in_tab(function()
	local file = vim.fn.expand('%:p')
	if file == '' then
		vim.notify('No file in this buffer', vim.log.levels.WARN)
		return nil
	end
	return { 'lazygit', '--filter', file }
end, no_lazygit), { desc = 'lazygit: history of this file' })

-- guarded: a clean index says nothing, a missing tool is a raw git error.
-- Asks git which tool, so this holds if merge.tool changes.
command('GitMergeTool', in_tab(function()
	-- U = unmerged: the paths git wants resolved
	local conflicts = vim.fn.systemlist({ 'git', 'diff', '--name-only', '--diff-filter=U' })
	if vim.v.shell_error ~= 0 then
		vim.notify('Not a git repository', vim.log.levels.WARN)
		return nil
	elseif #conflicts == 0 then
		vim.notify('No merge conflicts', vim.log.levels.INFO)
		return nil
	end

	local tool = vim.fn.systemlist({ 'git', 'config', '--get', 'merge.tool' })[1]
	if tool and tool ~= '' and vim.fn.executable(tool) == 0 then
		vim.notify(tool .. ' is not installed', vim.log.levels.WARN)
		return nil
	end
	return { 'git', 'mergetool' }
end, 'git is not installed'), { desc = 'Resolve merge conflicts in meld' })

vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<CR>',
	{ silent = true, desc = 'lazygit' })
vim.keymap.set('n', '<leader>gh', '<cmd>LazyGitFile<CR>',
	{ silent = true, desc = 'File history (this file)' })
vim.keymap.set('n', '<leader>gs', '<cmd>LazyGitStash<CR>',
	{ silent = true, desc = 'Stash list' })
vim.keymap.set('n', '<leader>gm', '<cmd>GitMergeTool<CR>',
	{ silent = true, desc = 'Resolve merge conflicts' })

-- full-file window; the inline blame above is separate
vim.keymap.set('n', '<leader>gb', function() gs.blame() end,
	{ desc = 'Blame file' })
