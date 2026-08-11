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
		map('[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', 'Previous diagnostic')
		map(']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', 'Next diagnostic')
		map('gd', '<cmd>lua vim.lsp.buf.definition()<cr>', 'Go to definition')
		map('<leader>vrn', '<cmd>lua vim.lsp.buf.rename()<cr>', 'Rename symbol')
		map('K', '<cmd>lua vim.lsp.buf.hover()<cr>', 'Hover docs')
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

require('mason').setup()
require('mason-lspconfig').setup({
	-- https://lsp-zero.netlify.app/docs/guide/integrate-with-mason-nvim.html
	-- mason-lspconfig v2 dropped `handlers`; servers are enabled through
	-- `automatic_enable`, and the two excluded ones are enabled by hand below
	automatic_enable = {
		exclude = { 'lua_ls', 'ts_ls' }
	},
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
