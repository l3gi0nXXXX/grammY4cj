#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"

if [ "$#" -gt 0 ]; then
  docs="$*"
else
  docs="README.md CONTRIBUTING.md src/README.md LICENSE"
fi

for doc in $docs; do
  if [ ! -f "$REPO_DIR/$doc" ]; then
    printf 'public docs scan failed: missing %s\n' "$doc"
    exit 1
  fi
done

forbidden='/Users/l3gi0n|workspace_cangjie|cangjie100|rtk'

if command -v rg >/dev/null 2>&1; then
  if (CDPATH= cd "$REPO_DIR" && rg -n "$forbidden" $docs); then
    printf 'public docs scan failed: forbidden local or internal marker found\n'
    exit 1
  fi
else
  if (CDPATH= cd "$REPO_DIR" && grep -En "$forbidden" $docs); then
    printf 'public docs scan failed: forbidden local or internal marker found\n'
    exit 1
  fi
fi

printf 'public docs scan passed: %s\n' "$docs"
