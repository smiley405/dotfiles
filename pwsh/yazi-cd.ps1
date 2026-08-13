# The windows half of bash/yazi-cd.bash, which carries the reasoning. Run `y`,
# not `yazi`; `Q` quits without moving the shell, `q` brings the directory back.

function y {
	$tmp = [System.IO.Path]::GetTempFileName()

	yazi $args --cwd-file="$tmp"

	$cwd = Get-Content -LiteralPath $tmp -Encoding UTF8
	if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
		Set-Location -LiteralPath $cwd
	}

	Remove-Item -LiteralPath $tmp
}
