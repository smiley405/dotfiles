# My dotfiles

Neovim with 'takac/vim-hardtime' enabled by default!

External dependencies:
1. [rg](https://github.com/sharkdp/fd)
2. [fd](https://github.com/BurntSushi/ripgrep)
3. [yazi](https://github.com/sxyazi/yazi) + jq -- for the file manager keymaps
4. `file` -- yazi's mime typing; on windows it comes from git for windows

Terminal Using:
1. [wezterm](https://github.com/wez/wezterm)

## Install

One entry point per platform. Both are idempotent, both move anything real in
the way to a `.bak.<timestamp>` copy rather than deleting it, and both report
missing dependencies.

```sh
./install.sh        # linux, macos, WSL
```

```powershell
pwsh -ExecutionPolicy Bypass -File install.ps1   # windows -- no admin needed
```

| | linux / macos / WSL | windows |
| --- | --- | --- |
| neovim | `~/.config/nvim` | `%LOCALAPPDATA%\nvim` |
| yazi | `~/.config/yazi` | `%APPDATA%\yazi\config` |
| wezterm | `~/.config/wezterm` (native only) | `%USERPROFILE%\.config\wezterm` |
| `yazi-wez` | `~/.local/bin/yazi-wez` | `bin\` appended to the user PATH |

Windows gets junctions, not symlinks: a symlink needs elevation or developer
mode, a junction needs neither.

The links are on the directories, so a new file under `nvim/` is live with no
re-run; a new top-level tool is not, and needs a line in each installer. That
list stays explicit because the mapping is not mechanical -- `yazi/` lands on
`~/.config/yazi` but `%APPDATA%\yazi\config`, and `bash/` and `pwsh/` (sourced
by path) and `bin/` (on PATH) are not linked at all.

A windows box used both ways needs two checkouts and both installers; neither
side can reach the other, since a junction cannot point into the VM over
`\\wsl.localhost`. A linux box is just `./install.sh`, which owns wezterm too.

## yazi <-> neovim

`<leader>-` in neovim opens yazi in a wezterm split; `<Enter>` there sends the
file back and closes the split. In yazi, `<C-o>` / `<C-t>` open the selection in
neovim as a split or a new tab. Both go through `wezterm cli`, so yazi runs in a
real pane and keeps its own keys and image previews.

Outside wezterm -- the test is `TERM_PROGRAM` -- there is no pane to split, so
the keys copy `yazi-wez pick <server> - <path>` and show it in a notification.
Pasted into any shell it starts yazi at the same path and still talking to that
neovim; `-` for the pane id only means nothing is refocused when yazi exits.

The mux spawns a pane's program without a shell, so the helper has one half per
platform:

- `bin/yazi-wez` -- linux, macos, WSL. Runs under `bash -lc`, which skips
  `~/.bashrc`, so neovim's `$PATH` is carried into the pane.
- `bin/yazi-wez.ps1` -- native windows, reached via `bin/yazi-wez.cmd` because
  yazi's `shell` goes through cmd, which resolves `.cmd` but not `.ps1`. Windows
  panes inherit the mux's environment, so no `$PATH` juggling.

Under WSL neovim is a linux process and takes the unix half, even though wezterm
is windows-side.

`wezterm cli split-pane` cannot cross domains, so when nvim and its pane are of
different kinds the helper is spawned in its own domain and the pane moved into
the split.

The keymaps pass `%s`, yazi's own substitution for the selection -- already
shell-quoted and the same everywhere. The old `"$@"` stopped being filled in at
yazi 26.x, which silently killed both keys on every platform.

`<Enter>` opens in neovim too, in yazi's own pane. `yazi.toml` names `nvim`
rather than `$EDITOR`, which windows ignores in favour of a hardcoded `code`,
and names it bare -- openers never cross domains the way `yazi-wez` does, so
each yazi finds the nvim on its own side.

yazi types files by running `file(1)`, which windows does not ship; without
one nothing matches the mime rules and `start` claims every file. So
`install.ps1` points `YAZI_FILE_ONE` at the copy git for windows keeps in
`usr\bin`, and untyped files fall to neovim rather than to that dialog.

## Windows + WSL

On Windows the terminal opens straight into WSL Ubuntu (`config.default_domain`
in `wezterm/wezterm.lua`, guarded by `wezterm.target_triple`); on linux that
guard is skipped and the native login shell is used.

Splits and tabs follow the program in the pane rather than the pane's domain:
`cmd.exe` at a WSL prompt splits into cmd, `wsl` at a cmd prompt into bash.
wezterm cannot see into the VM, which is the tell -- a WSL pane running bash
reports wslhost.exe, one running a windows program reports that program.
`LEADER T` forces a windows tab regardless.

WezTerm is a Windows app, so it reads its config from
`C:\Users\<you>\.config\wezterm\wezterm.lua` -- which is what `install.ps1`
links up. Run it from a windows-side checkout; a junction cannot point into the
VM over `\\wsl.localhost`.

## New tabs and splits keep the current directory

Wezterm reads a pane's cwd from `/proc/<pid>/cwd` or from OSC 7. Under WSL only
OSC 7 works -- the terminal is a Windows app, the shell lives in the VM -- so
without it every new tab and split lands in `$HOME`. Ubuntu ships no emitter,
hence `bash/wsl-shell-integration.bash`.

`install.sh` appends this when it detects WSL -- sourced by absolute path, not
symlinked, since `~/.bashrc` keeps its distro contents:

```sh
cat >> ~/.bashrc <<'EOF'
if [ -f "$HOME/workspace/git/dotfiles/bash/wsl-shell-integration.bash" ]; then
	. "$HOME/workspace/git/dotfiles/bash/wsl-shell-integration.bash"
fi
EOF
```

Not wezterm-specific: kitty, foot, ghostty, konsole, VTE and Windows Terminal
all consume OSC 7.

## yazi leaves the shell where you exited

Run `y`, not `yazi`. yazi is a child process and cannot change its parent's
directory, so `--cwd-file` has it write the one it exited from and the wrapper
does the cd. `q` brings that directory back, `Q` does not.

The shell moves, not the terminal, so this holds in any of them -- but it is
per-shell: `bash/yazi-cd.bash` on linux, macos and WSL, `pwsh/yazi-cd.ps1` on
windows. `install.sh` appends the source line on every platform, unlike the OSC
7 emitter above; `install.ps1` uses `$PROFILE.CurrentUserAllHosts`, whichever
powershell ran it -- 7 and 5.1 keep separate profiles. Shells already open keep
the old definition until they restart.

Under WSL the two stack: `y` moves the shell, OSC 7 reports the new directory,
so a split opened afterwards starts there.

## Clipboard

Neovim shells out for the system clipboard, so `clipboard=unnamedplus`
(`nvim/lua/config/_default.lua`) expects a tool to be installed:

1. WSL -- `xclip`; WSLg bridges it to the Windows clipboard
2. Fedora -- `wl-clipboard` on wayland, `xclip` on X11
3. Windows -- `scoop install win32yank`, otherwise every paste spawns powershell

Neovim finds all three on its own. The exception is WSL, where `_default.lua`
names xclip outright: autodetection scans `$PATH` for every tool it misses, and
the `/mnt/c` entries there make that ~190ms of each startup. `:checkhealth
vim.provider` shows which one was picked.
