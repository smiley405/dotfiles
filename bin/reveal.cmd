@echo off
rem The windows half of bin/reveal. yazi's `shell` runs through cmd, which
rem resolves .cmd but never a bare bash script. Needs bin\ on PATH.
setlocal
set "dir=%~1"
if not defined dir set "dir=."
rem explorer wants a full path, and exits 1 even when it worked
for %%d in ("%dir%") do set "full=%%~fd"
explorer "%full%"
exit /b 0
