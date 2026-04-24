# steam-ram-usage

Small DLL you drop next to **Steam** so the built-in browser (CEF) stays mostly off while a game is running. Valve removed the old `-no-browser` flag; this is a rough substitute.

## Install

**Easy way:** run **`steamfix.bat`** as Administrator. It finds your Steam folder, closes Steam if it is open, downloads **`umpdc.dll`** from this repo’s `main` branch, and copies it beside **`steam.exe`**.

**Manual way:** close Steam, copy **`umpdc.dll`** into the same folder as **`steam.exe`**, start Steam again.

Optional: add **`-silent`** to Steam’s launch options so the store/browser does not pop back on its own.

The DLL also adds a tray icon: right‑click it to force the web helper on or off.

## Build

1. Install [MSYS2](https://www.msys2.org), open the **UCRT64** terminal, then:

   `pacman -Syu --noconfirm`  
   `pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-gcc`

2. From normal **cmd**, go to this repo folder and run **`Build.cmd`**.

You get **`src\bin\umpdc.dll`** and a copy at the repo root **`umpdc.dll`** (that one is what GitHub’s raw URL serves for **`steamfix.bat`**).

## Heads‑up

Steam updates can break this. Use at your own risk.
