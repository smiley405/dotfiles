vim.g.did_install_syntax_menu = 1
vim.g.did_install_default_menus = 1
vim.g.no_buffers_menu = 1

vim.cmd([[
	unmenu *
	unmenu! *

	"Edit
	menu Edit.LSP\ Format :lua vim.lsp.buf.format({ async = false })<CR>
	menu Edit.NeoFormat :Neoformat<CR>
	menu Edit.Remove\ trailing\ whitespace\ -end\ of\ each\ line :%s/\s\+$//e<CR>
	menu Edit.Remove\ trailing\ whitespace\ -start\ of\ each\ line :%s/^\s\+//e<CR>
	"View"
	menu View.Toggle\ Colorizer :silent! ColorizerToggle<CR>
	"Git"
	menu Git.Diff:\ Working\ Tree :DiffviewOpen<CR>
	menu Git.Repository:\ Commits\ History :DiffviewFileHistory<CR>
	menu Git.File:\ Commits\ History :DiffviewFileHistory %<CR>
	menu Git.Line:\ Commits\ History :.DiffviewFileHistory %<CR>
	menu Git.Git\ Stash\ List :DiffviewFileHistory -g --range=stash<CR>
	menu Git.Git\ Blame :lua require('gitsigns').blame()<CR>
	menu Git.Git\ Merge:\ Resolve\ Conflicts<Tab>]x\ [x\ move,\ leader\ co/ct/cb/ca\ choose,\ dx\ drop :GitMergeTool<CR>
	menu Git.Toggle\ Git\ Lens :Gitsigns toggle_current_line_blame<CR>
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
