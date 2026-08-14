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

One entry point per platform, both idempotent. Anything real in the way is
moved to a `.bak.<timestamp>` copy, never deleted.

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
| lazygit | `~/.config/lazygit` | `%LOCALAPPDATA%\lazygit` |
| wezterm | `~/.config/wezterm` (native only) | `%USERPROFILE%\.config\wezterm` |
| `yazi-wez` | `~/.local/bin/yazi-wez` | `bin\` appended to the user PATH |

Windows gets junctions, not symlinks: a symlink needs elevation or developer
mode, a junction needs neither. A junction also cannot point into the VM over
`\\wsl.localhost`, so a windows box used both ways needs two checkouts and both
installers.

The links are on the directories, so a new file under `nvim/` is live with no
re-run. A new top-level tool needs a line in each installer, because the
mapping is not mechanical: `yazi/` lands on `~/.config/yazi` but
`%APPDATA%\yazi\config`, lazygit wants `~/Library/Application Support/lazygit`
on macos unless `XDG_CONFIG_HOME` is set, and `bash/`, `pwsh/` and `bin/` are
not linked at all.

## yazi <-> neovim

`<leader>-` in neovim opens yazi in a wezterm split; `<Enter>` there sends the
file back and closes it. In yazi, `<C-o>` and `<C-t>` open the selection in
neovim as a split or a new tab. Both go through `wezterm cli`, so yazi runs in
a real pane and keeps its own keys and image previews.

Outside wezterm (`TERM_PROGRAM`) there is no pane to split, so the keys copy
`yazi-wez pick <server> - <path>` into a notification instead. Pasted anywhere
it starts yazi at the same path, still talking to that neovim.

The mux spawns a pane's program without a shell, so the helper has one half per
platform:

- `bin/yazi-wez` -- linux, macos, WSL. Runs under `bash -lc`, skipping
  `~/.bashrc`, so neovim's `$PATH` reaches the pane.
- `bin/yazi-wez.ps1` -- windows, reached via `bin/yazi-wez.cmd`, since yazi's
  `shell` goes through cmd, which resolves `.cmd` but not `.ps1`.

Under WSL neovim is a linux process and takes the unix half, even though
wezterm is windows-side. `wezterm cli split-pane` cannot cross domains, so when
nvim and its pane differ the helper spawns in its own domain and the pane is
moved into the split.

Two things that bite:

- The keymaps pass `%s`, yazi's own substitution -- already shell-quoted, same
  everywhere. The old `"$@"` stopped being filled in at yazi 26.x and silently
  killed both keys on every platform.
- yazi types files with `file(1)`, which windows lacks. Without it nothing
  matches the mime rules and `start` claims everything, so `install.ps1` points
  `YAZI_FILE_ONE` at the copy git for windows keeps in `usr\bin`.

`yazi.toml` names `nvim` bare, not `$EDITOR` -- windows ignores `$EDITOR` for a
hardcoded `code`, and openers never cross domains the way `yazi-wez` does.

## Windows + WSL

The terminal opens straight into WSL Ubuntu (`config.default_domain` in
`wezterm/wezterm.lua`, guarded by `wezterm.target_triple`; on linux the guard
is skipped).

Splits and tabs follow the program in the pane, not the pane's domain:
`cmd.exe` at a WSL prompt splits into cmd, `wsl` at a cmd prompt into bash.
`LEADER T` forces a windows tab regardless.

WezTerm is a windows app and reads its config from
`C:\Users\<you>\.config\wezterm\wezterm.lua`, so run `install.ps1` from a
windows-side checkout.

## New tabs and splits keep the current directory

Wezterm reads a pane's cwd from `/proc/<pid>/cwd` or OSC 7. Under WSL only OSC
7 works -- the terminal is a windows app, the shell lives in the VM -- and
Ubuntu ships no emitter, so without `bash/wsl-shell-integration.bash` every new
tab lands in `$HOME`.

`install.sh` appends this on WSL, sourced by absolute path so `~/.bashrc` keeps
its distro contents:

```sh
cat >> ~/.bashrc <<'EOF'
if [ -f "$HOME/workspace/git/dotfiles/bash/wsl-shell-integration.bash" ]; then
	. "$HOME/workspace/git/dotfiles/bash/wsl-shell-integration.bash"
