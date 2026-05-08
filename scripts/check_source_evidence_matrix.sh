#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
MATRIX="$REPO_DIR/src/architecture/source_evidence_matrix.tsv"
EXPECTED_HEADER='kind	upstream_path	upstream_anchor	public_surface	functions_classes	control_flow_anchors	error_branch_anchors	grammY4cj_modules	gap	phase	test_files	current_anchor	test_anchor	coverage_notes'

if [ -z "${GRAMMY_DIR:-}" ]; then
  GRAMMY_DIR="$REPO_DIR/../grammY"
  if [ ! -d "$GRAMMY_DIR" ] && [ -d "$REPO_DIR/../../grammY" ]; then
    GRAMMY_DIR="$REPO_DIR/../../grammY"
  fi
fi

if [ ! -d "$GRAMMY_DIR" ]; then
  printf 'GRAMMY_DIR must point to the upstream grammY checkout (default: ../grammY or ../../grammY)\n'
  exit 2
fi

GRAMMY_DIR="$(CDPATH= cd "$GRAMMY_DIR" && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/grammy4cj-evidence.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
failures=0

fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

check_path_list() {
  base="$1"
  label="$2"
  paths="$3"
  old_ifs="$IFS"
  IFS=';'
  for path in $paths; do
    if [ -z "$path" ]; then
      fail "$label has empty path segment"
    elif [ "$path" != "n/a" ] && [ ! -e "$base/$path" ]; then
      fail "$label missing path: $path"
    fi
  done
  IFS="$old_ifs"
}

if [ ! -f "$MATRIX" ]; then
  fail "missing source evidence matrix: $MATRIX"
else
  header="$(sed -n '1p' "$MATRIX")"
  if [ "$header" = "$EXPECTED_HEADER" ]; then
    printf 'ok source evidence matrix header\n'
  else
    fail "source evidence matrix header mismatch"
    printf '  expected: %s\n' "$EXPECTED_HEADER"
    printf '  actual:   %s\n' "$header"
  fi
fi

if [ -f "$MATRIX" ]; then
  summary_file="$TMP_DIR/summary"
  awk -F '\t' '
      NR > 1 && $1 != "" {
        total += 1
        if (NF != 14) printf "bad_width\t%d\t%d\n", NR, NF
        if ($1 == "runtime") runtime += 1
        else if ($1 == "test") test += 1
        else printf "bad_kind\t%d\t%s\n", NR, $1
        if ($2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" || $7 == "" || $8 == "" || $9 == "" || $10 == "" || $11 == "" || $12 == "" || $13 == "") {
          printf "empty_required\t%d\n", NR
        }
        split($9, gaps, ",")
        for (i in gaps) {
          gap = gaps[i]
          if (gap ~ /^GAP-[0-9][0-9]$/ && $3 != "" && $12 != "" && $13 != "") covered[gap] = 1
        }
      }
      END {
        printf "summary\t%d\t%d\t%d\n", runtime + 0, test + 0, total + 0
        for (i = 1; i <= 12; i++) {
          gap = sprintf("GAP-%02d", i)
          if (!covered[gap]) printf "missing_gap\t%s\n", gap
        }
      }
    ' "$MATRIX" > "$summary_file"

  while IFS="$(printf '\t')" read -r tag a b c; do
    case "$tag" in
      bad_width) fail "matrix row $a has wrong column count $b" ;;
      bad_kind) fail "matrix row $a has invalid kind $b" ;;
      empty_required) fail "matrix row $a has empty required evidence field" ;;
      missing_gap) fail "matrix lacks upstream/current/test anchors for $a" ;;
    esac
  done < "$summary_file"

  runtime_rows="$(awk -F '\t' '$1 == "summary" {print $2}' "$summary_file")"
  test_rows="$(awk -F '\t' '$1 == "summary" {print $3}' "$summary_file")"
  total_rows="$(awk -F '\t' '$1 == "summary" {print $4}' "$summary_file")"
  printf 'source evidence matrix rows: runtime=%s test=%s total=%s\n' "$runtime_rows" "$test_rows" "$total_rows"
  if [ "$runtime_rows" != "25" ]; then fail "source evidence matrix runtime rows expected=25 actual=$runtime_rows"; fi
  if [ "$test_rows" != "18" ]; then fail "source evidence matrix test rows expected=18 actual=$test_rows"; fi

  while IFS="$(printf '\t')" read -r kind upstream_path _upstream_anchor _public _funcs _flow _errors modules _gap _phase tests _current_anchor _test_anchor _notes; do
    if [ "$kind" = "kind" ] || [ -z "$kind" ]; then
      continue
    fi
    if [ ! -f "$GRAMMY_DIR/$upstream_path" ]; then
      fail "missing upstream evidence source: $upstream_path"
    fi
    check_path_list "$REPO_DIR" "matrix modules for $upstream_path" "$modules"
    check_path_list "$REPO_DIR" "matrix tests for $upstream_path" "$tests"
  done < "$MATRIX"
fi

if [ "$failures" -ne 0 ]; then
  printf 'source evidence matrix checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'source evidence matrix checks passed\n'
