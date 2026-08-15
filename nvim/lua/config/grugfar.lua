-- Search / Replace / Files Filter / Flags / Paths as editable buffer lines, rg
-- re-running as you change any of them. <enter> gotos, <up>/<down> preview,
-- \i floats a preview, \q sends to quickfix.
local ok, grug = pcall(require, 'grug-far')
if not ok then
	vim.notify('grug-far.nvim missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

-- Prefilled rather than baked into extraArgs, so both stay visible and editable.
-- The old <leader>fg typed these onto the cmdline as -g "!{...}" and -S.
local default_filter =
'!{*-lock.json,*.lock.json,*.lock,*.log,*.min.js,*.map,*.csv,temp,builds,build,Export,out}'
local default_flags = '--smart-case'

local function prefills(extra)
	return vim.tbl_extend('force',
		{ filesFilter = default_filter, flags = default_flags }, extra or {})
end

grug.setup({
	-- Only non-default here. 'left' means "the window left of the panel, or make
	-- one" -- and 'splitright' is off, so the panel is leftmost and there never is
	-- one. That spawned a third window on every preview. 'prev' reuses the window
	-- <leader>fg was pressed from.
	openTargetWindow = { preferredLocation = 'prev' },
})

-- Panel keys are <localleader> (unset, so `\`): \r replace, \s sync, \c close.
-- `g?` lists them all.
vim.keymap.set('n', '<leader>fg', function()
	grug.open({ prefills = prefills() })
end, { desc = 'Search panel (grug-far)' })

vim.keymap.set('x', '<leader>fg', function()
	grug.with_visual_selection({ prefills = prefills() })
end, { desc = 'Search panel (selection)' })

-- Same panel, scoped to this file. Filter cleared, not just omitted: the default
-- list would exclude the very file you are in when it is a .log or .csv.
vim.keymap.set('n', '<leader>fs', function()
	local file = vim.fn.expand('%:p')
	if file == '' then
		return vim.notify('no file in this buffer to search', vim.log.levels.WARN)
	end
	grug.open({ prefills = prefills({ paths = file, filesFilter = '' }) })
end, { desc = 'Search in this file' })
