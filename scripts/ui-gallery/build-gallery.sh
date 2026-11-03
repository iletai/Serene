#!/usr/bin/env bash
# Build the UI gallery from a test result bundle.
# Usage: scripts/ui-gallery/build-gallery.sh <path.xcresult> <out-dir>
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <path.xcresult> <out-dir>" >&2
  exit 64
fi

result="$1"
out="$2"
export_dir="$(mktemp -d)"
trap 'rm -rf "$export_dir"' EXIT

# Xcode 16+: writes every attachment plus manifest.json.
xcrun xcresulttool export attachments --path "$result" --output-path "$export_dir"
python3 -I "$(dirname "$0")/gallery.py" "$export_dir" "$out"
