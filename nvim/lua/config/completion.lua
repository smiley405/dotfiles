-- The completion stack is registered with `on = {}` in plug.lua, i.e. held out
-- of 'runtimepath' until asked for, so that its after/plugin/ files do not run
-- during startup. This is the ask. Everything below is unchanged by it -- the
-- plugins are fully loaded by the time the requires on the next lines run.
vim.fn['plug#load'](
	'nvim-cmp',
	'cmp-nvim-lsp',
	'cmp-buffer',
	'cmp-path',
	'cmp-nvim-lsp-signature-help',
	'LuaSnip',
	'cmp_luasnip',
	'friendly-snippets'
)

local cmp = require('cmp')
local luasnip = require('luasnip')
local compare = require('cmp.config.compare')

require('luasnip.loaders.from_lua').lazy_load()
require('luasnip.loaders.from_vscode').lazy_load()

-- noinsert (instead of noselect) => first entry is preselected like VSCode,
-- but nothing is written into the buffer until you confirm.
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert' }

-- VSCode codicons (needs a nerd font)
local kind_icons = {
	Text = '󰉿',
	Method = '󰆧',
	Function = '󰊕',
	Constructor = '',
	Field = '󰜢',
	Variable = '󰀫',
	Class = '󰠱',
	Interface = '',
	Module = '',
	Property = '󰜢',
	Unit = '󰑭',
	Value = '󰎠',
	Enum = '',
	Keyword = '󰌋',
	Snippet = '',
	Color = '󰏘',
	File = '󰈙',
	Reference = '󰈇',
	Folder = '󰉋',
	EnumMember = '',
	Constant = '󰏿',
	Struct = '󰙅',
	Event = '',
	Operator = '󰆕',
	TypeParameter = '',
}

-- VSCode-ish icon colours, mapped onto the current colorscheme's palette.
local function set_cmp_highlights()
	local groups = {
		CmpItemAbbrDeprecated = { link = 'Comment' },
		-- the fuzzy-matched characters, highlighted like VSCode's blue match
		CmpItemAbbrMatch = { link = 'Function' },
		CmpItemAbbrMatchFuzzy = { link = 'Function' },
		CmpItemMenu = { link = 'Comment' },

		CmpItemKindText = { link = 'String' },
		CmpItemKindMethod = { link = 'Function' },
		CmpItemKindFunction = { link = 'Function' },
		CmpItemKindConstructor = { link = 'Function' },
		CmpItemKindField = { link = 'Identifier' },
		CmpItemKindVariable = { link = 'Identifier' },
		CmpItemKindClass = { link = 'Type' },
		CmpItemKindInterface = { link = 'Type' },
		CmpItemKindModule = { link = 'Include' },
		CmpItemKindProperty = { link = 'Identifier' },
		CmpItemKindUnit = { link = 'Number' },
		CmpItemKindValue = { link = 'Number' },
		CmpItemKindEnum = { link = 'Type' },
		CmpItemKindKeyword = { link = 'Keyword' },
		CmpItemKindSnippet = { link = 'Special' },
		CmpItemKindColor = { link = 'Special' },
		CmpItemKindFile = { link = 'Directory' },
		CmpItemKindReference = { link = 'Identifier' },
		CmpItemKindFolder = { link = 'Directory' },
		CmpItemKindEnumMember = { link = 'Constant' },
		CmpItemKindConstant = { link = 'Constant' },
		CmpItemKindStruct = { link = 'Type' },
		CmpItemKindEvent = { link = 'Special' },
		CmpItemKindOperator = { link = 'Operator' },
		CmpItemKindTypeParameter = { link = 'Type' },
	}

	for group, opts in pairs(groups) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

set_cmp_highlights()

vim.api.nvim_create_autocmd('ColorScheme', {
	desc = 'keep nvim-cmp highlights in sync with the colorscheme',
	callback = set_cmp_highlights,
})

local function has_words_before()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	if col == 0 then
		return false
	end
	local text = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
	return text:sub(col, col):match('%s') == nil
end

