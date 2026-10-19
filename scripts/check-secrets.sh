#!/usr/bin/env bash
# Pre-commit hook: block staging of sensitive files
set -euo pipefail
BLOCKED='\.p8$|\.p12$|\.mobileprovision$|Secrets\.xcconfig$|^\.env$|^\.env\.'
if git diff --cached --name-only | grep -qE "$BLOCKED"; then
  echo "error: sensitive file staged. Unstage it (git reset HEAD <file>)" >&2
  git diff --cached --name-only | grep -E "$BLOCKED" >&2
  exit 1
fi
