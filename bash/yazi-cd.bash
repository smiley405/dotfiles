# yazi cannot cd the shell that started it, so it writes the directory it
# exited from and the wrapper does the cd. Run `y`, not `yazi`; `Q` quits
# without moving the shell, `q` brings the directory back.

y() {
	local tmp cwd
	tmp=$(mktemp -t yazi-cwd.XXXXXX) || return

	yazi "$@" --cwd-file="$tmp"

	# -d '': a path holds anything but NUL
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"

	rm -f -- "$tmp"
}
