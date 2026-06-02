#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Using Xcode:"
xcodebuild -version

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods is not installed. Installing with gem..."
  sudo gem install cocoapods
fi

pod install --repo-update

BUILD_DIR="$ROOT_DIR/build"
PACKAGE_DIR="$ROOT_DIR/nativeplugins/Rokid-CXRL"
IOS_DIR="$PACKAGE_DIR/ios"
DIST_DIR="$ROOT_DIR/dist"
BUILD_LOG="$DIST_DIR/build-ios-plugin.log"
RESULT_BUNDLE="$DIST_DIR/RokidCXRLBuild.xcresult"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$IOS_DIR" "$DIST_DIR"
rm -rf "$IOS_DIR"/*.framework

set +e
xcodebuild \
  -workspace "$ROOT_DIR/RokidCXRLUniPlugin.xcworkspace" \
  -scheme RokidCXRLUniPlugin \
  -configuration Release \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -resultBundlePath "$RESULT_BUNDLE" \
  BUILD_DIR="$BUILD_DIR" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CODE_SIGNING_ALLOWED=NO \
  clean build 2>&1 | tee "$BUILD_LOG"
build_status=${PIPESTATUS[0]}
set -e

if [ "$build_status" -ne 0 ]; then
  echo "xcodebuild failed with status $build_status"
  echo "Recent diagnostics from $BUILD_LOG:"
  grep -nE "(error:|warning:|BUILD FAILED|The following build commands failed)" "$BUILD_LOG" | tail -80 || true
  exit "$build_status"
fi

copy_framework() {
  local name="$1"
  local source=""

  for candidate in \
    "$BUILD_DIR/Release-iphoneos/$name.framework" \
    "$BUILD_DIR/Release-iphoneos/$name/$name.framework" \
    "$ROOT_DIR/Vendor/$name.framework" \
    "$ROOT_DIR/Pods/$name/$name.framework"; do
    if [ -d "$candidate" ]; then
      source="$candidate"
      break
    fi
  done

  if [ -z "$source" ]; then
    echo "Missing framework: $name" >&2
    exit 1
  fi

  ditto "$source" "$IOS_DIR/$name.framework"
}

copy_framework "RokidCXRLUniPlugin"
copy_framework "RGCxrClient"
copy_framework "RGCoreKit"
copy_framework "CocoaLumberjack"

ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_DIR" "$DIST_DIR/Rokid-CXRL.zip"
echo "Packaged $DIST_DIR/Rokid-CXRL.zip"
