local conform = require('conform')

-- Resolves the project's own node_modules/.bin/biome and anchors to its
-- biome.json, so a repo's configured indent and quote style win over whatever
-- ts_ls would have done. Outside such a repo the binary is absent and the
-- fallback below takes it.
local biome = { 'biome' }

conform.setup({
	formatters_by_ft = {
		javascript = biome,
		javascriptreact = biome,
		typescript = biome,
		typescriptreact = biome,
		json = biome,
		jsonc = biome,
		css = biome,
	},

	-- Anything unlisted -- lua, html, vue, haxe -- goes to the attached server,
	-- which advertises documentFormatting for all of them.
	default_format_opts = { lsp_format = 'fallback' },
})

-- Not on save: reformatting a file on every write turns a one-line change into
-- a whole-file diff on someone else's code. `:ConformInfo` names what ran.
vim.keymap.set({ 'n', 'x' }, '<leader>cf', function()
	conform.format({ async = true })
end, { desc = 'Format buffer' })
