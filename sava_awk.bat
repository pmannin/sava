@echo off

cd /D %~dp0

gawk.exe -f sava.awk "%TEMP%\sava.txt"

if "%1"=="/P" echo.&&pause
