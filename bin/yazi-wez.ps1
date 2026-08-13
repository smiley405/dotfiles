#!/usr/bin/env pwsh
#
# yazi <-> neovim over wezterm panes -- the windows half of bin/yazi-wez, with
# the same pick/edit/pane subcommands; see that script for the design.
#
# A windows pane is spawned by the mux and inherits its environment, so none of
# the unix login-shell/PATH/cd juggling applies -- wezterm's --cwd covers it.
# yazi reaches `edit` through bin/yazi-wez.cmd.

[CmdletBinding()]
param(
	[Parameter(Position = 0)]
	[string]$Subcommand,

	[Parameter(Position = 1, ValueFromRemainingArguments = $true)]
	[string[]]$Argv
)

$ErrorActionPreference = 'Stop'
# pwsh 7.3+ makes a nonzero native exit terminating; we check $LASTEXITCODE
# ourselves. Inert on 5.1.
$PSNativeCommandUseErrorActionPreference = $false

if (-not $Argv) { $Argv = @() }

function Die($message) {
	[Console]::Error.WriteLine("yazi-wez: $message")
	exit 1
}

function Warn($message) {
	[Console]::Error.WriteLine("yazi-wez: $message")
}

# WEZTERM_CLI mirrors the unix script's override; otherwise the windows binary.
$Wezterm = if ($env:WEZTERM_CLI) {
	$env:WEZTERM_CLI
} elseif (Get-Command 'wezterm.exe' -ErrorAction SilentlyContinue) {
	'wezterm.exe'
} else {
	'wezterm'
}

# WEZTERM_PANE covers almost every case; else the least idle client acted last.
function Get-CallerPane {
	if ($env:WEZTERM_PANE) { return $env:WEZTERM_PANE }

	$json = & $Wezterm cli list-clients --format json 2>$null | Out-String
	if ($LASTEXITCODE -ne 0 -or -not $json.Trim()) { return $null }

	try { $clients = @($json | ConvertFrom-Json) } catch { return $null }
	if (-not $clients.Count) { return $null }

	$first = $clients | Sort-Object { $_.idle_time.secs } | Select-Object -First 1
	if ($null -eq $first.focused_pane_id) { return $null }
	return [string]$first.focused_pane_id
}

function Invoke-Pick {
	param([string]$Server, [string]$Pane, [string]$Start)

	if (-not $Server -or -not $Pane) {
		Die 'usage: yazi-wez pick <nvim-server> <nvim-pane-id|-> [start-path]'
	}

	$chooser = [System.IO.Path]::GetTempFileName()

	# let a nested `edit` reach the nvim that spawned us
	$env:YAZI_WEZ_NVIM = $Server
	$env:YAZI_WEZ_PANE = if ($Pane -eq '-') { $null } else { $Pane }

	try {
		if ($Start -and (Test-Path -LiteralPath $Start)) {
			& yazi "--chooser-file=$chooser" $Start
		} else {
			& yazi "--chooser-file=$chooser"
		}

		# empty when yazi was quit with q/<Esc>
		$files = @(Get-Content -LiteralPath $chooser -Encoding UTF8 -ErrorAction SilentlyContinue |
			Where-Object { $_ -ne '' })

		if ($files.Count) {
			& nvim --server $Server --remote @files
			if ($LASTEXITCODE -ne 0) { Warn "could not reach nvim at $Server" }
		}
	} finally {
		Remove-Item -LiteralPath $chooser -Force -ErrorAction SilentlyContinue
		if ($Pane -ne '-') { & $Wezterm cli activate-pane --pane-id $Pane | Out-Null }
	}
}

function Invoke-Edit {
	param([string[]]$Rest)

	$mode = 'split'
	$reuse = $true
	$paths = [System.Collections.Generic.List[string]]::new()

	# flags only until the first path, matching the unix script
	$parsing = $true
	foreach ($arg in $Rest) {
		if ($parsing) {
			if ($arg -eq '--tab') { $mode = 'tab'; continue }
			if ($arg -eq '--new') { $mode = 'split'; $reuse = $false; continue }
			if ($arg -eq '--') { $parsing = $false; continue }
			$parsing = $false
		}
		$paths.Add($arg)
	}
	if (-not $paths.Count) { exit 0 }

	# a nvim is already waiting for us -- reuse it
	if ($reuse -and $env:YAZI_WEZ_NVIM) {
		& nvim --server $env:YAZI_WEZ_NVIM --remote @($paths)
		if ($LASTEXITCODE -ne 0) { Die "could not reach nvim at $($env:YAZI_WEZ_NVIM)" }
		if ($env:YAZI_WEZ_PANE) {
			& $Wezterm cli activate-pane --pane-id $env:YAZI_WEZ_PANE | Out-Null
		}
		return
	}

	$caller = Get-CallerPane
	if (-not $caller) { Die 'no focused wezterm pane -- is this running under wezterm?' }

	$dir = Split-Path -Parent -Path $paths[0]
	if (-not $dir) { $dir = '.' }

	if ($mode -eq 'tab') {
		& $Wezterm cli spawn --pane-id $caller --cwd $dir -- nvim @($paths) | Out-Null
	} else {
		# --left so nvim lands where it usually sits, yazi keeps the side
		& $Wezterm cli split-pane --pane-id $caller --left --percent 60 --cwd $dir -- nvim @($paths) |
			Out-Null
	}
}

switch ($Subcommand) {
	'pick' { Invoke-Pick -Server $Argv[0] -Pane $Argv[1] -Start $Argv[2] }
	'edit' { Invoke-Edit -Rest $Argv }
	'pane' { Get-CallerPane }
	default { Die 'usage: yazi-wez {pick|edit|pane} [args...]' }
}
