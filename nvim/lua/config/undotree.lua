vim.cmd[[
	" Enable persistent undo so that undo history persists across vim sessions

	if has("persistent_undo")
		set undodir=~/.vim/undo
		set undofile
    endif

	let g:undotree_SetFocusWhenToggle = 1
	let g:undotree_DiffCommand = "git diff"
]]
