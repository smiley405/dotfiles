# My dotfiles

Neovim with 'takac/vim-hardtime' enabled by default!

External dependencies:
1. [rg](https://github.com/sharkdp/fd)
2. [fd](https://github.com/BurntSushi/ripgrep)
3. [yazi](https://github.com/sxyazi/yazi) + jq -- for the file manager keymaps

Terminal Using:
1. [wezterm](https://github.com/wez/wezterm)

## yazi <-> neovim

`<leader>-` in neovim opens yazi in a wezterm split; `<Enter>` there sends the
file back and closes the split. In yazi, `<C-o>` / `<C-t>` open the selection in
neovim as a split or a new tab. `bin/yazi-wez` drives both through `wezterm
cli`, so yazi runs in a real pane and keeps its own keys and image previews.

Symlinks expected (same idea as `~/.config/nvim -> nvim`):

```sh
ln -sfn "$PWD/yazi" ~/.config/yazi
ln -sfn "$PWD/bin/yazi-wez" ~/.local/bin/yazi-wez
```

