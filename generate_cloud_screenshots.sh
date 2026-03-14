#!/bin/bash

# QuakeTrack Cloud Screenshot Generator (Standard Method)
set -e

echo "----------------------------------------------------"
echo "QuakeTrack: Starting Cloud Screenshot Generation"
echo "----------------------------------------------------"

# 1. Build the Application APK (Debug mode for integration tests)
echo "Step 1: Building Debug APK..."
flutter build apk --debug

# 2. Build the Test APK (Instrumentation wrapper)
echo "Step 2: Building Test Wrapper..."
pushd android
./gradlew app:assembleDebugAndroidTest
popd

# 3. Define paths for the generated APKs
APP_APK="build/app/outputs/flutter-apk/app-debug.apk"
TEST_APK="build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"

# 4. Submit to Firebase Test Lab
echo "Step 3: Submitting to Firebase Test Lab..."
gcloud firebase test android run \
  --type instrumentation \
  --app "$APP_APK" \
  --test "$TEST_APK" \
  --timeout 5m \
  --device model=tangorpro,version=33,locale=en,orientation=portrait \
  --device model=gta7lite,version=34,locale=en,orientation=portrait \
  --device model=panther,version=33,locale=en,orientation=portrait \
  --directories-to-pull /sdcard/screenshots

echo "----------------------------------------------------"
echo "SUCCESS: Cloud run submitted."
echo "Screenshots will appear in your Firebase Console."
echo "----------------------------------------------------"
