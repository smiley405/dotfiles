-- see the following like to setup lsp
-- https://lsp-zero.netlify.app/docs/getting-started.html
local lsp = require('lspconfig')
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
	'volar'
	--'gdscript',
}

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
			vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = opts.buffer })
		end,
})

-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = lsp.util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
	'force',
	lspconfig_defaults.capabilities,
	require('cmp_nvim_lsp').default_capabilities()
)

-- for fix: https://github.com/neovim/neovim/issues/21686
lsp['lua_ls'].setup {
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
}


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

require('mason').setup()
require('mason-lspconfig').setup({
	-- https://lsp-zero.netlify.app/docs/guide/integrate-with-mason-nvim.html
    automatic_enable = true,
	ensure_installed = servers,
	handlers = {
		-- this first function is the "default handler"
			-- it applies to every language server without a "custom handler"
			function(server_name)
				require('lspconfig')[server_name].setup({})
			end,
	},
})

