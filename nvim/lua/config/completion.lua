-- cmp cost ~67ms at startup and cannot be reached before insert or cmdline
-- mode, so config/cmp.lua loads on first entry to either. cmp binds
-- TextChangedI/CmdlineChanged, which fire after this handler, so the menu still
-- appears on keystroke one.
--
-- Registered before the plug#load() below: cmp-nvim-lsp's after/plugin adds an
-- InsertEnter handler that require()s cmp, and autocmds run in registration
-- order.
vim.api.nvim_create_autocmd({ 'InsertEnter', 'CmdlineEnter' }, {
	desc = 'load the completion stack on first use',
	once = true,
	callback = function() require('config.cmp') end,
})

-- Cannot wait: config/lsp.lua needs default_capabilities() at startup. Cheap --
-- the module only require()s cmp from inside a function body.
vim.fn['plug#load']('cmp-nvim-lsp')
