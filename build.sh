#!/bin/bash

# Get current date in YYYY-MM-DD format
BUILD_DATE=$(date "+%Y-%m-%d")
BUILD_VERSION="6.6.6"
BUILD_NUMBER="10000"

if [ "$1" = "debug" ]; then
    echo "Building TV APK [Debug]..."
    flutter build apk --debug \
      --target=lib/main_tv.dart \
      --split-per-abi \
      --target-platform=android-arm,android-arm64 \
      --build-name=$BUILD_VERSION \
      --build-number=$BUILD_NUMBER \
      --dart-define=BUILD_DATE=$BUILD_DATE \
      --dart-define=BUILD_VERSION=$BUILD_VERSION \
      --flavor=tv
    
    APK_NAME="app-arm64-v8a-tv-debug.apk"
    RUN_CMD="flutter run --use-application-binary ./build/app/outputs/flutter-apk/$APK_NAME"
else
    echo "Building TV APK [Release + Obfuscation]..."
    flutter build apk --release \
      --target=lib/main_tv.dart \
      --split-per-abi \
      --obfuscate \
      --split-debug-info=./build/app/outputs/flutter-apk/ \
      --target-platform=android-arm,android-arm64 \
      --build-name=$BUILD_VERSION \
      --build-number=$BUILD_NUMBER \
      --dart-define=BUILD_DATE=$BUILD_DATE \
      --dart-define=BUILD_VERSION=$BUILD_VERSION \
      --flavor=tv
    
    APK_NAME="app-arm64-v8a-tv-release.apk"
    RUN_CMD="flutter run --use-application-binary ./build/app/outputs/flutter-apk/$APK_NAME"
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "========================================================"
    echo "BUILD FAILED! Check the error messages above."
    echo "========================================================"
    exit 1
fi

echo ""
echo "Build completed!"
echo "========================================================"
echo "To install the APK on a connected TV/device, use ADB:"
echo "  adb install -r ./build/app/outputs/flutter-apk/$APK_NAME"
echo ""
echo "Or, to run directly on the device:"
echo "  $RUN_CMD"
echo "========================================================"
