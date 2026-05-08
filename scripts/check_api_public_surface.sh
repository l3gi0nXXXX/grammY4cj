#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
API="$REPO_DIR/src/core/api.cj"
TABLE="$REPO_DIR/src/core/api_wrapper_table.cj"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/grammy4cj-api-surface.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

failures=0

fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

extract_table_func() {
  awk -v fn="$1" '
    $0 ~ "public func " fn "\\(" { in_table = 1; next }
    in_table && /^}/ { in_table = 0 }
    in_table {
      line = $0
      while (match(line, /"[^"]+"/)) {
        value = substr(line, RSTART + 1, RLENGTH - 2)
        print value
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$TABLE"
}

extract_table_func apiWrapperMethodNames | sort -u > "$TMP_DIR/wrapper"
extract_table_func apiRawZeroArgMethodNames | sort -u > "$TMP_DIR/zero_arg"

perl -ne 'if (/^\s*"([^"~]+)~/) { print "$1\n" }' "$TABLE" | sort -u > "$TMP_DIR/schema"
perl -ne 'if (/^\s*"([^"~]+)~[^~]*~[^~]*~[^~]*~[^~]*~([^~]*)~/ && $2 ne "") { print "$1\n" }' "$TABLE" | sort -u > "$TMP_DIR/typed"
perl -ne 'if (/^public class Api\b/) {$in = 1; next} if ($in && /^}/) {$in = 0} if ($in && /^    public func (?!endpointFor\b|call\b|callResult\b|use\b)([A-Za-z_]\w*)\(/) { print "$1\n" }' "$API" | sort -u > "$TMP_DIR/api"

wrapper_count="$(wc -l < "$TMP_DIR/wrapper" | tr -d ' ')"
raw_count="$(wc -l < "$TMP_DIR/schema" | tr -d ' ')"
zero_count="$(wc -l < "$TMP_DIR/zero_arg" | tr -d ' ')"
typed_count="$(wc -l < "$TMP_DIR/typed" | tr -d ' ')"
api_count="$(wc -l < "$TMP_DIR/api" | tr -d ' ')"

printf 'api wrapper=%s raw facade=%s zero-arg=%s typed-result=%s public-methods=%s\n' \
  "$wrapper_count" "$raw_count" "$zero_count" "$typed_count" "$api_count"

[ "$wrapper_count" = "180" ] || fail "wrapper method count must be 180"
[ "$raw_count" = "180" ] || fail "raw facade method count must be 180"
[ "$zero_count" = "8" ] || fail "zero-arg raw method count must be 8"
[ "$typed_count" = "180" ] || fail "typed result mapping count must be 180"
[ "$api_count" = "180" ] || fail "Api public wrapper count must be 180"

if ! grep -q 'public class ApiResult<T>' "$API"; then
  fail "missing ApiResult<T> public typed result shell"
fi

if ! grep -q 'public func getMe(): ApiResult<User>' "$API"; then
  fail "getMe must return ApiResult<User>"
fi

if ! grep -q 'public func getUpdates(): ApiResult<ArrayList<Update>>' "$API"; then
  fail "getUpdates must return typed Update array result"
fi

if ! grep -q 'public func sendMessage(chatId: Int64, text: String): ApiResult<Message>' "$API"; then
  fail "sendMessage must return typed Message result"
fi

if ! comm -3 "$TMP_DIR/wrapper" "$TMP_DIR/schema" | sed 's/^/  /' > "$TMP_DIR/diff"; then
  :
fi
if [ -s "$TMP_DIR/diff" ]; then
  printf 'wrapper/raw schema drift:\n'
  cat "$TMP_DIR/diff"
  fail "wrapper names and raw facade names differ"
fi

if [ "$failures" -ne 0 ]; then
  printf 'api public surface checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'api public surface checks passed\n'
