@echo off
rem The cmd half of bash/yazi-cd.bash. No setlocal: a batch file runs in this
rem cmd, which is what makes the cd stick. Run `y`, not `yazi`.

set "yazicwd=%TEMP%\yazi-cwd.%RANDOM%"
rem call, so a yazi that is itself a .cmd shim returns here
call yazi %* --cwd-file="%yazicwd%"
for /f "usebackq delims=" %%d in ("%yazicwd%") do cd /d "%%d"
del "%yazicwd%" 2>nul
set "yazicwd="