fi
EOF
```

Not wezterm-specific -- kitty, foot, ghostty, konsole, VTE and Windows Terminal
all consume OSC 7.

## yazi leaves the shell where you exited

Run `y`, not `yazi`. yazi cannot change its parent's directory, so `--cwd-file`
has it write the one it exited from and the wrapper does the cd. `q` brings
that directory back, `Q` does not.

The shell moves, not the terminal, so this works in any of them -- but it is
one half per shell: `bash/yazi-cd.bash`, `pwsh/yazi-cd.ps1`, and `bin/y.cmd`
for cmd, which has no functions. `install.sh` appends the source line
everywhere; `install.ps1` uses `$PROFILE.CurrentUserAllHosts`, since powershell
7 and 5.1 keep separate profiles. Open shells keep the old definition until
they restart.

A batch file runs in the cmd that called it, which is what lets `y.cmd` do the
cd; it `call`s yazi so a yazi that is itself a `.cmd` shim comes back.

Under WSL the two stack: `y` moves the shell, OSC 7 reports it, so the next
split starts there.

## Clipboard

Neovim shells out for the system clipboard, so `clipboard=unnamedplus`
(`nvim/lua/config/_default.lua`) needs a tool installed:

1. WSL -- `xclip`; WSLg bridges it to the windows clipboard
2. Fedora -- `wl-clipboard` on wayland, `xclip` on X11
3. windows -- `scoop install win32yank`, otherwise every paste spawns powershell

Neovim finds all three on its own, except on WSL where `_default.lua` names
xclip outright: autodetection scans `$PATH` for every tool it misses, and the
`/mnt/c` entries make that ~190ms of each startup. `:checkhealth vim.provider`
shows which was picked.

Selecting text flashes a blue `copied` chip in the tab bar for a second or two.
wezterm fires no event when the clipboard is written, so `wezterm/wezterm.lua`
hangs the chip off the three bindings that finish a selection -- drag, double
click, triple click -- keeping their stock `ClipboardAndPrimarySelection`.

It is built to survive wezterm updates. Right status is only ever written from
this config, so a wezterm that ships its own indicator sits alongside rather
than fighting it. The bindings go through `pcall`, because naming a dropped
action raises as the config loads and would take the leader table with it --
instead that click falls back to wezterm's default, so the copy still happens.

`wezterm.gui` has no accessor for default *mouse* bindings, so the clipboard
argument is pinned by hand. To recheck it against a nightly, diff `wezterm
show-keys` against the same run over a `return {}` config.

## The wezterm UI

wezterm runs `tokyonight_night`, the same scheme as nvim. The ANSI palette was
stock before, so shell output and the editor disagreed on every colour.

The chrome at the top of `wezterm/wezterm.lua` derives from that same palette,
so terminal, editor and tab bar are one system. Two tokens are lightened for
UI duty -- `comment` at 2.91:1 and `terminal_black` at 1.91:1 are fine as
syntax and too dark as chrome. Every colour clears WCAG AA on the surface it
sits on, 3:1 for non-text.

The tab bar stays at the **top**, because every overlay -- tab navigator,
`PaneSelect`, command palette -- opens from the top of the pane, and a bottom
bar would put the tab list at the far end of the window from the tabs.

It reports three things a modal, split-heavy setup otherwise hides:

- **LEADER** while the leader is armed, so the 1s window is visible
- **zoom**, since `LEADER o` hides every other pane and the count then lies
- the **pane count**, dimmed at one pane -- true, but nothing to act on

The active tab is marked by an accent bar and brighter text. The bar is a
shape rather than a shade, because the two tab surfaces differ by only
1.27:1 -- too little to be the only thing telling them apart. Tabs are
numbered because `SHIFT+CTRL+<n>` jumps to one.

Each tab shows an icon for what is running in it, the way an editor tab shows
a file type. The process name is enough on Fedora and for windows-side panes,
but every WSL pane reports `wslhost.exe`, so a program has to name itself in
the title instead: nvim sets `titlestring = 'nvim: %t'`, and wezterm reads
that prefix for the icon and shows the filename as the tab name. Anything
unrecognised gets a shell icon. Every glyph used was checked with `wezterm
ls-fonts --text` rather than assumed.

Inactive panes are dimmed, which is what makes the focused one obvious and
lets the split lines stay quiet. The new-tab and close buttons are gone; tabs
open and close from the keyboard, and one of those buttons was a misclick that
closed work. `LEADER p` opens the command palette. The bell is a cursor tint
rather than a beep.

`hide_tab_bar_if_only_one_tab` stays off on purpose -- leader, zoom and copied
all report in that bar.

## lazygit and yazi wear the same palette

Both shipped unthemed while nvim and wezterm ran tokyonight, so three tools in
one window disagreed on every colour. `lazygit/config.yml` and
`yazi/theme.toml` now use the same tokens.

Borders in both use a lightened `terminal_black`: the scheme's own `#414868`
is 1.91:1 against the background, under the 3:1 WCAG asks of a meaningful
non-text boundary. It is fine as syntax and too dark as chrome, the same
adjustment the wezterm chrome makes.

