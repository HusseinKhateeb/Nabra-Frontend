@echo off
setlocal enabledelayedexpansion

echo [1/4] Checking adb...
where adb >nul 2>&1
if errorlevel 1 (
  echo adb not found in PATH. Install Android platform-tools and reopen terminal.
  exit /b 1
)

echo [2/4] Starting adb server...
adb start-server >nul 2>&1

set DEVICE=
for /f "skip=1 tokens=1" %%D in ('adb devices') do (
  if not "%%D"=="" if not "%%D"=="List" (
    set DEVICE=%%D
    goto :foundDevice
  )
)

:foundDevice
if "%DEVICE%"=="" (
  echo No Android device found. Connect phone with USB, enable USB debugging, and accept RSA prompt.
  exit /b 1
)

echo [3/4] Setting USB reverse tcp:8080 -^> tcp:8080 on %DEVICE%...
adb -s %DEVICE% reverse tcp:8080 tcp:8080
if errorlevel 1 (
  echo Failed to set adb reverse for %DEVICE%.
  exit /b 1
)

echo [4/4] Running Flutter on %DEVICE%...
if "%~1"=="" (
  flutter run -d %DEVICE%
) else (
  flutter run -d %DEVICE% %*
)
