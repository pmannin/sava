@echo off

cd /D %~dp0

gawk.exe -f ylista.awk "%TEMP%\ylista.txt"

if "%1"=="/P" echo.&&pause
