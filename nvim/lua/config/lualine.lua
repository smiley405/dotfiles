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

require('lualine').setup {
	options = {
		theme = 'codedark',
	},
	sections = {
		lualine_a = { 'mode', { info }, },
		lualine_b = { 'branch' },
		lualine_c = { 'filename', { help_hint, cond = has_help } },
		lualine_x = { 'filetype' },
		lualine_y = { 'progress' },
		lualine_z = { 'location' }
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
