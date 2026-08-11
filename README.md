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

## Windows + WSL

On Windows the terminal opens straight into WSL Ubuntu (`config.default_domain`
in `wezterm/wezterm.lua`, guarded by `wezterm.target_triple`); on linux that
guard is skipped and the native login shell is used.

WezTerm is a Windows app, so it reads its config from
`C:\Users\<you>\.config\wezterm\wezterm.lua` -- copy it there after editing:

```sh
cp wezterm/wezterm.lua /mnt/c/Users/<you>/.config/wezterm/wezterm.lua
```

## New tabs and splits keep the current directory

Wezterm reads a pane's cwd from `/proc/<pid>/cwd` or from OSC 7. Under WSL only
OSC 7 works -- the terminal is a Windows app, the shell lives in the VM -- so
without it every new tab and split lands in `$HOME`. Ubuntu ships no emitter,
hence `bash/wsl-shell-integration.bash`.

Sourced by absolute path rather than symlinked, since `~/.bashrc` keeps its
distro contents. Adjust the path if the repo lives elsewhere:

```sh
cat >> ~/.bashrc <<'EOF'
if [ -f "$HOME/workspace/git/dotfiles/bash/wsl-shell-integration.bash" ]; then
	. "$HOME/workspace/git/dotfiles/bash/wsl-shell-integration.bash"
fi
EOF
```

Not wezterm-specific: kitty, foot, ghostty, konsole, VTE and Windows Terminal
all consume OSC 7.
