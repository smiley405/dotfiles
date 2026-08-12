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

Write-Host "dotfiles: linking from $repo"

Set-Junction -Target (Join-Path $repo 'nvim')    -Link (Join-Path $env:LOCALAPPDATA 'nvim')
Set-Junction -Target (Join-Path $repo 'yazi')    -Link (Join-Path $env:APPDATA 'yazi\config')
Set-Junction -Target (Join-Path $repo 'wezterm') -Link (Join-Path $env:USERPROFILE '.config\wezterm')

# yazi calls `yazi-wez` by bare name, which needs bin\yazi-wez.cmd on PATH
Write-Host 'dotfiles: PATH'
Add-UserPath -Dir $bin

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
