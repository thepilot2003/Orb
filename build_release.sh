#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
DIST_DIR="${PROJECT_DIR}/dist"
APP_NAME="Orb"
SCHEME="Orb"

echo "==> Building ${APP_NAME} in Release configuration..."
rm -rf "${BUILD_DIR}" "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

xcodebuild -project "${PROJECT_DIR}/${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    clean build

RELEASE_APP="${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "${RELEASE_APP}" ]; then
    echo "Error: Release build failed. ${RELEASE_APP} not found."
    exit 1
fi

echo "==> Copying built app to dist..."
cp -R "${RELEASE_APP}" "${DIST_DIR}/${APP_NAME}.app"

echo "==> Ad-hoc signing app bundle for distribution..."
codesign --force --deep --sign - "${DIST_DIR}/${APP_NAME}.app"

echo "==> Creating Release Zip..."
cd "${DIST_DIR}"
zip -r -q -y "${APP_NAME}-v2.0.0-macOS.zip" "${APP_NAME}.app"

echo "==> Creating Release DMG Installer..."
DMG_STAGING="${BUILD_DIR}/dmg_staging"
mkdir -p "${DMG_STAGING}"
cp -R "${DIST_DIR}/${APP_NAME}.app" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_STAGING}" \
    -ov -format UDZO \
    "${DIST_DIR}/${APP_NAME}-v2.0.0.dmg"

echo "==> Distribution artifacts ready in ${DIST_DIR}:"
ls -lh "${DIST_DIR}"
echo "==> Release build completed successfully!"
