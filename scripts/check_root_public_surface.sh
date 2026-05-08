#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
MOD="$REPO_DIR/src/mod.cj"
MANIFEST="$REPO_DIR/src/architecture/root_public_export_manifest.tsv"
EXPECTED_HEADER='export_name	module	category	upstream_anchor	note'
EXPECTED_ROOT_EXPORTS="59"
EXPECTED_MANIFEST_ROWS="59"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/grammy4cj-root-surface.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

failures=0

record_failure() {
  failures=$((failures + 1))
}

fail() {
  printf 'FAIL %s\n' "$1"
  record_failure
}

if [ ! -f "$MOD" ]; then
  fail "missing src/mod.cj"
fi

if [ ! -f "$MANIFEST" ]; then
  fail "missing src/architecture/root_public_export_manifest.tsv"
fi

if [ -f "$MANIFEST" ]; then
  actual_header="$(sed -n '1p' "$MANIFEST")"
  if [ "$actual_header" = "$EXPECTED_HEADER" ]; then
    printf 'ok root public export manifest header\n'
  else
    printf 'FAIL root public export manifest header\n'
    printf '  expected: %s\n' "$EXPECTED_HEADER"
    printf '  actual:   %s\n' "$actual_header"
    record_failure
  fi
fi

if [ -f "$MOD" ]; then
  awk '
    $1 == "public" && $2 == "import" {
      n = split($3, parts, ".")
      print parts[n]
    }
    $1 == "public" && ($2 == "let" || $2 == "var") {
      name = $3
      sub(/:.*/, "", name)
      print name
    }
    $1 == "public" && $2 == "func" {
      name = $3
      sub(/\(.*/, "", name)
      print name
    }
  ' "$MOD" | sort > "$TMP_DIR/root_exports"
fi

if [ -f "$MANIFEST" ]; then
  awk -F '\t' 'NR > 1 && $1 != "" {print $1}' "$MANIFEST" | sort > "$TMP_DIR/manifest_exports"
  awk -F '\t' '
    NR > 1 && $1 != "" {
      if (NF != 5) bad += 1
      if ($3 != "public" && $3 != "expert-public" && $3 != "internal" && $3 != "test-only") bad_category += 1
      key = $1
      seen[key] += 1
      if (seen[key] == 2) duplicate += 1
      if (($3 == "public" || $3 == "expert-public") && index($4, "grammY/src/mod.ts:") != 1) bad_anchor += 1
    }
    END {
      printf "%d %d %d %d\n", bad + 0, bad_category + 0, duplicate + 0, bad_anchor + 0
    }
  ' "$MANIFEST" > "$TMP_DIR/manifest_quality"

  read -r bad_width bad_category duplicate_names bad_anchor < "$TMP_DIR/manifest_quality"
  if [ "$bad_width" != "0" ]; then
    fail "root public export manifest rows with wrong column count=$bad_width"
  fi
  if [ "$bad_category" != "0" ]; then
    fail "root public export manifest rows with invalid category=$bad_category"
  fi
  if [ "$duplicate_names" != "0" ]; then
    fail "root public export manifest duplicate export names=$duplicate_names"
  fi
  if [ "$bad_anchor" != "0" ]; then
    fail "public/expert root exports without upstream mod.ts anchor=$bad_anchor"
  fi
fi

if [ -f "$TMP_DIR/root_exports" ] && [ -f "$TMP_DIR/manifest_exports" ]; then
  comm -23 "$TMP_DIR/root_exports" "$TMP_DIR/manifest_exports" > "$TMP_DIR/unclassified"
  comm -13 "$TMP_DIR/root_exports" "$TMP_DIR/manifest_exports" > "$TMP_DIR/stale"
  unclassified_count="$(wc -l < "$TMP_DIR/unclassified" | tr -d ' ')"
  stale_count="$(wc -l < "$TMP_DIR/stale" | tr -d ' ')"
  root_count="$(wc -l < "$TMP_DIR/root_exports" | tr -d ' ')"
  manifest_count="$(wc -l < "$TMP_DIR/manifest_exports" | tr -d ' ')"

  printf 'root public exports=%s manifest rows=%s\n' "$root_count" "$manifest_count"
  if [ "$root_count" != "$EXPECTED_ROOT_EXPORTS" ]; then
    fail "root public export count drift expected=$EXPECTED_ROOT_EXPORTS actual=$root_count"
  fi
  if [ "$manifest_count" != "$EXPECTED_MANIFEST_ROWS" ]; then
    fail "root public export manifest row count drift expected=$EXPECTED_MANIFEST_ROWS actual=$manifest_count"
  fi
  if [ "$unclassified_count" != "0" ]; then
    printf 'unclassified root exports:\n'
    sed 's/^/  /' "$TMP_DIR/unclassified"
    record_failure
  fi
  if [ "$stale_count" != "0" ]; then
    printf 'stale manifest exports not present in root:\n'
    sed 's/^/  /' "$TMP_DIR/stale"
    record_failure
  fi
fi

for forbidden in \
  ApiWrapperSchemaTrace \
  CoreHttpRequest \
  FrameworkAdapterContract \
  FakeWebhookUpdateHandler \
  NoopCoreFetch \
  adapterHandlerReturnKind \
  frameworkAdapterContracts \
  platformInputFileRawContract \
  telegramInputFileAliasTrace
do
  if [ -f "$TMP_DIR/root_exports" ] && grep -Fx "$forbidden" "$TMP_DIR/root_exports" >/dev/null 2>&1; then
    fail "internal/test-only export leaked from root: $forbidden"
  fi
done

if [ "$failures" -ne 0 ]; then
  printf 'root public surface checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'root public surface checks passed\n'
