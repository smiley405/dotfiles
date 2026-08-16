local uv = vim.uv ---@type table
local enable_haxe_lsp = true
local enable_vue_lsp = true
local servers = {
	'ts_ls',
	'cssls',
	'cssmodules_ls',
	'html',
	'eslint',
	'jsonls',
	'lua_ls',
	'vue_ls'
	--'gdscript',
}

-- configured by hand further down; kept out of the allowlist below
local manual_servers = { 'lua_ls', 'ts_ls' }

vim.api.nvim_create_autocmd('LspAttach', {
	desc = 'LSP actions',
	callback = function(event)
		local opts = { buffer = event.buf, remap = false }
		local function map(lhs, rhs, desc)
			vim.keymap.set('n', lhs, rhs, vim.tbl_extend('force', opts, { desc = desc }))
		end

		map('<leader>e', '<cmd>lua vim.diagnostic.open_float()<cr>', 'Diagnostics (float)')
		-- goto_prev/goto_next are gone in 0.13; jump() takes a count instead
		map('[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Previous diagnostic')
		map(']d', function() vim.diagnostic.jump({ count = 1 }) end, 'Next diagnostic')
		map('gd', '<cmd>lua vim.lsp.buf.definition()<cr>', 'Go to definition')
		map('<leader>vrn', '<cmd>lua vim.lsp.buf.rename()<cr>', 'Rename symbol')
		-- border is passed per-call; vim.lsp.with() is deprecated
		map('K', function() vim.lsp.buf.hover({ border = 'rounded' }) end, 'Hover docs')
		map('<space>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', 'Code action')
		map('gr', '<cmd>lua vim.lsp.buf.references()<cr>', 'References')
		vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = opts.buffer })
	end,
})

-- '*' merges into every server config, so all of them advertise the same cmp
-- completion capabilities. Must run before any server is configured.
vim.lsp.config('*', {
	capabilities = vim.tbl_deep_extend(
		'force',
		vim.lsp.protocol.make_client_capabilities(),
		require('cmp_nvim_lsp').default_capabilities()
	),
})

-- IMPORTANT: config for mason-auto-enabled servers must be registered *before*
-- mason-lspconfig.setup() below. That call ends in vim.lsp.enable(), and since
-- this module loads deferred (see init.lua) buffers are already open, so
-- enable() resolves configs and attaches on the spot. manual_servers are exempt.

-- cssmodules_ls ships filetypes = js/jsx/ts/tsx, so it started for every such
-- buffer -- ~61MB of node per project, and a second `nvim_lsp` cmp source
-- (cmp-nvim-lsp creates one per client). It is only useful where a
-- *.module.css exists, so gate on that. Cached per root; bounded scan.
local has_css_modules = {}

local function project_uses_css_modules(root)
	if has_css_modules[root] ~= nil then
		return has_css_modules[root]
	end

	local found = false
	for name, type in vim.fs.dir(root, {
		depth = 5,
		skip = function(dir)
			return dir ~= 'node_modules' and dir ~= '.git' and dir ~= 'dist'
				and dir ~= 'build' and dir ~= '.next' and dir ~= 'coverage'
		end,
	}) do
		if type == 'file' and name:match('%.module%.[sc]?[ac]?ss$') then
			found = true
			break
		end
	end

	has_css_modules[root] = found
	return found
end

vim.lsp.config('cssmodules_ls', {
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, { 'package.json', '.git' })
		-- declining to call on_dir is how root_dir refuses to attach
		if root and project_uses_css_modules(root) then
			on_dir(root)
		end
	end,
})

require('mason').setup()
require('mason-lspconfig').setup({
	-- Must stay a plain array ("enable only these"), never `{ exclude = ... }` --
	-- `exclude` enables every *installed* package minus the exclusions, which
	-- silently switches on leftovers from old experiments.
	automatic_enable = vim.tbl_filter(function(name)
		return not vim.tbl_contains(manual_servers, name)
	end, servers),
	ensure_installed = servers,
})

-- lazydev adds a plugin's dir to lua_ls's workspace.library only once this
-- config require()s from it, instead of handing over all of 'runtimepath'.
-- It appends to the library declared below, so that key must stay unset.
require('lazydev').setup()

-- for fix: https://github.com/neovim/neovim/issues/21686
vim.lsp.config('lua_ls', {
	settings = {
		Lua = {
			runtime = {
				version = 'LuaJIT',
			},
			diagnostics = {
				globals = { 'vim' },
			},
			telemetry = {
				enable = false,
			},
		},
	},
})

vim.lsp.enable('lua_ls')

if enable_haxe_lsp then
	-- Mason does not ship this: copy vshaxe's server.js out of the VSCode
	-- extension into ~/.vim/vshaxe, and re-copy on each vshaxe release. Haxe
	-- projects also need a build.hxml.
	local haxe_server_path = vim.env.HOME .. '/.vim/vshaxe/bin/server.js'

	if uv.fs_access(haxe_server_path, 'r') then
		-- lspconfig only ships this in its deprecated lua/lspconfig/configs/ dir,
		-- which nvim 0.11+ ignores -- so filetypes/root_dir must be spelled out
		-- here or vim.lsp.enable() has nothing to attach on.
		vim.lsp.config('haxe_language_server', {
			cmd = { 'node', haxe_server_path },
			filetypes = { 'haxe' },
			root_dir = function(bufnr, on_dir)
				local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
				-- prefer the nearest directory holding a .hxml build file
				local hxml = vim.fs.find(function(name)
					return name:match('%.hxml$')
				end, { path = dir, upward = true, type = 'file' })[1]

				on_dir(hxml and vim.fs.dirname(hxml) or vim.fs.root(bufnr, { '.git' }))
			end,
			settings = {
				haxe = {
					executable = 'haxe',
				},
			},
			-- haxe needs an hxml; pass the first one found as display arguments
			before_init = function(params, config)
				local opts = params.initializationOptions or {}
				if opts.displayArguments then
					return
				end

				local hxml = config.root_dir and vim.fs.find(function(name)
					return name:match('%.hxml$')
				end, { path = config.root_dir, type = 'file' })[1]

				if hxml then
					vim.notify('Using HXML: ' .. hxml)
					opts.displayArguments = { hxml }
					params.initializationOptions = opts
				end
			end,
		})
		vim.lsp.enable('haxe_language_server')
	end
end

if enable_vue_lsp then
	-- $MASON expansion: mason removed get_install_path()
	local vue_language_server_path = vim.fn.expand(
		'$MASON/packages/vue-language-server/node_modules/@vue/language-server')

	vim.lsp.config('ts_ls', {
		init_options = {
			plugins = {
				{
					name = '@vue/typescript-plugin',
					location = vue_language_server_path,
					languages = { 'vue' },
				},
			},
		},
		filetypes = {
			'typescript',
			'javascript',
			'javascriptreact',
			'typescriptreact',
			'vue'
		},
	})
	vim.lsp.enable('ts_ls')
end