cmp.setup({
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			luasnip.lsp_expand(args.body) -- For `luasnip` users.
		end,
	},

	-- feels closer to VSCode's "instant" popup
	performance = {
		debounce = 20,
		throttle = 15,
		fetching_timeout = 200,
	},

	completion = {
		-- pop up after the first typed character
		keyword_length = 1,
	},

	-- VSCode always highlights the first (best) entry
	preselect = cmp.PreselectMode.Item,

	-- VSCode is aggressively fuzzy; let cmp be too
	matching = {
		disallow_fuzzy_matching = false,
		disallow_fullfuzzy_matching = false,
		disallow_partial_fuzzy_matching = false,
		disallow_partial_matching = false,
		disallow_prefix_unmatching = false,
	},

	formatting = {
		-- icon | label | kind name, i.e. the VSCode row layout
		fields = { 'kind', 'abbr', 'menu' },
		expandable_indicator = true,
		format = function(_entry, item)
			-- some sources (signature help, cmdline) omit the kind entirely
			local kind = item.kind or 'Text'
			local icon = kind_icons[kind] or ''

			-- keep long labels from blowing the popup up
			local max_abbr = 50
			if item.abbr and vim.fn.strchars(item.abbr) > max_abbr then
				item.abbr = vim.fn.strcharpart(item.abbr, 0, max_abbr - 1) .. '…'
			end

			-- VSCode's dim right-hand column is the signature / import source.
			-- cmp already put the server's labelDetails there, so keep it and
			-- only fall back to the kind word when the server sent nothing.
			local detail = item.menu
			if not detail or detail == '' then
				detail = kind
			end

			local max_menu = 30
			if vim.fn.strchars(detail) > max_menu then
				detail = vim.fn.strcharpart(detail, 0, max_menu - 1) .. '…'
			end

			item.menu = '  ' .. detail
			item.kind = ' ' .. icon .. ' '

			return item
		end,
	},

	window = {
		-- borderless, solid background: the VSCode suggest widget
		completion = {
			winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None',
			col_offset = -3,
			side_padding = 0,
			scrollbar = true,
		},
		documentation = cmp.config.window.bordered({
			winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None',
			max_width = 80,
			max_height = 20,
		}),
	},

	-- inline preview of the selected entry, like VSCode's ghost text
	experimental = {
		ghost_text = { hl_group = 'Comment' },
	},

	sorting = {
		priority_weight = 2,
		comparators = {
			compare.offset,
			compare.exact,
			compare.score,
			-- VSCode's biggest relevance signal: what you picked last time
			compare.recently_used,
			compare.locality,
			compare.kind,
			compare.length,
			compare.order,
		},
	},

	mapping = cmp.mapping.preset.insert({
		['<Up>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select },
		['<Down>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select },
		['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select },
		['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select },
		['<C-k>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select },
		['<C-j>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select },
		['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
		['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
		['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
		['<C-y>'] = cmp.config.disable,
		['<C-e>'] = cmp.mapping {
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		},

		-- VSCode: Enter accepts the highlighted entry (acceptSuggestionOnEnter).
		-- Swap `select = true` for `select = false` if you'd rather have <CR>
		-- only accept entries you explicitly moved to.
		['<CR>'] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Insert,
			select = true,
		}),

		-- VSCode: Tab accepts too, and also drives snippet placeholders
		['<Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })
			elseif luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			elseif has_words_before() then
				cmp.complete()
			else
				fallback()
			end
		end, { 'i', 's' }),

		['<S-Tab>'] = cmp.mapping(function(fallback)
			if luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { 'i', 's' }),
	}),

	-- one flat list, ranked by priority — VSCode doesn't hide path/buffer
	-- results just because the language server returned something
	sources = cmp.config.sources({
		{ name = 'nvim_lsp',                priority = 1000 },
		{ name = 'nvim_lsp_signature_help', priority = 900 },
		{ name = 'luasnip',                 priority = 750 },
		{ name = 'path',                    priority = 500 },
		{
			name = 'buffer',
			priority = 250,
			keyword_length = 3,
			max_item_count = 10,
			option = {
				-- complete from every loaded buffer, not just the current one
				get_bufnrs = function()
					return vim.api.nvim_list_bufs()
				end,
			},
		},
	}),
})

-- Insert `()` after confirming a function/method, like VSCode does
local ok, cmp_autopairs = pcall(require, 'nvim-autopairs.completion.cmp')
if ok then
	cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
end

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
