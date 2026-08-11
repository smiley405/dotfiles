-- see the following like to setup lsp
-- https://lsp-zero.netlify.app/docs/getting-started.html
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

-- configured by hand further down (they need settings the automatic pass would
-- not apply), so they are kept out of the generated allowlist below
local manual_servers = { 'lua_ls', 'ts_ls' }

vim.api.nvim_create_autocmd('LspAttach', {
	desc = 'LSP actions',
	callback = function(event)
		local opts = { buffer = event.buf, remap = false }
		-- `desc` is what which-key shows for these in its popup
		local function map(lhs, rhs, desc)
			vim.keymap.set('n', lhs, rhs, vim.tbl_extend('force', opts, { desc = desc }))
		end

		-- Mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		map('<leader>e', '<cmd>lua vim.diagnostic.open_float()<cr>', 'Diagnostics (float)')
		-- goto_prev/goto_next are deprecated and removed in 0.13; jump() is the
		-- replacement and takes the direction as a count
		map('[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Previous diagnostic')
		map(']d', function() vim.diagnostic.jump({ count = 1 }) end, 'Next diagnostic')
		map('gd', '<cmd>lua vim.lsp.buf.definition()<cr>', 'Go to definition')
		map('<leader>vrn', '<cmd>lua vim.lsp.buf.rename()<cr>', 'Rename symbol')
		-- border used to come from a vim.lsp.with() handler wrapper (deprecated);
		-- it is passed per-call now -- see the note in config/diagnostic.lua
		map('K', function() vim.lsp.buf.hover({ border = 'rounded' }) end, 'Hover docs')
		map('<space>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', 'Code action')
		map('gr', '<cmd>lua vim.lsp.buf.references()<cr>', 'References')
		-- Enable completion triggered by <c-x><c-o>
		vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = opts.buffer })
	end,
})

-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server.
--
-- The '*' entry is merged into *every* server config (the ones mason enables
-- automatically as well as the hand-rolled ones below), so all servers
-- advertise the same completion capabilities: snippetSupport (placeholders in
-- function signatures), resolveSupport (docs + auto-import edits resolved
-- lazily) and preselect/labelDetails support.
vim.lsp.config('*', {
	capabilities = vim.tbl_deep_extend(
		'force',
		vim.lsp.protocol.make_client_capabilities(),
		require('cmp_nvim_lsp').default_capabilities()
	),
})

-- NOTE: config for any server mason enables automatically has to be registered
-- *before* mason-lspconfig.setup() below. That call ends in vim.lsp.enable(),
-- and since config/lsp.lua now loads on the deferred pass (see init.lua) there
-- are already buffers open when it does -- so enable() resolves each config and
-- attaches on the spot. A vim.lsp.config() placed after it arrives too late for
-- the first buffer of the session. Hand-configured servers (manual_servers) are
-- exempt: mason does not enable those, so they stay further down.

-- cssmodules_ls used to start for *every* javascript and typescript buffer,
-- because that is the filetype list it ships with -- ~61MB of node per project,
-- sitting next to ts_ls's own ~580MB, in projects that may not contain a single
-- CSS module. It also registers a second `nvim_lsp` source in cmp (cmp-nvim-lsp
-- creates one per attached client), so it is the remaining candidate for
-- duplicate completion entries.
--
-- It only has anything to say about `styles.foo` in a file that imports a
-- *.module.css, so it is now gated on the project actually having one. The
-- answer is cached per root: the scan is bounded to depth 5 and skips the
-- directories that make a recursive walk expensive.
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
		-- not calling on_dir at all is how a root_dir declines to attach
		if root and project_uses_css_modules(root) then
			on_dir(root)
		end
	end,
})

require('mason').setup()
require('mason-lspconfig').setup({
	-- https://lsp-zero.netlify.app/docs/guide/integrate-with-mason-nvim.html
	-- mason-lspconfig v2 dropped `handlers`; servers are enabled through
	-- `automatic_enable`, and the two hand-configured ones are enabled below
	-- because they need extra settings.
	--
	-- This has to be an allowlist, not `{ exclude = ... }`: given `exclude`,
	-- mason-lspconfig enables *every installed package* minus the exclusions,
	-- so any server left in mason from an old experiment gets switched on
	-- silently. That is how tailwindcss -- never listed in `servers` -- ended up
	-- attaching to every css and typescript buffer alongside cssls/ts_ls.
	-- A plain array is treated as "enable only these".
	automatic_enable = vim.tbl_filter(function(name)
		return not vim.tbl_contains(manual_servers, name)
	end, servers),
	ensure_installed = servers,
})

-- for fix: https://github.com/neovim/neovim/issues/21686
vim.lsp.config('lua_ls', {
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using
				-- (most likely LuaJIT in the case of Neovim)
				version = 'LuaJIT',
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = {
					'vim',
					'require'
				},
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
})

vim.lsp.enable('lua_ls')

if enable_haxe_lsp then
	-- for haxe: since there is an issue with Mason::
	-- manually copy the haxe_language_server extension from vscode
	-- add it .vim/vshaxe folder and point it cmd = {...}
	-- and remember haxe projects needs build.hxml
	-- https://community.openfl.org/t/build-openfl-with-hxml-config/9546
	-- https://community.haxe.org/t/neovim-lsp-having-issues-setting-up-haxe-lsp-with-neovim/3623/3
	-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#haxe_language_server
	--
	-- on each vscode vshaxe update/release change the version here aswell
	-- local haxe_server_path = vim.env.HOME .. '/.vscode-oss/extensions/nadako.vshaxe-2.31.0-universal/bin/server.js'
	local haxe_server_path = vim.env.HOME .. '/.vim/vshaxe/bin/server.js'

	if uv.fs_access(haxe_server_path, 'r') then
		-- nvim-lspconfig only ships haxe_language_server in the deprecated
		-- `lua/lspconfig/configs/` directory, which Nvim 0.11+ does not read
		-- (and upstream will delete). So there is nothing to merge `cmd` into:
		-- filetypes/root_dir have to be spelled out here, otherwise
		-- vim.lsp.enable() has no filetype to attach on and the server never
		-- starts. Ported from lspconfig's old default_config.
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
			-- haxe projects need an hxml; hand the first one we find to the
			-- server as its display arguments (was `on_new_config` in lspconfig)
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
	-- @see https://kosu.me/blog/vue-nvim-lsp-config
	-- https://github.com/mason-org/mason.nvim/blob/main/CHANGELOG.md#packageget_install_path-has-been-removed
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
