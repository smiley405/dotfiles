-- Opens yazi in a wezterm split running bin/yazi-wez; <Enter> there sends the
-- file back over --remote and closes the split. A real pane (not yazi.nvim's
-- :terminal float) keeps image previews and yazi's own keys intact.
-- Reverse direction: yazi/keymap.toml, same script.
--
-- The mux spawns a pane's program without a shell, so the script has two halves:
-- bin/yazi-wez under bash, bin/yazi-wez.ps1 under powershell. WSL nvim is a
-- linux process, so it takes the unix one.

-- the config dir is a symlink into the repo; resolve it to find bin/
local repo = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath('config')), ':h')
local is_win = vim.fn.has('win32') == 1
local script = repo .. (is_win and '/bin/yazi-wez.ps1' or '/bin/yazi-wez')

-- Resolved on first use, not at startup: executable() walks every $PATH entry,
-- and the /mnt/c ones under WSL made this ~88ms of every launch.
local wezterm

local function wezterm_cmd()
	if not wezterm then
		-- wezterm.exe on windows and on WSL with interop; plain wezterm on linux
		wezterm = vim.fn.executable('wezterm.exe') == 1 and 'wezterm.exe' or 'wezterm'
	end
	return wezterm
end

-- Same, and only ever needed on windows.
local powershell

local function powershell_cmd()
	if not powershell then
		powershell = vim.fn.executable('pwsh') == 1 and 'pwsh' or 'powershell'
	end
	return powershell
end

-- Cached: nvim does not change pane during a session.
local pane_id

local function nvim_pane()
	if pane_id then return pane_id end

	-- native panes export WEZTERM_PANE; WSL does not forward it, so there we ask
	-- the mux which pane has focus instead
	pane_id = tonumber(vim.env.WEZTERM_PANE or '')
	if pane_id then return pane_id end

	local res = vim.system({ wezterm_cmd(), 'cli', 'list-clients', '--format', 'json' },
		{ text = true }):wait()
	if res.code ~= 0 then return nil end

	local ok, clients = pcall(vim.json.decode, (res.stdout:gsub('\r', '')))
	if not ok or type(clients) ~= 'table' or #clients == 0 then return nil end

	-- of several attached clients, the one that just acted is the least idle
	table.sort(clients, function(a, b) return a.idle_time.secs < b.idle_time.secs end)
	pane_id = clients[1].focused_pane_id
	return pane_id
end

-- split-pane always lands in the target pane's domain -- it takes no --domain --
-- so a windows nvim sitting in a WSL pane would try to run powershell inside the
-- VM, and the split would die on the spot. wezterm reports no domain over the
-- cli, but a WSL pane's cwd is a posix path where a windows one has a drive.
local pane_native

local function pane_is_native(pane)
	if pane_native ~= nil then return pane_native end
	pane_native = true

	local res = vim.system({ wezterm_cmd(), 'cli', 'list', '--format', 'json' },
		{ text = true }):wait()
	if res.code ~= 0 then return pane_native end

	local ok, panes = pcall(vim.json.decode, (res.stdout:gsub('\r', '')))
	if not ok or type(panes) ~= 'table' then return pane_native end

	for _, p in ipairs(panes) do
		if p.pane_id == pane and type(p.cwd) == 'string' and p.cwd ~= '' then
			-- file:///C:/... or file://host/C:/... both leave /C: once the
			-- scheme and authority are gone; a linux cwd leaves /home/...
			pane_native = p.cwd:gsub('^file://[^/]*', ''):match('^/%a:') ~= nil
			break
		end
	end
	return pane_native
end

-- Windows panes inherit the mux's environment, so they skip the PATH dance.
local function pane_program(args)
	if is_win then
		local prog = { powershell_cmd(), '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
			'-File', script }
		return vim.list_extend(prog, args)
	end

	-- `bash -l` skips ~/.bashrc, where brew puts nvim/yazi/jq on PATH, so carry
	-- nvim's own PATH into the pane
	local run = 'export PATH=' .. vim.fn.shellescape(vim.env.PATH) .. '; exec '
		.. vim.fn.shellescape(script)
	for _, a in ipairs(args) do run = run .. ' ' .. vim.fn.shellescape(a) end
	return { 'bash', '-lc', run }
end

local function open(start)
	local pane = nvim_pane()
	if not pane then
		vim.notify('yazi: no wezterm pane found (is nvim running under wezterm?)',
			vim.log.levels.WARN)
		return
	end

	if is_win and not pane_is_native(pane) then
		vim.notify('yazi: this is a WSL pane, so the split cannot run the windows '
			.. 'helper. Open a windows pane with LEADER T, or use the WSL nvim here.',
			vim.log.levels.WARN)
		return
	end

	-- nvim always listens, but --remote needs the address spelled out
	local server = vim.v.servername
	if server == '' then server = vim.fn.serverstart() end

	local args = { 'pick', server, tostring(pane) }
	if start and start ~= '' then args[#args + 1] = start end

	local cmd = {
		wezterm_cmd(), 'cli', 'split-pane',
		'--pane-id', tostring(pane),
		'--right', '--percent', '40',
		'--',
	}
	vim.list_extend(cmd, pane_program(args))

	vim.system(cmd, { text = true }, function(res)
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
