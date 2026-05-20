@echo off
REM ========================================================
REM Enigma CryptoShelter — Tebako build script (Windows)
REM Generates single .exe for Windows
REM Usage: package\build.bat
REM ========================================================

set APP_NAME=enigma_cryptoshelter
set RUBY_VERSION=3.2.2
set OUTPUT=dist\%APP_NAME%.exe

echo [52m╔══════════════════════════════════════╗
echo ║   Enigma CryptoShelter — Packaging   ║
echo ╚══════════════════════════════════════╝
echo.
echo Building for Windows...
echo Output: %OUTPUT%
echo.

if not exist dist mkdir dist

tebako press ^
  --root . ^
  --entry-point main.rb ^
  --output %OUTPUT% ^
  --Ruby %RUBY_VERSION%

echo.
echo Build complete: %OUTPUT%
pause
