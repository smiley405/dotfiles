@echo off
rem yazi's `shell` runs through cmd, which resolves .cmd via PATHEXT but never
rem .ps1 -- hence this stub. Needs bin\ on PATH; install.ps1 sees to that.
setlocal
set "PS=powershell"
where /q pwsh.exe && set "PS=pwsh"
"%PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0yazi-wez.ps1" %*
exit /b %ERRORLEVEL%
