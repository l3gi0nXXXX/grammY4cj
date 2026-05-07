#!/usr/bin/env sh
set -eu

check_forbidden() {
  group="$1"
  pattern="$2"
  paths="$3"
  if rg -n "$pattern" $paths >/tmp/grammy4cj_dependency_boundary_match.txt 2>/dev/null; then
    echo "dependency boundary violation in $group:"
    cat /tmp/grammy4cj_dependency_boundary_match.txt
    rm -f /tmp/grammy4cj_dependency_boundary_match.txt
    exit 1
  fi
  rm -f /tmp/grammy4cj_dependency_boundary_match.txt
}

check_forbidden "core" 'import grammy4cj\.(bot|context|composer|convenience|platform)' 'src/core/*.cj'
check_forbidden "context" 'import grammy4cj\.platform' 'src/context/*.cj'
check_forbidden "platform" 'import grammy4cj\.(bot|context)' 'src/platform/*.cj'
check_forbidden "convenience" 'import grammy4cj\.(core\.ApiClient|bot)' 'src/convenience/*.cj'

echo "dependency boundary checks passed"
