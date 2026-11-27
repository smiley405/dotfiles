-- devicons follows the newest Nerd Fonts; wezterm's built-in symbols font is a
-- release behind and stops at U+E6B7. Anything past that draws as a placeholder
-- and raises wezterm's missing-glyph warning, so those icons are swapped for
-- ones the built-in font has (checked with `wezterm ls-fonts --text`).
require('nvim-web-devicons').setup({
	override_by_extension = {
		-- default is U+E6B8, the new css logo
		css = { icon = '\u{e749}', color = '#663399', cterm_color = '91', name = 'Css' },
	},
})
