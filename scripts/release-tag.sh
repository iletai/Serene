#!/usr/bin/env bash
# Create and push an annotated release tag.
# Usage: scripts/release-tag.sh 1.0.0
set -euo pipefail

VERSION="${1:?Usage: scripts/release-tag.sh <major.minor.patch>}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must match MAJOR.MINOR.PATCH (e.g. 1.0.0)" >&2
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "warning: currently on '$CURRENT_BRANCH', release tags should typically be cut from 'main'" >&2
fi

TAG="v$VERSION"
echo "Creating release tag $TAG on $(git rev-parse --short HEAD)"
git tag -a "$TAG" -m "Release $TAG"
echo "Tag $TAG created locally. To push to remote, run:"
echo "  git push origin $TAG"
