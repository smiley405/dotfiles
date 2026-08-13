-- Opens yazi in a wezterm split running bin/yazi-wez; <Enter> there sends the
-- file back over --remote and closes the split. A real pane (not yazi.nvim's
-- :terminal float) keeps image previews and yazi's own keys intact.
-- Reverse direction: yazi/keymap.toml, same script.
--
-- Elsewhere there is no pane to split, so the keys copy `yazi-wez pick <server>
-- - <path>` and notify it. Pasted in any shell it still reaches this nvim.
--
-- The mux spawns a pane's program without a shell, so the script has two halves:
-- bin/yazi-wez under bash, bin/yazi-wez.ps1 under powershell. WSL nvim is a
-- linux process, so it takes the unix one.

-- the config dir is a symlink into the repo; resolve it to find bin/
local repo = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath('config')), ':h')
local is_win = vim.fn.has('win32') == 1
local script = repo .. (is_win and '/bin/yazi-wez.ps1' or '/bin/yazi-wez')

-- Set in every pane and forwarded into the WSL ones, unlike WEZTERM_PANE.
local in_wezterm = vim.env.TERM_PROGRAM == 'WezTerm'

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

-- split-pane lands in the target pane's domain and takes no --domain, so the
-- helper cannot be split straight into a pane of the other kind: `cmd.exe` typed
-- at a WSL prompt, `wsl` typed at a cmd one. wezterm reports no domain over the
-- cli, but a windows pane's cwd carries a drive letter and a linux one does not.
local is_wsl = not is_win and (vim.env.WSL_DISTRO_NAME or '') ~= ''

local pane_checked, pane_native

local function pane_is_native(pane)
	if pane_checked then return pane_native end
	pane_checked = true

	local res = vim.system({ wezterm_cmd(), 'cli', 'list', '--format', 'json' },
		{ text = true }):wait()
	if res.code ~= 0 then return nil end

	local ok, panes = pcall(vim.json.decode, (res.stdout:gsub('\r', '')))
	if not ok or type(panes) ~= 'table' then return nil end

	for _, p in ipairs(panes) do
		if p.pane_id == pane and type(p.cwd) == 'string' and p.cwd ~= '' then
			-- file:///C:/... and file://host/C:/... both leave /C:
			pane_native = p.cwd:gsub('^file://[^/]*', ''):match('^/%a:') ~= nil
			break
		end
	end
	return pane_native
end

-- Where the helper has to be spawned, or nil when the pane already matches it
-- and a plain split will do. nil too when there was nothing to go on.
local function other_domain(pane)
	local native = pane_is_native(pane)
	if native == nil then return nil end
	if is_win and not native then return 'local' end
	if is_wsl and native then return 'WSL:' .. vim.env.WSL_DISTRO_NAME end
	return nil
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

-- Double quotes: the only kind cmd takes, and bash and pwsh take them too.
local function quote(s)
	if s:match('^[%w%._/\\:%-]+$') then return s end
	return '"' .. (s:gsub('"', '\\"')) .. '"'
end

-- No pane to split: hand the command over. `-` means nothing to refocus.
local function copy_command(server, start)
	local cmd = 'yazi-wez pick ' .. quote(server) .. ' -'
	if start and start ~= '' then cmd = cmd .. ' ' .. quote(start) end

	-- nvim finds win32yank/xclip/wl-copy itself, or OSC 52 over ssh
	vim.fn.setreg('+', cmd)

	vim.notify(table.concat({
		'No wezterm pane to split -- copied instead:',
		'',
		'  ' .. cmd,
		'',
		'Paste it in any terminal. <Enter> in yazi sends the file back here.',
	}, '\n'), vim.log.levels.INFO, { title = 'yazi' })
end

local function open(start)
	-- nvim always listens, but --remote needs the address spelled out
	local server = vim.v.servername
	if server == '' then server = vim.fn.serverstart() end

	if not in_wezterm then return copy_command(server, start) end

	-- mux unreachable: the paste still works
	local pane = nvim_pane()
	if not pane then return copy_command(server, start) end

	local args = { 'pick', server, tostring(pane) }
	if start and start ~= '' then args[#args + 1] = start end

	local function failed(res)
		if res.code == 0 then return false end
		vim.schedule(function()
			vim.notify('yazi: ' .. (res.stderr ~= '' and res.stderr or 'split-pane failed'),
				vim.log.levels.ERROR)
		end)
		return true
	end

	local function split(tail)
		local cmd = { wezterm_cmd(), 'cli', 'split-pane', '--pane-id', tostring(pane),
			'--right', '--percent', '40' }
		vim.system(vim.list_extend(cmd, tail), { text = true }, failed)
	end

	local domain = other_domain(pane)
	if not domain then
		return split(vim.list_extend({ '--' }, pane_program(args)))
	end

	-- spawn it where it belongs, then adopt that pane as the split
	local cmd = { wezterm_cmd(), 'cli', 'spawn', '--domain-name', domain,
		'--pane-id', tostring(pane), '--' }
	vim.list_extend(cmd, pane_program(args))
	vim.system(cmd, { text = true }, function(res)
		if failed(res) then return end
		split({ '--move-pane-id', vim.trim((res.stdout or ''):gsub('\r', '')) })
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
