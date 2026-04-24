@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
set "EXITCODE=0"

:: =========================================================
:: AUTO ELEVATE (Steam is often under Program Files)
:: =========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process '%~f0' -Verb RunAs"
    exit /b 0
)

title steam-ram-usage deploy

:: =========================================================
:: CONFIG
:: =========================================================
set "DLL_NAME=umpdc.dll"

:: Raw file on repo default branch (change user/repo if you fork).
set "DLL_URL=https://raw.githubusercontent.com/akahobby/steam-ram-usage/main/umpdc.dll"

:: Process to close before copying (blank = skip).
set "LOCKING_PROCESS=steam.exe"

:: =========================================================
:: UI (optional colors)
:: =========================================================
for /f "delims=" %%A in ('echo prompt $E^| cmd') do set "ESC=%%A"
set "C_RESET=!ESC![0m"
set "C_OK=!ESC![92m"
set "C_WARN=!ESC![93m"
set "C_ERR=!ESC![91m"
set "C_INFO=!ESC![96m"
set "C_DIM=!ESC![90m"

cls
echo !C_INFO!==============================================!C_RESET!
echo !C_INFO! steam-ram-usage - deploy !DLL_NAME!!C_RESET!
echo !C_INFO!==============================================!C_RESET!
echo.

:: =========================================================
:: Resolve Steam install folder (HKCU\Software\Valve\Steam\SteamPath)
:: =========================================================
set "STEAMDIR="
set "STEAM_TMP=%TEMP%\nosteam_steampath_%RANDOM%%RANDOM%.txt"
powershell -NoProfile -Command "try { (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath | Out-File -Encoding ascii -NoNewline '%STEAM_TMP%' } catch { }" >nul 2>&1
if exist "%STEAM_TMP%" (
    for /f "usebackq delims=" %%I in ("%STEAM_TMP%") do set "STEAMDIR=%%I"
    del /f /q "%STEAM_TMP%" >nul 2>&1
)

if not defined STEAMDIR (
    echo !C_ERR![x]!C_RESET! Could not read SteamPath from the registry.
    echo !C_DIM!Is Steam installed and has it been run at least once?!C_RESET!
    set "EXITCODE=1"
    goto :END
)

if not exist "!STEAMDIR!\steam.exe" (
    echo !C_ERR![x]!C_RESET! steam.exe not found under:
    echo !C_DIM!!STEAMDIR!!C_RESET!
    set "EXITCODE=1"
    goto :END
)

echo !C_OK![OK]!C_RESET! Steam folder:
echo !C_DIM!!STEAMDIR!!C_RESET!
echo.

:: =========================================================
:: Download DLL (same flow as discordfix.bat)
:: =========================================================
set "TEMP_DIR=%TEMP%\nosteam_deploy_%RANDOM%%RANDOM%"
mkdir "!TEMP_DIR!" >nul 2>&1
if errorlevel 1 (
    echo !C_ERR![x]!C_RESET! Failed to create temp folder.
    set "EXITCODE=1"
    goto :END
)
set "TEMP_DLL=!TEMP_DIR!\!DLL_NAME!"

echo !C_INFO![i]!C_RESET! Downloading !DLL_NAME!...
echo.

call :Download "!DLL_URL!" "!TEMP_DLL!"
if errorlevel 1 (
    set "EXITCODE=1"
    goto :END
)

:: =========================================================
:: Close Steam if running
:: =========================================================
if not "!LOCKING_PROCESS!"=="" (
    echo !C_INFO![i]!C_RESET! Checking for "!LOCKING_PROCESS!"...
    tasklist /fi "imagename eq !LOCKING_PROCESS!" | find /i "!LOCKING_PROCESS!" >nul
    if errorlevel 1 (
        echo !C_OK![OK]!C_RESET! Process not running.
    ) else (
        echo !C_WARN![!]!C_RESET! Terminating Steam...
        taskkill /f /im "!LOCKING_PROCESS!" >nul 2>&1
        set "WAITCOUNT=0"
        :waitloop
        timeout /t 1 /nobreak >nul
        tasklist /fi "imagename eq !LOCKING_PROCESS!" | find /i "!LOCKING_PROCESS!" >nul
        if not errorlevel 1 (
            set /a WAITCOUNT+=1
            if !WAITCOUNT! LSS 15 goto waitloop
        )
        tasklist /fi "imagename eq !LOCKING_PROCESS!" | find /i "!LOCKING_PROCESS!" >nul
        if not errorlevel 1 (
            echo !C_ERR![x]!C_RESET! Steam is still running. Close it manually and run this script again.
            set "EXITCODE=1"
            goto :END
        )
        echo !C_OK![OK]!C_RESET! Steam closed.
    )
    echo.
)

:: =========================================================
:: Copy
:: =========================================================
set "DEST=!STEAMDIR!\!DLL_NAME!"
echo !C_INFO![i]!C_RESET! Installing...
echo !C_DIM!To: !DEST!!C_RESET!
copy /y "!TEMP_DLL!" "!DEST!" >nul
if errorlevel 1 (
    echo !C_ERR![x]!C_RESET! Copy failed. Try Run as administrator, or check folder permissions.
    set "EXITCODE=1"
    goto :END
)

echo.
echo !C_OK![OK]!C_RESET! Done. Start Steam from this installation when you are ready.
set "EXITCODE=0"
goto :END

:: =========================================================
:Download
set "URL=%~1"
set "OUT=%~2"
set "CURL_EXE=%SystemRoot%\System32\curl.exe"

if not exist "!CURL_EXE!" (
    echo !C_ERR![x]!C_RESET! curl.exe not found in System32.
    exit /b 1
)

echo !C_INFO![^>]!C_RESET! !URL!
"!CURL_EXE!" -L --fail "!URL!" -o "!OUT!"
if errorlevel 1 (
    echo !C_ERR![x]!C_RESET! Download failed. Ensure !DLL_NAME! exists on main at akahobby/steam-ram-usage, or edit DLL_URL in this script.
    exit /b 1
)
if not exist "!OUT!" exit /b 1
for %%F in ("!OUT!") do if %%~zF LSS 1 (
    echo !C_ERR![x]!C_RESET! Downloaded file is empty.
    exit /b 1
)
echo !C_OK![OK]!C_RESET! Downloaded.
exit /b 0

:END
if defined TEMP_DIR rd /s /q "!TEMP_DIR!" >nul 2>&1
if defined STEAM_TMP del /f /q "%STEAM_TMP%" >nul 2>&1
if not defined EXITCODE set "EXITCODE=0"
echo.
echo !C_DIM!Press any key to close...!C_RESET!
pause >nul
exit /b !EXITCODE!
