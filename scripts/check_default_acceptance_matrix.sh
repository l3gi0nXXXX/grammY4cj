#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
MATRIX="$REPO_DIR/src/architecture/default_acceptance_matrix.tsv"
EXPECTED_HEADER='acceptance_area	category	gate	owner_artifact	default_command	opt_in_gate	network	file_io	server	token_policy	acceptance'

failures=0

fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

if [ ! -f "$MATRIX" ]; then
  fail "missing src/architecture/default_acceptance_matrix.tsv"
else
  actual_header="$(sed -n '1p' "$MATRIX")"
  if [ "$actual_header" = "$EXPECTED_HEADER" ]; then
    printf 'ok header src/architecture/default_acceptance_matrix.tsv\n'
  else
    printf 'FAIL header src/architecture/default_acceptance_matrix.tsv\n'
    printf '  expected: %s\n' "$EXPECTED_HEADER"
    printf '  actual:   %s\n' "$actual_header"
    failures=$((failures + 1))
  fi
fi

if [ -f "$MATRIX" ]; then
  row_count="$(awk -F '\t' 'NR > 1 && $1 != "" {count += 1} END {print count + 0}' "$MATRIX")"
  bad_width="$(awk -F '\t' 'NR > 1 && $1 != "" && NF != 11 {bad += 1} END {print bad + 0}' "$MATRIX")"
  bad_category="$(awk -F '\t' '
    NR > 1 && $1 != "" && $1 != "source_drift" && $1 != "semantic_parity" && $1 != "formal_substitute_debt" {bad += 1}
    END {print bad + 0}
  ' "$MATRIX")"
  missing_category="$(awk -F '\t' '
    NR > 1 && $1 != "" {seen[$1] = 1}
    END {
      if (!seen["source_drift"]) missing += 1
      if (!seen["semantic_parity"]) missing += 1
      if (!seen["formal_substitute_debt"]) missing += 1
      print missing + 0
    }
  ' "$MATRIX")"
  bad_default_side_effect="$(awk -F '\t' '
    NR > 1 && $1 != "" && $6 == "none" && ($7 != "no" || $8 != "no" || $9 != "no" || $10 != "no-token") {bad += 1}
    END {print bad + 0}
  ' "$MATRIX")"
  opt_in_without_gate="$(awk -F '\t' '
    NR > 1 && $1 != "" && $6 != "none" && index($6, "GRAMMY4CJ_OPTIONAL_") == 0 {bad += 1}
    END {print bad + 0}
  ' "$MATRIX")"
  package_rows="$(awk -F '\t' 'NR > 1 && $2 ~ /root_package_surface|package_entry_smoke|language_boundary/ {count += 1} END {print count + 0}' "$MATRIX")"

  printf 'default acceptance matrix rows=%s package_rows=%s\n' "$row_count" "$package_rows"
  if [ "$row_count" -lt 9 ]; then
    fail "default acceptance matrix must contain at least 9 rows"
  fi
  if [ "$bad_width" != "0" ]; then
    fail "default acceptance matrix rows with wrong column count=$bad_width"
  fi
  if [ "$bad_category" != "0" ]; then
    fail "default acceptance matrix invalid categories=$bad_category"
  fi
  if [ "$missing_category" != "0" ]; then
    fail "default acceptance matrix missing required categories=$missing_category"
  fi
  if [ "$bad_default_side_effect" != "0" ]; then
    fail "default acceptance matrix default rows with side effects=$bad_default_side_effect"
  fi
  if [ "$opt_in_without_gate" != "0" ]; then
    fail "default acceptance matrix opt-in rows without GRAMMY4CJ_OPTIONAL gate=$opt_in_without_gate"
  fi
  if [ "$package_rows" -lt 3 ]; then
    fail "default acceptance matrix must cover package/root/language-boundary rows"
  fi

  awk -F '\t' 'NR > 1 && $1 != "" {print $4}' "$MATRIX" |
    tr ';' '\n' |
    while IFS= read -r artifact; do
      [ -n "$artifact" ] || continue
      case "$artifact" in
        cjpm) continue ;;
      esac
      if [ ! -e "$REPO_DIR/$artifact" ]; then
        printf 'FAIL missing referenced artifact: %s\n' "$artifact"
        exit 1
      fi
    done || failures=$((failures + 1))
fi

if [ "$failures" -ne 0 ]; then
  printf 'default acceptance matrix checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'default acceptance matrix checks passed\n'
