local cmp = require('cmp')
local luasnip = require('luasnip')

require('luasnip.loaders.from_lua').lazy_load()
require('luasnip.loaders.from_vscode').lazy_load()

vim.cmd([[
	set completeopt=menu,menuone,noselect
]])

cmp.setup({
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			luasnip.lsp_expand(args.body) -- For `luasnip` users.
		end,
	},
	formatting = {
		fields = { 'kind', 'abbr', 'menu' },
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		['<Up>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select },
		['<Down>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select },
		['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
		['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
		['<C-k>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
		['<C-j>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
		['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-1), { 'i', 'c' }),
		['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(1), { 'i', 'c' }),
		['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
		['<C-y>'] = cmp.config.disable,
		['<C-e>'] = cmp.mapping {
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		},
		['<CR>'] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = 'nvim_lsp' },
		{ name = 'luasnip' }, -- For luasnip users.
	}, {
		{ name = 'buffer' },
	}, {
		{ name = 'path' },
	}, {
		{ name = 'nvim_lsp_signature_help' }
	})
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
	{ name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
	{ name = 'path' }
  }, {
	{ name = 'cmdline' }
  })
})
