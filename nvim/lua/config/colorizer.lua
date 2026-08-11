-- setup() installs its own autocmd and attaches to every filetype (the default
-- is filetypes = { '*' }), so the `autocmd BufEnter * ColorizerToggle` that used
-- to live here was fighting it: entering a buffer colorizer had just attached to
-- toggled the highlighting straight back off. Verified with is_buffer_attached()
-- -- it reported false on every buffer. Dropping the autocmd is the fix.
--
-- lazy_load wraps the per-buffer attach in vim.schedule(), so opening a file
-- paints the text first and colorizes on the next tick instead of blocking.
require('colorizer').setup({
	lazy_load = true,
})
