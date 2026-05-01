@echo off
setlocal

for /f "delims=" %%a in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd'"') do set BUILD_DATE=%%a
set BUILD_VERSION=6.6.6
set BUILD_NUMBER=10000

if "%~1"=="debug" (
    echo Building TV APK [Debug]...
    call flutter build apk --debug ^
      --target=lib/main_tv.dart ^
      --split-per-abi ^
      --target-platform=android-arm,android-arm64 ^
      --build-name=%BUILD_VERSION% ^
      --build-number=%BUILD_NUMBER% ^
      --dart-define=BUILD_DATE=%BUILD_DATE% ^
      --dart-define=BUILD_VERSION=%BUILD_VERSION% ^
      --flavor=tv

    set APK_NAME=app-arm64-v8a-tv-debug.apk
    set RUN_CMD=flutter run --use-application-binary .\build\app\outputs\flutter-apk\app-arm64-v8a-tv-debug.apk
) else (
    echo Building TV APK [Release + Obfuscation]...
    call flutter build apk --release ^
      --target=lib/main_tv.dart ^
      --split-per-abi ^
      --obfuscate ^
      --split-debug-info=.\build\app\outputs\flutter-apk\ ^
      --target-platform=android-arm,android-arm64 ^
      --build-name=%BUILD_VERSION% ^
      --build-number=%BUILD_NUMBER% ^
      --dart-define=BUILD_DATE=%BUILD_DATE% ^
      --dart-define=BUILD_VERSION=%BUILD_VERSION% ^
      --flavor=tv

    set APK_NAME=app-arm64-v8a-tv-release.apk
    set RUN_CMD=flutter run --use-application-binary .\build\app\outputs\flutter-apk\app-arm64-v8a-tv-release.apk
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo ========================================================
    echo BUILD FAILED! Check the error messages above.
    echo ========================================================
    exit /b %ERRORLEVEL%
)

echo.
echo Build completed!
echo ========================================================
echo To install the APK on a connected TV/device, use ADB:
echo   adb install -r .\build\app\outputs\flutter-apk\%APK_NAME%
echo.
echo Or, to run directly on the device:
echo   %RUN_CMD%
echo ========================================================
endlocal
