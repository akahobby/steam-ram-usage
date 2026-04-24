@echo off
setlocal EnableExtensions

:: Prefer UCRT64 GCC (same as MSYS2 UCRT64 shell)
if exist "C:\msys64\ucrt64\bin\gcc.exe" set "PATH=C:\msys64\ucrt64\bin;%PATH%"

cd /d "%~dp0src"

rd /q /s "bin" 2>nul
md "bin"

gcc.exe -Oz -Wl,--gc-sections,--exclude-all-symbols -municode -shared -nostdlib -s "Library.c" -lntdll -lwtsapi32 -lkernel32 -luser32 -ladvapi32 -lshell32 -o "bin\umpdc.dll"
if errorlevel 1 (
    echo Build failed. Install MSYS2 UCRT64 and: pacman -S mingw-w64-ucrt-x86_64-gcc
    exit /b 1
)

copy /y "bin\umpdc.dll" "%~dp0umpdc.dll" >nul
echo OK: src\bin\umpdc.dll and %~dp0umpdc.dll
