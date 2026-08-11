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
			vim.schedule(function() gs.next_hunk() end)
			return '<Ignore>'
		end, { expr = true, desc = 'Next hunk' })

		map('n', '[c', function()
			if vim.wo.diff then return '[c' end
			vim.schedule(function() gs.prev_hunk() end)
			return '<Ignore>'
		end, { expr = true, desc = 'Previous hunk' })

		-- Actions
		map('n', '<leader>vh', gs.preview_hunk, { desc = 'Preview hunk' })
	end
})

-- diff3_mixed: the two sides on top, the merged result below
require('diffview').setup({
	view = {
		merge_tool = {
			layout = 'diff3_mixed',
		},
	},
})

-- takes a rev too, e.g. :DiffviewOpen HEAD~2
vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<CR>',
	{ silent = true, desc = 'Diff working tree' })

-- replaces :0Gclog, but checks nothing out. Prefix a range to trace those lines.
vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<CR>',
	{ silent = true, desc = 'File history (this file)' })

-- -g walks the refs/stash reflog, which is where stashes live
vim.keymap.set('n', '<leader>gs', '<cmd>DiffviewFileHistory -g --range=stash<CR>',
	{ silent = true, desc = 'Stash list' })

-- full-file window; the inline blame above is separate
vim.keymap.set('n', '<leader>gb', function() gs.blame() end,
	{ desc = 'Blame file' })

-- multi-file history opens with one entry expanded; it fills async, hence the poll
vim.api.nvim_create_autocmd('User', {
	pattern = 'DiffviewViewOpened',
	callback = function()
		local ok, lib = pcall(require, 'diffview.lib')
		if not ok then return end

		local view = lib.get_current_view()
		local panel = view and view.panel
		-- the file tree and single-file history have no folds
		if not panel or type(panel.entries) ~= 'table' or not panel.set_entry_fold then
			return
		end

		local tries, timer = 0, vim.uv.new_timer()
		timer:start(80, 80, vim.schedule_wrap(function()
			tries = tries + 1
			local done = tries > 25 or panel.single_file

			if not panel.single_file and #panel.entries > 0 then
				for _, entry in ipairs(panel.entries) do entry.folded = true end
				pcall(function()
					panel:render()
					panel:redraw()
				end)
				done = true
			end

			if done and not timer:is_closing() then
				timer:stop()
				timer:close()
			end
		end))
	end,
})

-- guarded, since :DiffviewOpen on a clean index just opens an empty diff
vim.api.nvim_create_user_command('GitMergeTool', function()
	-- U = unmerged: the paths git wants resolved
	local conflicts = vim.fn.systemlist({ 'git', 'diff', '--name-only', '--diff-filter=U' })
	if vim.v.shell_error ~= 0 then
		vim.notify('Not a git repository', vim.log.levels.WARN)
	elseif #conflicts == 0 then
		vim.notify('No merge conflicts', vim.log.levels.INFO)
	else
		vim.cmd('DiffviewOpen')
	end
end, { desc = 'Resolve merge conflicts' })

-- in the merge view: ]x [x move, <leader>co/ct/cb/ca take ours/theirs/base/all,
-- dx drops it (upper-case for the whole file). Write the middle window to stage.
vim.keymap.set('n', '<leader>gm', '<cmd>GitMergeTool<CR>',
	{ silent = true, desc = 'Resolve merge conflicts' })
