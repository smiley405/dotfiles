local lsp = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local enable_haxe_lsp = true
local enable_vue_lsp = true
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

require('mason').setup()

require('mason-lspconfig').setup{
	ensure_installed = servers
}

for _, name in ipairs(servers) do
	lsp[name].setup {
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

	lsp['haxe_language_server'].setup({
			capabilities = capabilities,
			cmd = {'node', haxe_server_path},
		})
end

if enable_vue_lsp then
	-- @see https://kosu.me/blog/vue-nvim-lsp-config
	-- https://github.com/mason-org/mason.nvim/blob/main/CHANGELOG.md#packageget_install_path-has-been-removed
	local vue_language_server_path = vim.fn.expand('$MASON/packages/vue-language-server/node_modules/@vue/language-server')

	lsp['ts_ls'].setup {
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

vim.api.nvim_create_autocmd('LspAttach', {
		desc = 'LSP actions',
		callback = function(event)
			local opts = {buffer = event.buf, remap=false}
			-- Mappings.
			-- See `:help vim.lsp.*` for documentation on any of the below functions
			vim.keymap.set('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
			vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
			vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)
			vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
			vim.keymap.set('n', '<leader>vrn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
			vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
			vim.keymap.set('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
			vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
			-- Enable completion triggered by <c-x><c-o>
			vim.api.nvim_buf_set_option(opts.buffer, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
		end,
	})

