#!/usr/bin/env bash
# Run UIGalleryTests on a simulator and open the resulting gallery.
# Usage: scripts/ui-gallery/run-local.sh [out-dir]   (SIM_ID=<udid> to pick a simulator)
set -euo pipefail

cd "$(dirname "$0")/../.."
out="${1:-/tmp/ui-gallery}"
result=/tmp/ui-gallery.xcresult
sim="${SIM_ID:-iPhone 16 Pro}"

if [[ -n "${SIM_ID:-}" ]]; then
  destination="platform=iOS Simulator,id=$SIM_ID"
else
  destination="platform=iOS Simulator,name=$sim"
fi

xcrun simctl boot "$sim" 2>/dev/null || true  # already booted is fine
xcodegen generate
rm -rf "$result"
# Test failures (missing anchors) still produce screenshots, so build the gallery regardless.
xcodebuild test \
  -scheme AnNien-Dev \
  -configuration Debug-Development \
  -destination "$destination" \
  -only-testing:AnNienUITests/UIGalleryTests \
  -resultBundlePath "$result" || echo "warning: some gallery tests failed; building gallery anyway" >&2

rm -rf "$out"
scripts/ui-gallery/build-gallery.sh "$result" "$out"
open "$out/index.html"
