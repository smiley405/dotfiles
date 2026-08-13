#!/usr/bin/env bash
#
# Links this checkout into place on linux, macos and WSL; windows uses
# install.ps1. Idempotent, and anything real in the way is moved aside.

set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config=${XDG_CONFIG_HOME:-$HOME/.config}
bindir=$HOME/.local/bin

# under WSL wezterm is windows-side, so that checkout owns wezterm/
is_wsl() { [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; }

is_macos() { [ "$(uname)" = Darwin ]; }

info() { printf '  %s\n' "$*"; }

# sourced by path, not symlinked: ~/.bashrc keeps its distro contents
bashrc_source() {
	local file=$1 why=$2

	if grep -qF "$file" "$HOME/.bashrc" 2>/dev/null; then
		info "ok      ~/.bashrc already sources $file"
		return
	fi

	{
		printf '\n# dotfiles: %s\n' "$why"
		printf 'if [ -f "%s/bash/%s" ]; then\n' "$repo" "$file"
		printf '\t. "%s/bash/%s"\n' "$repo" "$file"
		printf 'fi\n'
	} >> "$HOME/.bashrc"
	info "append  ~/.bashrc now sources $file"
}

link() {
	local src=$1 dst=$2 backup

	# portable, and enough to spot a link pointing somewhere else
	if [ -L "$dst" ] && [ "$(readlink -- "$dst")" = "$src" ]; then
		info "ok      $dst"
		return
	fi

	mkdir -p -- "$(dirname -- "$dst")"
	if [ -e "$dst" ] && [ ! -L "$dst" ]; then
		backup=$dst.bak.$(date +%Y%m%d%H%M%S)
		mv -- "$dst" "$backup"
		info "backup  $dst -> $backup"
	fi

	ln -sfn -- "$src" "$dst"
	info "link    $dst -> $src"
}

printf 'dotfiles: linking from %s\n' "$repo"

link "$repo/nvim" "$config/nvim"
link "$repo/yazi" "$config/yazi"

# lazygit is the exception: macos reads Application Support, unless
# XDG_CONFIG_HOME is set, which lazygit honours there too
if is_macos && [ -z "${XDG_CONFIG_HOME:-}" ]; then
	link "$repo/lazygit" "$HOME/Library/Application Support/lazygit"
else
	link "$repo/lazygit" "$config/lazygit"
fi
for script in yazi-wez reveal; do
	link "$repo/bin/$script" "$bindir/$script"
	# never fatal: set -e would otherwise abandon the rest of the install
	chmod +x "$repo/bin/$script" 2>/dev/null || info "note    could not chmod +x bin/$script"
done

if is_wsl; then
	info "skip    wezterm (windows-side under WSL -- run install.ps1 there)"
else
	link "$repo/wezterm" "$config/wezterm"
fi

printf 'dotfiles: shell integration\n'

# every platform, unlike the OSC 7 block below
bashrc_source yazi-cd.bash 'y() -- yazi, leaving the shell where you exited'

# OSC 7: the terminal is a windows app and the shell is in the VM, so /proc is
# out of reach and only the escape sequence gets through.
if is_wsl; then
	bashrc_source wsl-shell-integration.bash 'OSC 7 cwd reporting (wezterm tab/split inherits cwd under WSL)'
fi

printf 'dotfiles: git\n'

# not a link: git reads the settings through an include in ~/.gitconfig.
# --add, since a plain set would replace an include that is already there
kdiff3_conf=$repo/git/kdiff3.gitconfig
if git config --global --get-all include.path 2>/dev/null | grep -qxF "$kdiff3_conf"; then
	info "ok      git includes kdiff3.gitconfig"
else
	git config --global --add include.path "$kdiff3_conf"
	info "config  git now includes kdiff3.gitconfig"
fi

printf 'dotfiles: dependencies\n'
for tool in nvim yazi lazygit rg fd jq wezterm; do
	if command -v "$tool" >/dev/null 2>&1; then
		info "ok      $tool"
	elif [ "$tool" = wezterm ] && command -v wezterm.exe >/dev/null 2>&1; then
		info "ok      wezterm (wezterm.exe via WSL interop)"
	else
		info "MISSING $tool"
	fi
done

case ":${PATH-}:" in
	*":$bindir:"*) ;;
	*) info "note    $bindir is not on \$PATH -- yazi's <C-o>/<C-t>/<C-e> need it there" ;;
esac
