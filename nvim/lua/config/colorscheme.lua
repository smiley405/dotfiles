require("tokyonight").setup({
	style = "night",
	transparent = false,
	terminal_colors = true,

	styles = {
		comments = { italic = true },
		keywords = { italic = false },
	},

	dim_inactive = false,
	lualine_bold = true,
})

vim.cmd.colorscheme("tokyonight-night")
