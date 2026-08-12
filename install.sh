#!/usr/bin/env bash
#
# Links this checkout into place on linux, macos and WSL; windows has its own
# entry point, install.ps1. Idempotent, and anything real sitting where a link
# belongs is moved aside, never deleted.

set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config=${XDG_CONFIG_HOME:-$HOME/.config}
bindir=$HOME/.local/bin

# under WSL wezterm is windows-side, so that checkout owns wezterm/
is_wsl() { [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; }

info() { printf '  %s\n' "$*"; }

link() {
	local src=$1 dst=$2 backup

	# compare with what we would write: portable, and enough to spot a foreign link
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
link "$repo/bin/yazi-wez" "$bindir/yazi-wez"
# never fatal: set -e would otherwise abandon the rest of the install
chmod +x "$repo/bin/yazi-wez" 2>/dev/null || info "note    could not chmod +x bin/yazi-wez"

if is_wsl; then
	info "skip    wezterm (windows-side under WSL -- run install.ps1 there)"
else
	link "$repo/wezterm" "$config/wezterm"
fi

# OSC 7 cwd reporting: under WSL the terminal is a windows app and the shell is
# in the VM, so /proc is out of reach and only the escape sequence gets through.
if is_wsl; then
	printf 'dotfiles: shell integration\n'
	if grep -qF 'wsl-shell-integration.bash' "$HOME/.bashrc" 2>/dev/null; then
		info "ok      ~/.bashrc already sources wsl-shell-integration.bash"
	else
		{
			printf '\n# dotfiles: OSC 7 cwd reporting (wezterm tab/split inherits cwd under WSL)\n'
			printf 'if [ -f "%s/bash/wsl-shell-integration.bash" ]; then\n' "$repo"
			printf '\t. "%s/bash/wsl-shell-integration.bash"\n' "$repo"
			printf 'fi\n'
		} >> "$HOME/.bashrc"
		info "append  ~/.bashrc now sources wsl-shell-integration.bash"
	fi
fi

printf 'dotfiles: dependencies\n'
for tool in nvim yazi rg fd jq wezterm; do
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
	*) info "note    $bindir is not on \$PATH -- yazi's <C-o>/<C-t> need it there" ;;
esac
