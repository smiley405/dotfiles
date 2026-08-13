#!/usr/bin/env pwsh
#
# Links this checkout into place on windows:
#
#     pwsh -ExecutionPolicy Bypass -File install.ps1
#
# Linux, macos and WSL use install.sh. Directory links are junctions, not
# symlinks: a symlink needs elevation or developer mode, a junction needs
# neither. Idempotent, and anything real in the way is moved aside, not deleted.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$repo = $PSScriptRoot
$bin = Join-Path $repo 'bin'

function Info($message) { Write-Host "  $message" }

function Set-Junction {
	param([string]$Target, [string]$Link)

	if (-not (Test-Path -LiteralPath $Target)) {
		Info "MISSING $Target (skipped)"
		return
	}
	$Target = (Resolve-Path -LiteralPath $Target).Path

	$existing = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
	if ($existing) {
		if ($existing.LinkType) {
			# already a junction/symlink: keep it if it already points at us
			$to = @($existing.Target)[0]
			if ($to -and $to.TrimEnd('\') -eq $Target.TrimEnd('\')) {
				Info "ok      $Link"
				return
			}
			# the reparse point only -- Remove-Item -Recurse would gut the target
			[System.IO.Directory]::Delete($Link, $false)
			Info "relink  $Link (was $to)"
		} else {
			$backup = "$Link.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
			Move-Item -LiteralPath $Link -Destination $backup
			Info "backup  $Link -> $backup"
		}
	}

	$parent = Split-Path -Parent -Path $Link
	if ($parent -and -not (Test-Path -LiteralPath $parent)) {
		New-Item -ItemType Directory -Path $parent -Force | Out-Null
	}

	New-Item -ItemType Junction -Path $Link -Value $Target | Out-Null
	Info "link    $Link -> $Target"
}

function Add-UserPath {
	param([string]$Dir)

	$current = [Environment]::GetEnvironmentVariable('Path', 'User')
	$parts = @()
	if ($current) { $parts = @($current -split ';' | Where-Object { $_ -ne '' }) }

	$have = @($parts | ForEach-Object { $_.TrimEnd('\') })
	if ($have -contains $Dir.TrimEnd('\')) {
		Info "ok      PATH already has $Dir"
		return
	}

	[Environment]::SetEnvironmentVariable('Path', (@($parts) + $Dir -join ';'), 'User')
	# only reaches processes started later; wezterm passes its env to each pane
	Info "path    added $Dir to the user PATH (restart wezterm to pick it up)"
}

function Set-UserEnv {
	param([string]$Name, [string]$Value)

	if ([Environment]::GetEnvironmentVariable($Name, 'User') -eq $Value) {
		Info "ok      $Name already set"
		return
	}

	[Environment]::SetEnvironmentVariable($Name, $Value, 'User')
	Info "env     $Name = $Value (restart wezterm to pick it up)"
}

function Add-ProfileSource {
	param([string]$File, [string]$Why)

	# CurrentUserAllHosts: the console, the VS Code terminal and the ISE all read it
	$profilePath = $PROFILE.CurrentUserAllHosts
	if (-not $profilePath) {
		Info "MISSING no profile path -- skipped $(Split-Path -Leaf $File)"
		return
	}

	if ((Test-Path -LiteralPath $profilePath) -and
			(Select-String -LiteralPath $profilePath -SimpleMatch -Pattern $File -Quiet)) {
		Info "ok      profile already sources $(Split-Path -Leaf $File)"
		return
	}

	$parent = Split-Path -Parent -Path $profilePath
	if ($parent -and -not (Test-Path -LiteralPath $parent)) {
		New-Item -ItemType Directory -Path $parent -Force | Out-Null
	}

	Add-Content -LiteralPath $profilePath -Value @('', "# dotfiles: $Why", ". `"$File`"")
	Info "append  $profilePath now sources $(Split-Path -Leaf $File)"
}

function Find-File1 {
	# git for windows keeps one in usr\bin, off PATH, under either root
	$roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
	$candidates = @($roots | ForEach-Object { Join-Path $_ 'Git\usr\bin\file.exe' })
	$candidates += (Join-Path $env:USERPROFILE 'scoop\apps\git\current\usr\bin\file.exe')

	foreach ($candidate in $candidates) {
		if (Test-Path -LiteralPath $candidate) { return $candidate }
	}
	return $null
}

Write-Host "dotfiles: linking from $repo"

Set-Junction -Target (Join-Path $repo 'nvim')    -Link (Join-Path $env:LOCALAPPDATA 'nvim')
Set-Junction -Target (Join-Path $repo 'yazi')    -Link (Join-Path $env:APPDATA 'yazi\config')
Set-Junction -Target (Join-Path $repo 'wezterm') -Link (Join-Path $env:USERPROFILE '.config\wezterm')

# yazi calls `yazi-wez` by bare name, which needs bin\yazi-wez.cmd on PATH
Write-Host 'dotfiles: PATH'
Add-UserPath -Dir $bin

# the windows half of the ~/.bashrc append in install.sh
Write-Host 'dotfiles: shell integration'
Add-ProfileSource -File (Join-Path $repo 'pwsh\yazi-cd.ps1') `
	-Why 'y -- yazi, leaving the shell where you exited'

# cmd has no functions, so it gets a batch file instead -- already live from the
# PATH entry above, nothing to wire
if (Test-Path -LiteralPath (Join-Path $bin 'y.cmd')) {
	Info "ok      cmd uses bin\y.cmd"
} else {
	Info "MISSING bin\y.cmd"
}

# yazi types files with file(1); without one, `start` claims every file
Write-Host 'dotfiles: file(1)'
if (Get-Command 'file' -ErrorAction SilentlyContinue) {
	Info "ok      file is on PATH"
} else {
	$file1 = Find-File1
	if ($file1) {
		Set-UserEnv -Name 'YAZI_FILE_ONE' -Value $file1
	} else {
		Info "MISSING file -- install git for windows, then re-run"
	}
}

Write-Host 'dotfiles: dependencies'
foreach ($tool in 'nvim', 'yazi', 'rg', 'fd', 'jq', 'wezterm', 'pwsh') {
	if (Get-Command $tool -ErrorAction SilentlyContinue) {
		Info "ok      $tool"
	} elseif ($tool -eq 'pwsh') {
		Info "note    pwsh not found -- falling back to windows powershell 5.1"
	} else {
		Info "MISSING $tool"
	}
}
