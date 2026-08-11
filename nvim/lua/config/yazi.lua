-- Opens yazi in a wezterm split running bin/yazi-wez; <Enter> there sends the
-- file back over --remote and closes the split. A real pane (not yazi.nvim's
-- :terminal float) keeps image previews and yazi's own keys intact.
-- Reverse direction: yazi/keymap.toml, same script.

-- ~/.config/nvim is a symlink into the repo; resolve it to find bin/
local repo = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath('config')), ':h')
local script = repo .. '/bin/yazi-wez'

-- wezterm.exe on PATH means WSL with interop; native linux has plain wezterm
local wezterm = vim.fn.executable('wezterm.exe') == 1 and 'wezterm.exe' or 'wezterm'

-- Cached: nvim does not change pane during a session.
local pane_id

local function nvim_pane()
	if pane_id then return pane_id end

	-- native panes export WEZTERM_PANE; WSL does not forward it, so there we ask
	-- the mux which pane has focus instead
	pane_id = tonumber(vim.env.WEZTERM_PANE or '')
	if pane_id then return pane_id end

	local res = vim.system({ wezterm, 'cli', 'list-clients', '--format', 'json' },
		{ text = true }):wait()
	if res.code ~= 0 then return nil end

	local ok, clients = pcall(vim.json.decode, (res.stdout:gsub('\r', '')))
	if not ok or type(clients) ~= 'table' or #clients == 0 then return nil end

	-- of several attached clients, the one that just acted is the least idle
	table.sort(clients, function(a, b) return a.idle_time.secs < b.idle_time.secs end)
	pane_id = clients[1].focused_pane_id
	return pane_id
end

local function open(start)
	local pane = nvim_pane()
	if not pane then
		vim.notify('yazi: no wezterm pane found (is nvim running under wezterm?)',
			vim.log.levels.WARN)
		return
	end

	-- nvim always listens, but --remote needs the address spelled out
	local server = vim.v.servername
	if server == '' then server = vim.fn.serverstart() end

	local args = { script, 'pick', server, tostring(pane) }
	if start and start ~= '' then args[#args + 1] = start end

	-- `bash -l` skips ~/.bashrc, where brew puts nvim/yazi/jq on PATH, so carry
	-- nvim's own PATH into the pane
	local run = 'export PATH=' .. vim.fn.shellescape(vim.env.PATH) .. '; exec'
	for _, a in ipairs(args) do run = run .. ' ' .. vim.fn.shellescape(a) end

	vim.system({
		wezterm, 'cli', 'split-pane',
		'--pane-id', tostring(pane),
		'--right', '--percent', '40',
		'--', 'bash', '-lc', run,
	}, { text = true }, function(res)
		if res.code ~= 0 then
			vim.schedule(function()
				vim.notify('yazi: ' .. (res.stderr ~= '' and res.stderr or 'split-pane failed'),
					vim.log.levels.ERROR)
			end)
		end
	end)
end

vim.keymap.set('n', '<leader>-', function()
	local file = vim.api.nvim_buf_get_name(0)
	-- open with the current file hovered
	open(vim.fn.filereadable(file) == 1 and file or nil)
end, { silent = true, desc = 'Yazi at current file (wezterm split)' })

vim.keymap.set('n', '<leader>_', function()
	open(vim.uv.cwd())
end, { silent = true, desc = 'Yazi in cwd (wezterm split)' })
