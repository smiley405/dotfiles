-- Parsers only. nvim 0.12 does the highlighting through vim.treesitter.start()
-- and reads 'commentstring' from the language under the cursor, so gc gives
-- `{/* */}` inside a JSX block and `//` outside it, with no comment plugin
-- involved. master is frozen; main is the 0.12 rewrite and installs parsers.
--
-- Needs the tree-sitter CLI on PATH (see install.sh / install.ps1). Without it
-- nothing is built and nvim falls back to its own syntax files.
local ok, ts = pcall(require, 'nvim-treesitter')
if not ok then
	vim.notify('nvim-treesitter missing - run :PlugInstall', vim.log.levels.WARN)
	return
end

-- c, lua, markdown, query, vim and vimdoc ship with nvim already. No haxe or
-- jsonc grammar exists upstream, so those keep nvim's syntax files.
local parsers = {
	'bash', 'css', 'gdscript', 'html', 'javascript', 'json', 'python',
	'toml', 'tsx', 'typescript', 'vue', 'yaml',
}

ts.setup({})

-- Installs only what is missing, so later starts cost one directory read.
-- :TSUpdate, the plug hook, keeps the built ones current.
local installed = ts.get_installed()
local missing = vim.tbl_filter(function(p)
	return not vim.tbl_contains(installed, p)
end, parsers)
if #missing > 0 then
	ts.install(missing)
end

local function start(buf)
	pcall(vim.treesitter.start, buf)
end

vim.api.nvim_create_autocmd('FileType', {
	desc = 'treesitter highlighting where a parser exists',
	callback = function(ev)
		start(ev.buf)
	end,
})

-- This module loads deferred (init.lua), so the first file's FileType has
-- already fired by the time we get here.
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
	if vim.api.nvim_buf_is_loaded(buf) then
		start(buf)
	end
end