lazygit's `nerdFontsVersion` was empty, which means it drew no file icons at
all; it is `'3'` now, matching the glyph range the rest of these configs use.

## kdiff3 as the merge and difftool

Optional. The draw is the three-way merge -- a middle pane carrying the base
-- and `git difftool -d`, which folder-compares the whole tree against any ref.

The settings live in `git/kdiff3.gitconfig`. It is not a link: both installers
add an include to `~/.gitconfig` instead, so one edit here reaches every box.

```ini
[include]
	path = <repo>/git/kdiff3.gitconfig
```

`git config --global --list` will not show them without `--includes`; they are
active all the same. git ships a kdiff3 definition and finds the binary on
`$PATH`. The binary is not shared -- it is a GUI app, so every environment
needs its own, the two windows checkouts included.

1. WSL / Ubuntu -- `sudo apt install kdiff3`
2. Fedora -- `sudo dnf install kdiff3`
3. windows -- `winget install KDE.KDiff3`
4. macos -- `brew install --cask kdiff3`

Use `KDE.KDiff3`. The `JoachimEibl.KDiff3` beside it is 0.9.98, from before the
project moved to KDE.

It has to be on the side the calling git runs on. `git difftool` stages blobs
under `/tmp/git-blob-XXXXXX`, and a windows kdiff3 or a flatpak resolves those
in a filesystem of its own -- two empty panes. `git mergetool` keeps its
`.BASE`, `.LOCAL` and `.REMOTE` in the repo, so it works either way. Test
difftool first.

A blank grey window under WSL is WSLg, not kdiff3. If `LIBGL_ALWAYS_SOFTWARE=1`
is blank too, run `wsl --update` then `wsl --shutdown`. The `[WARN:COPY MODE]`
title prefix is unrelated and stays.

`lazygit/config.yml` puts `<ctrl+t>` on the commits panel for a folder diff
against the selected commit, and `T` in the files panel for the working tree
against `HEAD`; lazygit has `<ctrl+t>` everywhere else already.

Both run `bin/git-treediff`, not `git difftool -d`, which copies only the
changed files into its temp dirs. The script extracts the whole commit with
`git archive` and diffs it against the working tree, so every folder is there.
The right pane is live -- saving in kdiff3 writes to your files -- and
untracked files sit on that side alone. Needs `~/.local/bin` on `$PATH` and a
POSIX shell, so run lazygit inside WSL on a windows box.

1.12.4 everywhere but Ubuntu 24.04 -- 1.10.7, and no backport. 26.04 has 1.12.4.
