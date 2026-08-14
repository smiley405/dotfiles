-- Window and buffer number: what :b <n> and <C-w> aim at, and all an inactive
-- split shows besides its name.
local function info()
	return [[[%{winnr()}]:#%n]]
end

-- Panels hide their help behind ? or g?; say which. Read per buffer rather than
-- hardcoded, so a new plugin needs no change here.
local function find_help_key()
	for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, 'n')) do
		if m.lhs == '?' or m.lhs == 'g?' then
			return m.lhs
		end
	end
end

-- cached: lualine re-renders on every cursor move
local function help_key()
	local cached = vim.b.lualine_help_key
	if cached == nil then
		cached = find_help_key() or false
		vim.b.lualine_help_key = cached
	end
	return cached or nil
end

local function help_hint()
	return help_key() .. ' help'
end

local function has_help()
	return help_key() ~= nil
end

-- gitsigns has already counted the hunks for the sign column, so read its dict
-- rather than let lualine shell out to `git diff` on every cursor move.
local function gitsigns_diff()
	local gs = vim.b.gitsigns_status_dict
	if not gs then return nil end
	return { added = gs.added, modified = gs.changed, removed = gs.removed }
end

require('lualine').setup {
	options = {
		-- the scheme nvim actually runs; it was codedark, a vscode palette
		theme = 'tokyonight-night',
		-- flat, like the wezterm bar: no powerline arrows between sections
		section_separators = '',
		component_separators = '',
	},
	sections = {
		lualine_a = { 'mode' },
		-- what changed and what is broken, left to right
		lualine_b = {
			'branch',
			{ 'diff', source = gitsigns_diff },
			-- virtual_text is off (config/diagnostic.lua), so without this a
			-- count only exists in the sign column. Same letters as the signs.
			{
				'diagnostics',
				symbols = { error = 'E', warn = 'W', info = 'I', hint = 'H' },
			},
		},
		lualine_c = { 'filename', { help_hint, cond = has_help } },
		-- no 'progress': nvim-scrollbar already shows where in the file this is
		lualine_x = { { 'filetype', icon_only = true } },
		lualine_y = { 'location' },
		lualine_z = { { info } },
	},
	inactive_sections = {
		lualine_a = { { info } },
		lualine_b = {},
		lualine_c = { 'filename' },
		lualine_x = {},
		lualine_y = {},
		lualine_z = {}
	},
}
