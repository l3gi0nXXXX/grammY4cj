#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
PLATFORM="$REPO_DIR/src/platform/platform.cj"
MOD="$REPO_DIR/src/mod.cj"
MANIFEST="$REPO_DIR/src/architecture/root_public_export_manifest.tsv"
OPTIONAL_PLAN="$REPO_DIR/src/architecture/optional_integration_test_plan.tsv"
CJPM="$REPO_DIR/cjpm.toml"

failures=0

fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

require_file() {
  if [ ! -f "$1" ]; then
    fail "missing ${1#$REPO_DIR/}"
  fi
}

require_fixed() {
  file="$1"
  needle="$2"
  label="$3"
  if grep -F "$needle" "$file" >/dev/null 2>&1; then
    printf 'ok %s\n' "$label"
  else
    fail "$label"
  fi
}

require_file "$PLATFORM"
require_file "$MOD"
require_file "$MANIFEST"
require_file "$OPTIONAL_PLAN"
require_file "$CJPM"

if [ -f "$PLATFORM" ]; then
  require_fixed "$PLATFORM" 'PlatformRuntimeContract("deno", "oak", "empty-object", "ReadableStream.from(asyncIterable)", "debug-skypack-deno-env")' "deno facade mirrors upstream platform.deno.ts"
  require_fixed "$PLATFORM" 'PlatformRuntimeContract("node", "express", "node-http-https-keepAlive-agent", "Readable.from(asyncIterable)", "debug-node")' "node facade mirrors upstream platform.node.ts"
  require_fixed "$PLATFORM" 'PlatformRuntimeContract("web", "cloudflare", "empty-object", "manual-readable-stream", "debug-skypack-web")' "web facade mirrors upstream platform.web.ts"
  require_fixed "$PLATFORM" 'public let DEFAULT_CALLBACK_ADAPTER: String = "callback"' "callback adapter is explicit"
  require_fixed "$PLATFORM" 'public let DEFAULT_WEBHOOK_ADAPTER: String = "oak"' "package default adapter is not callback"
  require_fixed "$PLATFORM" 'PlatformPackageExportContract(' "package conditional export contract is represented"
  require_fixed "$PLATFORM" 'cjpm-single-static-root-no-conditional-export' "cjpm package boundary is documented"
  require_fixed "$PLATFORM" 'cangjie-no-type-only-runtime-split' "type-only export boundary is documented"
  require_fixed "$PLATFORM" 'public func mergeBaseFetchConfigForRuntime' "platform baseFetchConfig override merge helper"
fi

if [ -f "$MOD" ]; then
  for export_name in PlatformAdapter PlatformRuntimeContract BaseFetchConfig ByteIterator ByteStream denoPlatform nodePlatform webPlatform defaultAdapterForRuntime baseFetchConfigForRuntime itrToStreamForRuntime; do
    require_fixed "$MOD" "public import grammy4cj.platform.$export_name" "root exports $export_name"
  done
fi

if [ -f "$MANIFEST" ]; then
  for export_name in PlatformAdapter PlatformRuntimeContract BaseFetchConfig ByteIterator ByteStream denoPlatform nodePlatform webPlatform defaultAdapterForRuntime baseFetchConfigForRuntime itrToStreamForRuntime; do
    if awk -F '\t' -v name="$export_name" 'NR > 1 && $1 == name && $2 == "grammy4cj.platform" && $3 == "public" {found = 1} END {exit found ? 0 : 1}' "$MANIFEST"; then
      printf 'ok manifest includes platform export %s\n' "$export_name"
    else
      fail "manifest missing platform export $export_name"
    fi
  done
fi

if [ -f "$OPTIONAL_PLAN" ]; then
  require_fixed "$OPTIONAL_PLAN" 'R4.PLATFORM.FAKE' "optional matrix includes platform fake gate"
  require_fixed "$OPTIONAL_PLAN" 'R4.PLATFORM.REAL.LOOPBACK' "optional matrix includes platform loopback gate"
fi

if [ -f "$CJPM" ]; then
  require_fixed "$CJPM" 'name = "grammy4cj"' "cjpm package name"
  require_fixed "$CJPM" 'output-type = "static"' "cjpm static package entry"
fi

if [ "$failures" -ne 0 ]; then
  printf 'platform gate checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'platform gate checks passed\n'
