-- The completion stack is held out of 'runtimepath' by `on = {}` in plug.lua so
-- its after/plugin/ files do not run at startup; this is where it gets loaded.
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

-- noinsert: first entry is preselected, but nothing is written until confirm
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

-- True just after `.`, `?.`, `->` or `::`. Only the language server knows what
-- is valid there, so the word-scraping sources are filtered out (see below).
local function after_member_access()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	-- step back over the partial identifier being typed
	local before = line:sub(1, col):gsub('[%w_]*$', '')
	return before:match('[%.:>]$') ~= nil
end

local function has_words_before()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	if col == 0 then
		return false
	end
	local text = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
	return text:sub(col, col):match('%s') == nil
end

-- false positive: `cmp.setup` is annotated as a union (table | callable) and
-- lua_ls can only narrow to one branch at a time. It is both at runtime.
---@diagnostic disable-next-line: redundant-parameter
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

			-- keep the server's labelDetails; fall back to the kind word
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

		-- set select = false for <CR> to only accept entries you moved to
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

	-- one flat list ranked by priority; LSP results do not hide the rest
	sources = cmp.config.sources({
		{ name = 'nvim_lsp',                priority = 1000 },
		{ name = 'nvim_lsp_signature_help', priority = 900 },
		{
			name = 'luasnip',
			priority = 750,
			-- `styles.` offered ~130 snippets before this
			entry_filter = function() return not after_member_access() end,
		},
		{ name = 'path', priority = 500 },
		{
			name = 'buffer',
			priority = 250,
			keyword_length = 3,
			max_item_count = 10,
			-- otherwise `styles.` returns 2 real class names plus 10 buffer
			-- words (`div`, `from`, `const`, `import`, ...)
			entry_filter = function() return not after_member_access() end,
			option = {
				-- Visible real files only, under 512KB. nvim_list_bufs() (the
				-- default) also scrapes unloaded buffers and the scratch ones
				-- oil/neo-tree/terminal leave behind, and re-indexes the lot
				-- on every keystroke.
				get_bufnrs = function()
					local bufs = {}
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						if vim.bo[buf].buftype == '' and vim.api.nvim_buf_is_loaded(buf) then
							local name = vim.api.nvim_buf_get_name(buf)
							local stat = name ~= '' and vim.uv.fs_stat(name) or nil
							if not stat or stat.size < 512 * 1024 then
								bufs[buf] = true
							end
						end
					end
					return vim.tbl_keys(bufs)
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

-- buffer source for `/` and `?`
---@diagnostic disable-next-line: undefined-field
cmp.setup.cmdline({ '/', '?' }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = 'buffer' }
	}
})

-- cmdline + path source for `:`
---@diagnostic disable-next-line: undefined-field
cmp.setup.cmdline(':', {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = 'path' }
	}, {
		{ name = 'cmdline' }
	})
})
