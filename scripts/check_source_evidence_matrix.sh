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

normalize_anchor_path() {
  anchor="$1"
  path="${anchor%%:*}"
  case "$path" in
    grammY/*) path="${path#grammY/}" ;;
    grammY4cj/*) path="${path#grammY4cj/}" ;;
  esac
  printf '%s\n' "$path"
}

anchor_line() {
  anchor="$1"
  line="${anchor##*:}"
  case "$line" in
    ''|*[!0-9]*) printf '0\n' ;;
    *) printf '%s\n' "$line" ;;
  esac
}

check_anchor_list() {
  base="$1"
  label="$2"
  anchors="$3"
  old_ifs="$IFS"
  IFS=';'
  for anchor in $anchors; do
    if [ -z "$anchor" ]; then
      fail "$label has empty anchor segment"
    elif [ "$anchor" != "n/a" ]; then
      path="$(normalize_anchor_path "$anchor")"
      line="$(anchor_line "$anchor")"
      file="$base/$path"
      if [ "$line" = "0" ]; then
        fail "$label has invalid anchor line: $anchor"
      elif [ ! -f "$file" ]; then
        fail "$label missing anchor file: $anchor"
      else
        max_line="$(awk 'END {print NR + 0}' "$file")"
        if [ "$line" -gt "$max_line" ]; then
          fail "$label anchor line out of range: $anchor max=$max_line"
        fi
      fi
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
        split($10, phase_parts, ",")
        for (i in phase_parts) {
          part = phase_parts[i]
          if (part ~ /^GAP-[0-9][0-9]\.[0-9]+$/) {
            phases[part] = 1
          } else if (part ~ /^GAP-[0-9][0-9]\.[0-9]+\.\.GAP-[0-9][0-9]\.[0-9]+$/) {
            split(part, range, /\.\./)
            split(range[1], start, /[.-]/)
            split(range[2], stop, /[.-]/)
            if (start[2] != stop[2]) {
              printf "bad_phase_range\t%d\t%s\n", NR, part
            } else {
              for (phase = start[3]; phase <= stop[3]; phase++) {
                phases[sprintf("GAP-%s.%d", start[2], phase)] = 1
              }
            }
          } else {
            printf "bad_phase\t%d\t%s\n", NR, part
          }
        }
      }
      END {
        printf "summary\t%d\t%d\t%d\n", runtime + 0, test + 0, total + 0
        for (i = 1; i <= 12; i++) {
          gap = sprintf("GAP-%02d", i)
          if (!covered[gap]) printf "missing_gap\t%s\n", gap
        }
        for (gap_num = 1; gap_num <= 12; gap_num++) {
          max_phase = gap_num <= 2 ? 6 : 5
          for (phase = 1; phase <= max_phase; phase++) {
            gap_phase = sprintf("GAP-%02d.%d", gap_num, phase)
            expected += 1
            if (gap_phase in phases) covered_phases += 1
            else printf "missing_phase\t%s\n", gap_phase
          }
        }
        printf "phase_summary\t%d\t%d\n", covered_phases + 0, expected + 0
      }
    ' "$MATRIX" > "$summary_file"

  while IFS="$(printf '\t')" read -r tag a b c; do
    case "$tag" in
      bad_width) fail "matrix row $a has wrong column count $b" ;;
      bad_kind) fail "matrix row $a has invalid kind $b" ;;
      bad_phase) fail "matrix row $a has invalid phase expression $b" ;;
      bad_phase_range) fail "matrix row $a has invalid cross-gap phase range $b" ;;
      empty_required) fail "matrix row $a has empty required evidence field" ;;
      missing_gap) fail "matrix lacks upstream/current/test anchors for $a" ;;
      missing_phase) fail "matrix lacks source admission evidence for $a" ;;
    esac
  done < "$summary_file"

  runtime_rows="$(awk -F '\t' '$1 == "summary" {print $2}' "$summary_file")"
  test_rows="$(awk -F '\t' '$1 == "summary" {print $3}' "$summary_file")"
  total_rows="$(awk -F '\t' '$1 == "summary" {print $4}' "$summary_file")"
  covered_phases="$(awk -F '\t' '$1 == "phase_summary" {print $2}' "$summary_file")"
  expected_phases="$(awk -F '\t' '$1 == "phase_summary" {print $3}' "$summary_file")"
  printf 'source evidence matrix rows: runtime=%s test=%s total=%s\n' "$runtime_rows" "$test_rows" "$total_rows"
  printf 'source evidence matrix phases: covered=%s expected=%s\n' "$covered_phases" "$expected_phases"
  if [ "$runtime_rows" != "25" ]; then fail "source evidence matrix runtime rows expected=25 actual=$runtime_rows"; fi
  if [ "$test_rows" != "18" ]; then fail "source evidence matrix test rows expected=18 actual=$test_rows"; fi
  if [ "$covered_phases" != "62" ]; then fail "source evidence matrix GAP phase coverage expected=62 actual=$covered_phases"; fi

  while IFS="$(printf '\t')" read -r kind upstream_path _upstream_anchor _public _funcs _flow _errors modules _gap _phase tests _current_anchor _test_anchor _notes; do
    if [ "$kind" = "kind" ] || [ -z "$kind" ]; then
      continue
    fi
    if [ ! -f "$GRAMMY_DIR/$upstream_path" ]; then
      fail "missing upstream evidence source: $upstream_path"
    fi
    check_path_list "$REPO_DIR" "matrix modules for $upstream_path" "$modules"
    check_path_list "$REPO_DIR" "matrix tests for $upstream_path" "$tests"
    check_anchor_list "$GRAMMY_DIR" "upstream anchor for $upstream_path" "$_upstream_anchor"
    check_anchor_list "$REPO_DIR" "current anchor for $upstream_path" "$_current_anchor"
    check_anchor_list "$REPO_DIR" "test anchor for $upstream_path" "$_test_anchor"
  done < "$MATRIX"
fi

if [ "$failures" -ne 0 ]; then
  printf 'source evidence matrix checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'source evidence matrix checks passed\n'
