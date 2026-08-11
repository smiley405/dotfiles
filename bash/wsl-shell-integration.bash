# OSC 7 -- tell the terminal the shell's cwd, so new tabs and splits inherit it.
#
# Terminals otherwise read /proc/<pid>/cwd, which fails under WSL: the terminal
# is a Windows app and the shell lives in the VM. Ubuntu ships no emitter.
# Consumed by kitty, foot, ghostty, konsole, VTE and Windows Terminal too.

# Empty authority == localhost (RFC 8089); avoids a WSL/Windows hostname match.
__wezterm_osc7() {
	printf '\033]7;file://%s\033\\' "$PWD"
}

# Don't stack duplicates if ~/.bashrc is re-sourced.
case "$PROMPT_COMMAND" in
	*__wezterm_osc7*) ;;
	*) PROMPT_COMMAND="__wezterm_osc7${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
