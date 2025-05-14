local nvim_lsp = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local on_attach = function(client, bufnr)
	local opts = { noremap=true, silent=true }
	vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
	vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
	vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
	-- vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

	-- Enable completion triggered by <c-x><c-o>
	vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

	-- Mappings.
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	local bufopts = { noremap=true, silent=true, buffer=bufnr }
	vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
	vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
	vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
	-- quick fix
	vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
	vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
	-- vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end

local servers = {
	'ts_ls',
	'cssls',
	'cssmodules_ls',
	'html',
	'eslint',
	'jsonls',
	'volar'
	--'gdscript',
}

local enable_haxe_lsp = true
local enable_vue_lsp = true
local mason_registry = require('mason-registry')

require('mason').setup()

require('mason-lspconfig').setup{
	ensure_installed = servers
}

for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup {
		on_attach = on_attach,
		capabilities = capabilities,
	}
end

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

	nvim_lsp['haxe_language_server'].setup({
		on_attach = on_attach,
		capabilities = capabilities,
		cmd = {'node', haxe_server_path},
	})
end

if enable_vue_lsp then
	-- @see https://kosu.me/blog/vue-nvim-lsp-config
	-- https://github.com/mason-org/mason.nvim/blob/main/CHANGELOG.md#packageget_install_path-has-been-removed
	local vue_language_server_path = vim.fn.expand('$MASON/packages/vue-language-server/node_modules/@vue/language-server')

	nvim_lsp['ts_ls'].setup {
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
	}
end
