-- Restricts repeated hjkl/arrows to build better motion habits. Maps globally,
-- so a plugin's own buffer-local hjkl still wins.
local hardtime = require('hardtime')

hardtime.setup({
	-- plugin default is 3
	max_count = 2,

	-- default true lets jkjkjk reset the counter forever, so only a literal jjj
	-- ever trips
	allow_different_key = false,

	-- 'hint' would let the key through and only advise
	restriction_mode = 'block',

	-- default disables the mouse, taking the wheel from telescope/grug-far results
	disable_mouse = false,

	-- names a better motion after a repeated run; `:Hardtime report` ranks them
	hint = true,
	notification = true,

	-- Blocked, not throttled: an arrow allowed twice a second is still an arrow.
	-- Normal/visual only -- config/cmp.lua binds <Up>/<Down> to the completion
	-- menu and cmp sets no buffer-local map to win against a global block.
	disabled_keys = {
		['<Up>'] = { 'n', 'x' },
		['<Down>'] = { 'n', 'x' },
		['<Left>'] = { 'n', 'x' },
		['<Right>'] = { 'n', 'x' },
	},

	-- Merged over defaults, which already cover TelescopePrompt, undotree, qf,
	-- netrw, noice and notify -- every exemption the old config hand-rolled.
	disabled_filetypes = {
		['grug-far'] = true,
		-- defaults cover aerial but not outline.nvim's sidebar
		['Outline'] = true,
		-- snacks pickers (vim.ui.select) and notifications; trailing * = prefix
		['snacks_picker.*'] = true,
		['snacks_notif.*'] = true,
		-- undotree's diff pane, read by scrolling. Also exempts real .diff files.
		['diff'] = true,
	},

	-- Merged over ~35 built-ins. These name motions this config actually has.
	hints = {
		['www'] = {
			message = function() return 'Use <leader>w to flash to any word on screen' end,
			length = 3,
		},
		['bbb'] = {
			message = function() return 'Use <leader>w to flash backwards too' end,
			length = 3,
		},
		[';;;'] = {
			message = function() return 'Use <leader>s to flash straight to the target' end,
			length = 3,
		},
	},
})
