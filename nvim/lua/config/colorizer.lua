-- No BufEnter autocmd here: setup() attaches on its own, and a
-- `ColorizerToggle` on BufEnter would toggle that straight back off.
--
-- lazy_load defers the per-buffer attach to vim.schedule().
require('colorizer').setup({
	lazy_load = true,
})
