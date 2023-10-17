@echo off

mkdir  "%LocalAppdata%\nvim" > NUL 2>&1
del    "%LocalAppdata%\nvim\init.lua" > NUL 2>&1
mklink "%LocalAppdata%\nvim\init.lua" "%~dp0..\init.lua"

pause
