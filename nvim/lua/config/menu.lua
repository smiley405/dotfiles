vim.g.did_install_syntax_menu = 1
vim.g.did_install_default_menus = 1
vim.g.no_buffers_menu = 1

vim.cmd([[
	function! ViewGitFileHistory(format, total_commits)
		let l:error_git_empty_file_type = 'Cannot Open Git file history.Empty file type!'
		let l:gclog = a:format == v:true ? '0Gclog' : 'Gclog'

		let l:file_name = expand('%:t')

		if l:file_name != ""
			if a:total_commits != 0
				let l:exe_cmd = l:gclog .. " -" .. a:total_commits .. " -- %"
				execute l:exe_cmd
			else
				if a:format == v:true
					execute '0Gclog'
				else
					execute 'Gclog -- %'
				endif
			endif
			if a:format == v:false
				" highlight file_name
				let @/ = file_name
				call feedkeys(":let &hlsearch=1 \| echo \<CR>", "n")
			endif
		else
			echo l:error_git_empty_file_type
		endif
	endfunction

	function! ViewGitStashList()
		execute 'Gclog -g stash'
	endfunction

	unmenu *
	unmenu! *

	"Edit
	menu Edit.Eslint\ Fix\ All :EslintFixAll<CR>
	menu Edit.NeoFormat :Neoformat<CR>
	menu Edit.Remove\ trailing\ whitespace\ -end\ of\ each\ line :%s/\s\+$//e<CR>
	menu Edit.Remove\ trailing\ whitespace\ -start\ of\ each\ line :%s/^\s\+//e<CR>
	"View"
	menu View.Toggle\ Colorizer :silent! ColorizerToggle<CR>
	"Git"
	menu Git.Repository:\ Commits\ History<Tab>:Gclog :Gclog<CR>
	menu Git.File:\ [Formatted]\ Commits\ History<Tab>:0Gclog :call ViewGitFileHistory(v:true, 0)<CR>
	menu Git.File:\ [Formatted]\ Last\ {n}\ Commits\ History<Tab>:0Gclog\ -{n}\ --\ % :call ViewGitFileHistory(v:true, 10)<Left><C-n>
	menu Git.File:\ [Raw]\ Commits\ History<Tab>:Gclog\ --\ % :call ViewGitFileHistory(v:false, 0)<CR>
	menu Git.File:\ [Raw]\ Last\ {n}\ Commits\ History<Tab>:Gclog\ -{n}\ --\ % :call ViewGitFileHistory(v:false, 10)<Left><C-n>
	menu Git.Git\ Stash\ List<Tab>:Gclog\ -g\ stash :call ViewGitStashList()<CR>
	menu Git.Git\ Blame<Tab>:G\ blame :G blame<CR>
	menu Git.Git\ Merge<Tab>-to\ resolve\ use\ :diffget,\ :diffput,\ y\ to\ yank\ and\ p\ to\ paste\ selected\ line\ or\ range\ :MergetoolToggle :MergetoolToggle<CR>
	menu Git.Toggle\ Git\ Lens :GitBlameToggle<CR>
	"Buffers
	menu Buffers.Scroll\ bind\ <Tab>:set\ scrollbind :set scrollbind<CR>
	menu Buffers.Scroll\ bind\ off\ <Tab>:set\ noscrollbind :set noscrollbind<CR>
	menu Buffers.Diff\ this\ <Tab>:windo\ diffthis :windo diffthis<CR>
	menu Buffers.Diff\ off\ <Tab>:windo\ diffoff : windo diffoff<CR>
	menu Buffers.Clear\ and\ redraw\ the\ screen :redraw!<CR>
	menu Buffers.Force\ Reload\ all\ buffers :bufdo! e<CR>
	menu Buffers.Close\ all\ buffers\ except\ this :%bdelete<bar>edit#<bar>bdelete#<CR>
	menu Buffers.Close\ all\ buffers :bufdo bd<CR>
	menu Buffers.Undo\ Tree :UndotreeToggle<CR>

	"Lsp
	menu Lsp.restart\ <Tab>:LspRestart\ <optional\ client\ id> :LspRestart <C-n>
	menu Lsp.start\ <Tab>:LspStart\ <client\ name> :LspStart <C-n>
	menu Lsp.stop :LspStop<CR>
	"cmd
	menu cmd.cmd\ Output\ To\ Buffer\ <Tab>:r\ !RANDOM_COMMAND :r !<C-n>
	menu cmd.cmd\ Output\ To\ Quick\ Fix\ <Tab>:cex\ system('$RANDOM_COMMAND')\ bar\ copen :cex system('')<bar>copen<Left><Left><Left><Left><Left><Left><Left><Left><C-n>
]])


