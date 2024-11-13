vim.cmd([[
	let g:hardtime_default_on = 1
	let g:hardtime_ignore_quickfix = 1
	let g:hardtime_ignore_buffer_patterns = [ "fugitive", "diffpanel", "undotree", "oil" ]
	let g:hardtime_motion_with_count_resets = 1
	let g:hardtime_maxcount = 2

	let g:list_of_normal_keys = [
		\ "h", "j", "k", "l", "-", "+",
		\ "<UP>", "<DOWN>", "<LEFT>", "<RIGHT>", "<ENTER>"]

	let g:list_of_visual_keys = [
		\ "h", "j", "k", "l", "-", "+",
		\ "<UP>", "<DOWN>", "<LEFT>", "<RIGHT>", "<ENTER>"]
]])

