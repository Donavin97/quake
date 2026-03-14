#!/bin/bash

# --- Configuration ---
PACKAGE_NAME="com.liebgott.eqtrack"
FIREBASE_APP_ID="1:349946205462:android:182c1177801f64925eac37"
PLAY_STORE_JSON_KEY="playstore-api-key.json" # Path to your Google Play Service Account JSON key
TRACK="internal" # internal, alpha, beta, production

# Paths
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
NOTES_FILE="RELEASE-NOTES.md"
PLAY_NOTES_FILE="playstore_release_notes.md"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Distribution for QuakeTrack...${NC}"

# 1. Distribute to Firebase App Distribution
echo -e "\n${BLUE}Step 1: Distributing to Firebase Beta Group...${NC}"
if [ -f "$APK_PATH" ]; then
    firebase appdistribution:distribute "$APK_PATH" \
        --app "$FIREBASE_APP_ID" \
        --groups "beta" \
        --release-notes-file "$NOTES_FILE"
    echo -e "${GREEN}Firebase Distribution Complete.${NC}"
else
    echo "Error: APK not found at $APK_PATH. Run 'flutter build apk --release' first."
fi

# 2. Distribute to Google Play Store (using Fastlane Supply)
echo -e "\n${BLUE}Step 2: Distributing to Google Play Store ($TRACK track)...${NC}"
if [ -f "$AAB_PATH" ]; then
    if [ -f "$PLAY_STORE_JSON_KEY" ]; then
        # Create a temporary directory for Fastlane release notes (it expects a specific structure)
        mkdir -p fastlane/metadata/android/en-US/changelogs/
        cat "$PLAY_NOTES_FILE" > "fastlane/metadata/android/en-US/changelogs/default.txt"

        fastlane supply --aab "$AAB_PATH" \
            --json_key "$PLAY_STORE_JSON_KEY" \
            --package_name "$PACKAGE_NAME" \
            --track "$TRACK" \
            --skip_upload_metadata true \
            --skip_upload_images true \
            --skip_upload_screenshots true

        echo -e "${GREEN}Google Play Store Upload Complete.${NC}"
    else
        echo "Warning: Play Store JSON key not found at $PLAY_STORE_JSON_KEY. Skipping Play Store upload."
        echo "To enable, place your service account JSON key in the project root."
    fi
else
    echo "Error: AAB not found at $AAB_PATH. Run 'flutter build appbundle --release' first."
fi

echo -e "\n${GREEN}All distribution tasks attempted.${NC}"
