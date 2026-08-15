-- The handful of actions that had no other home, as real user commands -- so `:`
-- completion, noice's cmdline and the <leader>m palette all find them.
--
-- :LspStart / :LspStop / :LspRestart do not exist in this setup: config/lsp.lua
-- uses the native vim.lsp.enable() path and never loads lspconfig's framework.
-- :LspRestart is rebuilt below on the native API.

local function command(name, fn, opts)
	vim.api.nvim_create_user_command(name, fn, opts or {})
end

-- Keeps the cursor and the window's scroll position across a :%s that would
-- otherwise dump you at the last match.
local function keep_view(fn)
	return function()
		local view = vim.fn.winsaveview()
		fn()
		vim.fn.winrestview(view)
	end
end

command('LspFormat', function()
	vim.lsp.buf.format({ async = false })
end, { desc = 'Format buffer via the attached LSP' })

command('TrimTrailing', keep_view(function()
	vim.cmd([[keeppatterns %s/\s\+$//e]])
end), { desc = 'Strip trailing whitespace' })

-- The old menu called this "remove trailing whitespace - start of each line",
-- which undersells it: it strips the indentation off every line.
command('TrimIndent', keep_view(function()
	vim.cmd([[keeppatterns %s/^\s\+//e]])
end), { desc = 'Strip leading whitespace (de-indents every line)' })

command('DiffWindows', function()
	vim.cmd('windo diffthis')
end, { desc = 'Diff every window in this tab (:diffoff! to stop)' })

-- The menu had these as two entries; one toggle covers both, and it applies to
-- every window because scrollbind is only useful when more than one has it.
command('ScrollBind', function()
	local on = not vim.wo.scrollbind
	vim.cmd('windo set scrollbind' .. (on and '' or '!'))
	vim.notify('scrollbind ' .. (on and 'on' or 'off'))
end, { desc = 'Toggle scrollbind across the tab' })

-- `bufdo! edit` was the menu's version of this; it errors out on the first
-- scratch or unnamed buffer, and its bang throws away unsaved changes without
-- asking. This walks the buffer list instead, touching only file-backed ones,
-- and leaves modified buffers alone rather than silently discarding them.
command('ReloadBuffers', function()
	local reloaded, skipped = 0, 0
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buflisted and vim.bo[buf].buftype == ''
			and vim.api.nvim_buf_get_name(buf) ~= '' then
			if vim.bo[buf].modified then
				skipped = skipped + 1
			else
				-- nvim_buf_call restores the current buffer for us
				vim.api.nvim_buf_call(buf, function() vim.cmd('edit') end)
				reloaded = reloaded + 1
			end
		end
	end
	vim.notify(('reloaded %d buffer(s)%s')
		:format(reloaded, skipped > 0 and (', %d unsaved left alone'):format(skipped) or ''))
end, { desc = 'Re-read unmodified buffers from disk' })

-- lspconfig's :LspRestart is not available (see the header). Stopping the
-- client is enough to get it back: the server stays enabled, so the :edit
-- re-runs FileType and nvim re-attaches.
command('LspRestart', function()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return vim.notify('no LSP client attached', vim.log.levels.WARN)
	end
	for _, client in ipairs(clients) do
		client:stop(true)
	end
	vim.defer_fn(function() vim.cmd('edit') end, 200)
end, { desc = 'Restart the LSP clients on this buffer' })

-- The two `cmd.` entries, which only ever prefilled the cmdline for you.
command('R', function(opts)
	vim.cmd('read !' .. opts.args)
end, { nargs = '+', complete = 'shellcmd', desc = 'Read shell output into the buffer' })

command('Cex', function(opts)
	vim.fn.setqflist({}, ' ', { title = opts.args, lines = vim.fn.systemlist(opts.args) })
	vim.cmd('copen')
end, { nargs = '+', complete = 'shellcmd', desc = 'Shell output into the quickfix list' })

-- What <leader>m now opens: fuzzy search over every command, the ones above
-- included, with their desc as the second column. A tree of 22 entries was
-- worse than typing three letters.
vim.keymap.set('n', '<leader>m', function()
	require('telescope.builtin').commands()
end, { desc = 'Command palette' })
