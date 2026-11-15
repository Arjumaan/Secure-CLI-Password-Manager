@echo off
echo ===================================================
echo     SecureVault Cross-Platform Build Helper
echo ===================================================
echo.

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [-] Flutter SDK is not detected in your PATH.
    echo [*] Please install Flutter from https://docs.flutter.dev/get-started/install/windows
    echo [*] Once installed and added to PATH, re-run this script.
    pause
    exit /b 1
)

echo [+] Flutter detected. Fetching packages...
cd /d "%~dp0securevault_app"
call flutter pub get

echo.
echo Select target build:
echo [1] Build Windows Desktop (.exe)
echo [2] Build Android (.apk)
echo [3] Build Both
echo.
set /p choice="Enter choice (1-3): "

if "%choice%"=="1" (
    echo [*] Building Windows release .exe...
    call flutter build windows --release
    echo [✔] Executable built in securevault_app\build\windows\x64\runner\Release\
) else if "%choice%"=="2" (
    echo [*] Building Android release .apk...
    call flutter build apk --release
    echo [✔] APK built in securevault_app\build\app\outputs\flutter-apk\
) else if "%choice%"=="3" (
    echo [*] Building Windows release .exe...
    call flutter build windows --release
    echo [*] Building Android release .apk...
    call flutter build apk --release
    echo [✔] Both builds completed!
) else (
    echo [-] Invalid selection.
)

pause
