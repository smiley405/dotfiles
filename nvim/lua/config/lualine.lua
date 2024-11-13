local function info()
  return [[[%{winnr()}]:#%n]]
end

require('lualine').setup {
	options = {
		theme = 'codedark',
	},
	sections = {
		lualine_a = {'mode',{info},},
		lualine_b = {'branch'},
		lualine_c = {'filename'},
		lualine_x = {'filetype'},
		lualine_y = {'progress'},
		lualine_z = {'location'}
	},
	inactive_sections = {
		lualine_a = {{info}},
		lualine_b = {},
		lualine_c = {'filename'},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {}
	},
}
