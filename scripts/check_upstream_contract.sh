#!/usr/bin/env sh
set -eu

LC_ALL=C
export LC_ALL

EXPECTED_HEAD="c865dd3a4d26911b01c83695e3845c7245870a5d"
EXPECTED_TAG="v1.42.0-5-gc865dd3"
HARD_FAIL="${GRAMMY4CJ_HARD_FAIL:-0}"
ARTIFACT_DIR="${GRAMMY4CJ_ARTIFACT_DIR:-}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --hard-fail|--strict)
      HARD_FAIL=1
      shift
      ;;
    --artifact-dir)
      ARTIFACT_DIR="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1"
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
PARITY_LEDGER="$REPO_DIR/src/architecture/upstream_test_parity_ledger.tsv"
PHASE_STATUS_SOURCE="$REPO_DIR/src/architecture/phase_status.tsv"
GATE_STATUS_SOURCE="$REPO_DIR/src/architecture/gate_status.tsv"

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
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/grammy4cj-upstream.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

failures=0

section() {
  printf '\n== %s ==\n' "$1"
}

count_lines() {
  wc -l < "$1" | tr -d ' '
}

record_failure() {
  failures=$((failures + 1))
}

hard_fail_if_nonzero() {
  name="$1"
  count="$2"
  if [ "$HARD_FAIL" = "1" ] && [ "$count" != "0" ]; then
    printf 'FAIL hard-fail %s count=%s\n' "$name" "$count"
    record_failure
  fi
}

check_eq() {
  name="$1"
  actual="$2"
  expected="$3"
  if [ "$actual" = "$expected" ]; then
    printf 'ok %s=%s\n' "$name" "$actual"
  else
    printf 'FAIL %s expected=%s actual=%s\n' "$name" "$expected" "$actual"
    record_failure
  fi
}

check_ge() {
  name="$1"
  actual="$2"
  minimum="$3"
  if [ "$actual" -ge "$minimum" ]; then
    printf 'ok %s=%s minimum=%s\n' "$name" "$actual" "$minimum"
  else
    printf 'FAIL %s minimum=%s actual=%s\n' "$name" "$minimum" "$actual"
    record_failure
  fi
}

test_count_for() {
  key="$1"
  file="$2"
  awk -v k="$key" '$1 == k {print $2; found = 1} END {if (!found) print 0}' "$file"
}

show_set_diff() {
  title="$1"
  upstream_file="$2"
  port_file="$3"
  missing_file="$TMP_DIR/missing"
  extra_file="$TMP_DIR/extra"

  comm -23 "$upstream_file" "$port_file" > "$missing_file"
  comm -13 "$upstream_file" "$port_file" > "$extra_file"

  missing_count="$(count_lines "$missing_file")"
  extra_count="$(count_lines "$extra_file")"
  printf '%s: missing_in_port=%s extra_in_port=%s\n' "$title" "$missing_count" "$extra_count"
  if [ "$missing_count" != "0" ]; then
    sed 's/^/  missing: /' "$missing_file"
  fi
  if [ "$extra_count" != "0" ]; then
    sed 's/^/  extra: /' "$extra_file"
  fi
}

assert_no_set_diff() {
  title="$1"
  upstream_file="$2"
  port_file="$3"
  missing_file="$TMP_DIR/assert_missing"
  extra_file="$TMP_DIR/assert_extra"

  comm -23 "$upstream_file" "$port_file" > "$missing_file"
  comm -13 "$upstream_file" "$port_file" > "$extra_file"

  missing_count="$(count_lines "$missing_file")"
  extra_count="$(count_lines "$extra_file")"
  if [ "$missing_count" = "0" ] && [ "$extra_count" = "0" ]; then
    printf 'ok %s has no diff\n' "$title"
  else
    printf 'FAIL %s missing_in_port=%s extra_in_port=%s\n' "$title" "$missing_count" "$extra_count"
    if [ "$missing_count" != "0" ]; then
      sed 's/^/  missing: /' "$missing_file"
    fi
    if [ "$extra_count" != "0" ]; then
      sed 's/^/  extra: /' "$extra_file"
    fi
    record_failure
  fi
}

extract_markdown_headings() {
  markdown_file="$1"
  output_file="$2"
  : > "$output_file"
  if [ -f "$markdown_file" ]; then
    grep -E '^#{1,6} ' "$markdown_file" | sed -E 's/^#{1,6}[[:space:]]+//' > "$output_file" || true
  fi
}

check_docs_heading_policy() {
  title="$1"
  policy_file="$2"
  policy_marker="$3"
  upstream_file="$4"
  port_file="$5"
  missing_file="$TMP_DIR/${title}_docs_missing"
  extra_file="$TMP_DIR/${title}_docs_extra"

  comm -23 "$upstream_file" "$port_file" > "$missing_file"
  comm -13 "$upstream_file" "$port_file" > "$extra_file"
  missing_count="$(count_lines "$missing_file")"
  extra_count="$(count_lines "$extra_file")"
  total_count=$((missing_count + extra_count))

  if [ "$total_count" = "0" ]; then
    printf 'ok %s README heading parity has no diff\n' "$title"
  elif grep -F "$policy_marker" "$policy_file" >/dev/null 2>&1; then
    printf 'ok %s README heading diff explicitly exempted missing=%s extra=%s\n' \
      "$title" "$missing_count" "$extra_count"
  else
    printf 'WARN %s README heading diff has no exemption marker missing=%s extra=%s\n' \
      "$title" "$missing_count" "$extra_count"
    hard_fail_if_nonzero "$title README heading policy" "$total_count"
  fi
}

write_phase_status_artifact() {
  if [ ! -f "$PHASE_STATUS_SOURCE" ]; then
    printf 'FAIL missing phase status source: %s\n' "$PHASE_STATUS_SOURCE"
    record_failure
    return
  fi
  if [ ! -f "$GATE_STATUS_SOURCE" ]; then
    printf 'FAIL missing gate status source: %s\n' "$GATE_STATUS_SOURCE"
    record_failure
    return
  fi

  phase_rows="$(awk -F '\t' 'NR > 1 && $1 != "" {count += 1} END {print count + 0}' "$PHASE_STATUS_SOURCE")"
  gate_rows="$(awk -F '\t' 'NR > 1 && $1 != "" {count += 1} END {print count + 0}' "$GATE_STATUS_SOURCE")"
  printf 'phase status source: %s rows=%s\n' "$PHASE_STATUS_SOURCE" "$phase_rows"
  printf 'gate status source: %s rows=%s\n' "$GATE_STATUS_SOURCE" "$gate_rows"

  if [ "$phase_rows" != "63" ]; then
    printf 'FAIL phase status rows expected=63 actual=%s\n' "$phase_rows"
    record_failure
  fi
  if [ "$gate_rows" != "11" ]; then
    printf 'FAIL gate status rows expected=11 actual=%s\n' "$gate_rows"
    record_failure
  fi

  if [ -n "$ARTIFACT_DIR" ]; then
    mkdir -p "$ARTIFACT_DIR"
    phase_artifact="$ARTIFACT_DIR/phase_status.tsv"
    gate_artifact="$ARTIFACT_DIR/gate_status.tsv"
    cp "$PHASE_STATUS_SOURCE" "$phase_artifact"
    cp "$GATE_STATUS_SOURCE" "$gate_artifact"
    printf 'phase status artifact: %s rows=%s\n' "$phase_artifact" "$phase_rows"
    printf 'gate status artifact: %s rows=%s\n' "$gate_artifact" "$gate_rows"
  fi
}

classify_test_parity_mismatches() {
  mismatch_file="$1"
  if [ ! -f "$PARITY_LEDGER" ]; then
    printf 'FAIL missing test parity ledger: %s\n' "$PARITY_LEDGER"
    record_failure
    TEST_PARITY_TRUE_GAPS=0
    TEST_PARITY_LEDGER_ERRORS=1
    return
  fi

  report_file="$TMP_DIR/test_parity_ledger_report"
  summary_file="$TMP_DIR/test_parity_ledger_summary"
  artifact_file=""
  if [ -n "$ARTIFACT_DIR" ]; then
    mkdir -p "$ARTIFACT_DIR"
    artifact_file="$ARTIFACT_DIR/upstream_test_parity_mismatches.tsv"
  fi

  awk -F '\t' -v artifact="$artifact_file" -v summary="$summary_file" '
    BEGIN {
      if (artifact != "") {
        print "key\tupstream_count\tport_count\tclassification\tgate\tupstream_file\tport_files\towner_artifact\trationale" > artifact
      }
    }
    NR == FNR {
      if (FNR > 1 && $1 != "") {
        ledger_upstream[$1] = $2
        ledger_port[$1] = $3
        classification[$1] = $4
        gate[$1] = $5
        upstream_file[$1] = $6
        port_files[$1] = $7
        owner_artifact[$1] = $8
        rationale[$1] = $9
      }
      next
    }
    $1 != "" {
      key = $1
      upstream = $2
      port = $3
      cls = classification[key]
      row_gate = gate[key]
      row_upstream_file = upstream_file[key]
      row_port_files = port_files[key]
      row_owner_artifact = owner_artifact[key]
      row_rationale = rationale[key]

      if (cls == "") {
        cls = "unclassified"
        row_gate = "UNKNOWN"
        row_upstream_file = "UNKNOWN"
        row_port_files = "UNKNOWN"
        row_owner_artifact = "UNKNOWN"
        row_rationale = "missing ledger row"
        errors += 1
      } else {
        if (cls != "necessary-extra" && cls != "mapped-different-file" && cls != "true-gap") {
          row_rationale = "invalid classification: " cls
          errors += 1
        }
        if (ledger_upstream[key] != upstream || ledger_port[key] != port) {
          row_rationale = row_rationale "; stale ledger count expected=" ledger_upstream[key] "/" ledger_port[key]
          errors += 1
        }
      }

      if (cls == "necessary-extra") necessary += 1
      else if (cls == "mapped-different-file") mapped += 1
      else if (cls == "true-gap") {
        true_gap += 1
        true_gap_lines = true_gap_lines sprintf("  true-gap: %s gate=%s upstream=%s port=%s owner=%s\n", key, row_gate, upstream, port, row_owner_artifact)
      } else {
        unclassified += 1
      }

      printf "  %-34s upstream=%3s port=%3s class=%s gate=%s\n", key, upstream, port, cls, row_gate
      printf "    upstream_file=%s port_files=%s\n", row_upstream_file, row_port_files
      printf "    rationale=%s\n", row_rationale

      if (artifact != "") {
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", key, upstream, port, cls, row_gate, row_upstream_file, row_port_files, row_owner_artifact, row_rationale >> artifact
      }
    }
    END {
      printf "test parity ledger summary: necessary-extra=%d mapped-different-file=%d true-gap=%d unclassified=%d ledger-errors=%d\n", necessary + 0, mapped + 0, true_gap + 0, unclassified + 0, errors + 0
      if (true_gap > 0) {
        printf "remaining true-gap gates:\n%s", true_gap_lines
      }
      printf "%d %d\n", true_gap + 0, errors + 0 > summary
    }
  ' "$PARITY_LEDGER" "$mismatch_file" > "$report_file"

  cat "$report_file"
  if [ -n "$artifact_file" ]; then
    printf 'test parity mismatch artifact: %s\n' "$artifact_file"
  fi

  TEST_PARITY_TRUE_GAPS="$(awk '{print $1}' "$summary_file")"
  TEST_PARITY_LEDGER_ERRORS="$(awk '{print $2}' "$summary_file")"
}

upstream_test_key() {
  printf '%s\n' "$1" | sed 's#^test/##; s#\.test\.ts$##'
}

port_test_key() {
  key="$(printf '%s\n' "$1" | sed 's#^src/##; s#_test\.cj$##')"
  case "$key" in
    bot/bot) key="bot" ;;
    composer/composer) key="composer" ;;
    composer/composer_type) key="composer.type" ;;
    context/context) key="context" ;;
    filter/filter) key="filter" ;;
    platform/platform) key="platform" ;;
    types/types) key="types" ;;
  esac
  printf '%s\n' "$key"
}

section "Upstream baseline"
actual_head="$(git -C "$GRAMMY_DIR" rev-parse HEAD)"
actual_tag="$(git -C "$GRAMMY_DIR" describe --tags --always)"
runtime_files="$(find "$GRAMMY_DIR/src" -type f \( -name '*.ts' -o -name '*.md' \) | wc -l | tr -d ' ')"
runtime_ts_files="$(find "$GRAMMY_DIR/src" -type f -name '*.ts' | wc -l | tr -d ' ')"
test_files="$(find "$GRAMMY_DIR/test" -type f -name '*.ts' | wc -l | tr -d ' ')"
bdd_tests="$(rg -n '\bit\(' "$GRAMMY_DIR/test" -g '*.ts' | wc -l | tr -d ' ')"
deno_tests="$(rg -n '\bDeno\.test\(' "$GRAMMY_DIR/test" -g '*.ts' | wc -l | tr -d ' ')"

check_eq "grammY HEAD" "$actual_head" "$EXPECTED_HEAD"
check_eq "grammY tag" "$actual_tag" "$EXPECTED_TAG"
check_eq "upstream src files including README.md" "$runtime_files" "25"
check_eq "upstream runtime ts files" "$runtime_ts_files" "24"
check_eq "upstream test ts files" "$test_files" "18"
check_eq "upstream BDD it(...) tests" "$bdd_tests" "317"
check_eq "upstream Deno.test tests" "$deno_tests" "10"

section "G8.1 API method diff"
perl -0ne 'while(/^    (?!private|constructor)(?:async\s+)?([A-Za-z_]\w*)\s*\(/mg){print "$1\n"}' \
  "$GRAMMY_DIR/src/core/api.ts" | sort -u > "$TMP_DIR/upstream_api_methods"
perl -ne 'if (/^public class Api\b/) {$in=1; next} if ($in && /^}/) {$in=0} if ($in && /^    public func (?!endpointFor\b|call\b)([A-Za-z_]\w*)\(/) {print "$1\n"}' \
  "$REPO_DIR/src/core/api.cj" | sort -u > "$TMP_DIR/port_api_methods"
awk '
  /public func apiWrapperMethodNames/ { in_table = 1; next }
  in_table && /^}/ { in_table = 0 }
  in_table {
    line = $0
    while (match(line, /"[^"]+"/)) {
      value = substr(line, RSTART + 1, RLENGTH - 2)
      print value
      line = substr(line, RSTART + RLENGTH)
    }
  }
' "$REPO_DIR/src/core/api_wrapper_table.cj" | sort -u > "$TMP_DIR/port_api_table_methods"

check_eq "upstream public Api wrapper methods" "$(count_lines "$TMP_DIR/upstream_api_methods")" "180"
check_eq "port Api wrapper methods" "$(count_lines "$TMP_DIR/port_api_methods")" "180"
check_eq "port Api wrapper table methods" "$(count_lines "$TMP_DIR/port_api_table_methods")" "180"
assert_no_set_diff "Api class methods vs upstream" "$TMP_DIR/upstream_api_methods" "$TMP_DIR/port_api_methods"
assert_no_set_diff "Api wrapper table vs upstream" "$TMP_DIR/upstream_api_methods" "$TMP_DIR/port_api_table_methods"

section "G8.1b API schema trace diff"
perl -ne 'if (/^\s*"([^"~]+)~/) { print "$1\n" }' \
  "$REPO_DIR/src/core/api_wrapper_table.cj" | sort -u > "$TMP_DIR/port_api_schema_methods"
perl -ne 'if (/^\s*"([^"~]+)~([^"~]+)~/ && $1 ne $2) { print "$1 -> $2\n" }' \
  "$REPO_DIR/src/core/api_wrapper_table.cj" | sort -u > "$TMP_DIR/port_api_schema_raw_variants"
perl -ne 'if (/m === "([^"]+)"/ && $1 ne "toJSON") { print "$1\n" }' \
  "$GRAMMY_DIR/src/core/client.ts" | sort -u > "$TMP_DIR/upstream_raw_zero_arg_methods"
awk '
  /public func apiRawZeroArgMethodNames/ { in_table = 1; next }
  in_table && /^}/ { in_table = 0 }
  in_table {
    line = $0
    while (match(line, /"[^"]+"/)) {
      value = substr(line, RSTART + 1, RLENGTH - 2)
      print value
      line = substr(line, RSTART + RLENGTH)
    }
  }
' "$REPO_DIR/src/core/api_wrapper_table.cj" | sort -u > "$TMP_DIR/port_raw_zero_arg_methods"

check_eq "port Api schema trace methods" "$(count_lines "$TMP_DIR/port_api_schema_methods")" "180"
check_eq "port Api public-to-raw variants" "$(count_lines "$TMP_DIR/port_api_schema_raw_variants")" "11"
check_eq "upstream raw zero-arg methods" "$(count_lines "$TMP_DIR/upstream_raw_zero_arg_methods")" "8"
check_eq "port raw zero-arg methods" "$(count_lines "$TMP_DIR/port_raw_zero_arg_methods")" "8"
assert_no_set_diff "Api schema trace methods vs upstream" "$TMP_DIR/upstream_api_methods" "$TMP_DIR/port_api_schema_methods"
assert_no_set_diff "Raw zero-arg methods" "$TMP_DIR/upstream_raw_zero_arg_methods" "$TMP_DIR/port_raw_zero_arg_methods"

section "G8.2 Context this.api.* call target diff"
perl -ne 'while(/this\.api\.([A-Za-z_]\w*)\s*\(/g){print "$1\n"}' \
  "$GRAMMY_DIR/src/context.ts" > "$TMP_DIR/upstream_context_calls"
perl -ne 'while(/this\.api\.([A-Za-z_]\w*)\s*\(/g){print "$1\n"}' \
  "$REPO_DIR/src/context/context.cj" > "$TMP_DIR/port_context_calls"
sort -u "$TMP_DIR/upstream_context_calls" > "$TMP_DIR/upstream_context_targets"
sort -u "$TMP_DIR/port_context_calls" > "$TMP_DIR/port_context_targets"
printf 'upstream context api callsites=%s unique_targets=%s\n' \
  "$(count_lines "$TMP_DIR/upstream_context_calls")" \
  "$(count_lines "$TMP_DIR/upstream_context_targets")"
printf 'port context api callsites=%s unique_targets=%s\n' \
  "$(count_lines "$TMP_DIR/port_context_calls")" \
  "$(count_lines "$TMP_DIR/port_context_targets")"
show_set_diff "Context api targets" "$TMP_DIR/upstream_context_targets" "$TMP_DIR/port_context_targets"
comm -23 "$TMP_DIR/upstream_context_targets" "$TMP_DIR/port_context_targets" > "$TMP_DIR/context_missing_targets"
context_missing_count="$(count_lines "$TMP_DIR/context_missing_targets")"
hard_fail_if_nonzero "Context api targets missing" "$context_missing_count"

section "G8.3 Composer 20 controls diff"
perl -ne 'if (/export class Composer/) {$in=1; next} if ($in && /^}/) {$in=0} if ($in && /^    (?!constructor\b)([A-Za-z_]\w*)(?:<[^)]*>)?\(/) {print "$1\n"}' \
  "$GRAMMY_DIR/src/composer.ts" | sort -u > "$TMP_DIR/upstream_composer_controls"
perl -ne 'if (/public class Composer/) {$in=1; next} if ($in && /^}/) {$in=0} if ($in && /^    public func ([A-Za-z_]\w*)\(/) {print "$1\n"}' \
  "$REPO_DIR/src/composer/composer.cj" | sort -u > "$TMP_DIR/port_composer_controls"
comm -12 "$TMP_DIR/upstream_composer_controls" "$TMP_DIR/port_composer_controls" > "$TMP_DIR/implemented_composer_controls"
check_eq "upstream Composer controls" "$(count_lines "$TMP_DIR/upstream_composer_controls")" "20"
printf 'port composer public methods=%s upstream_controls_implemented=%s\n' \
  "$(count_lines "$TMP_DIR/port_composer_controls")" \
  "$(count_lines "$TMP_DIR/implemented_composer_controls")"
show_set_diff "Composer controls" "$TMP_DIR/upstream_composer_controls" "$TMP_DIR/port_composer_controls"
comm -23 "$TMP_DIR/upstream_composer_controls" "$TMP_DIR/port_composer_controls" > "$TMP_DIR/composer_missing_controls"
composer_missing_count="$(count_lines "$TMP_DIR/composer_missing_controls")"
hard_fail_if_nonzero "Composer controls missing" "$composer_missing_count"

section "G8.4 Test count per file diff"
find "$GRAMMY_DIR/test" -type f -name '*.ts' | sort | while IFS= read -r file; do
  rel="${file#$GRAMMY_DIR/}"
  key="$(upstream_test_key "$rel")"
  count="$(rg -n '\bit\(|\bDeno\.test\(' "$file" | wc -l | tr -d ' ')"
  printf '%s %s %s\n' "$key" "$count" "$rel"
done | sort > "$TMP_DIR/upstream_test_counts"

find "$REPO_DIR/src" -type f -name '*_test.cj' | sort | while IFS= read -r file; do
  rel="${file#$REPO_DIR/}"
  key="$(port_test_key "$rel")"
  count="$(rg -n '@TestCase' "$file" | wc -l | tr -d ' ')"
  printf '%s %s %s\n' "$key" "$count" "$rel"
done | sort > "$TMP_DIR/port_test_counts"

upstream_test_total="$(awk '{sum += $2} END {print sum + 0}' "$TMP_DIR/upstream_test_counts")"
port_test_total="$(awk '{sum += $2} END {print sum + 0}' "$TMP_DIR/port_test_counts")"
check_eq "upstream total test declarations" "$upstream_test_total" "327"
printf 'port total @TestCase declarations=%s\n' "$port_test_total"
join -a 1 -a 2 -e 0 -o '0 1.2 2.2' "$TMP_DIR/upstream_test_counts" "$TMP_DIR/port_test_counts" |
  awk '{
    status = ($2 == $3) ? "same" : "diff"
    printf "  %-34s upstream=%3s port=%3s %s\n", $1, $2, $3, status
  }'
check_ge "port composer runtime @TestCase declarations" "$(test_count_for composer "$TMP_DIR/port_test_counts")" "43"
check_ge "port composer.type compile-surface @TestCase declarations" "$(test_count_for composer.type "$TMP_DIR/port_test_counts")" "14"
check_ge "port filter @TestCase declarations" "$(test_count_for filter "$TMP_DIR/port_test_counts")" "11"
test_mismatch_count="$(join -a 1 -a 2 -e 0 -o '0 1.2 2.2' "$TMP_DIR/upstream_test_counts" "$TMP_DIR/port_test_counts" |
  awk '$2 != $3 {count += 1} END {print count + 0}')"
printf 'test parity mismatches=%s\n' "$test_mismatch_count"
join -a 1 -a 2 -e 0 -o '0 1.2 2.2' "$TMP_DIR/upstream_test_counts" "$TMP_DIR/port_test_counts" |
  awk '$2 != $3 {printf "%s\t%s\t%s\n", $1, $2, $3}' > "$TMP_DIR/test_parity_mismatches"
TEST_PARITY_TRUE_GAPS=0
TEST_PARITY_LEDGER_ERRORS=0
if [ "$test_mismatch_count" != "0" ]; then
  classify_test_parity_mismatches "$TMP_DIR/test_parity_mismatches"
  if [ "$TEST_PARITY_LEDGER_ERRORS" != "0" ]; then
    printf 'FAIL test parity ledger has stale or unclassified rows count=%s\n' "$TEST_PARITY_LEDGER_ERRORS"
    record_failure
  fi
  hard_fail_if_nonzero "test parity true gaps" "$TEST_PARITY_TRUE_GAPS"
fi

section "G8.5 Docs heading diff"
extract_markdown_headings "$GRAMMY_DIR/README.md" "$TMP_DIR/upstream_readme_headings"
extract_markdown_headings "$REPO_DIR/README.md" "$TMP_DIR/port_readme_headings"
extract_markdown_headings "$GRAMMY_DIR/src/README.md" "$TMP_DIR/upstream_src_readme_headings"
extract_markdown_headings "$REPO_DIR/src/README.md" "$TMP_DIR/port_src_readme_headings"
sort -u "$TMP_DIR/upstream_readme_headings" > "$TMP_DIR/upstream_readme_headings.sorted"
sort -u "$TMP_DIR/port_readme_headings" > "$TMP_DIR/port_readme_headings.sorted"
sort -u "$TMP_DIR/upstream_src_readme_headings" > "$TMP_DIR/upstream_src_readme_headings.sorted"
sort -u "$TMP_DIR/port_src_readme_headings" > "$TMP_DIR/port_src_readme_headings.sorted"
printf 'root README headings: upstream=%s port=%s\n' \
  "$(count_lines "$TMP_DIR/upstream_readme_headings")" \
  "$(count_lines "$TMP_DIR/port_readme_headings")"
show_set_diff "Root README headings" "$TMP_DIR/upstream_readme_headings.sorted" "$TMP_DIR/port_readme_headings.sorted"
check_docs_heading_policy "root" "$REPO_DIR/README.md" \
  "grammy4cj:docs-heading-exemptions root" \
  "$TMP_DIR/upstream_readme_headings.sorted" "$TMP_DIR/port_readme_headings.sorted"
printf 'src README headings: upstream=%s port=%s\n' \
  "$(count_lines "$TMP_DIR/upstream_src_readme_headings")" \
  "$(count_lines "$TMP_DIR/port_src_readme_headings")"
show_set_diff "src README headings" "$TMP_DIR/upstream_src_readme_headings.sorted" "$TMP_DIR/port_src_readme_headings.sorted"
check_docs_heading_policy "src" "$REPO_DIR/src/README.md" \
  "grammy4cj:docs-heading-exemptions src" \
  "$TMP_DIR/upstream_src_readme_headings.sorted" "$TMP_DIR/port_src_readme_headings.sorted"

section "G9 Source trace matrix"
if [ -n "$ARTIFACT_DIR" ]; then
  GRAMMY_DIR="$GRAMMY_DIR" GRAMMY4CJ_TRACE_ARTIFACT_DIR="$ARTIFACT_DIR" sh "$SCRIPT_DIR/check_source_trace_matrix.sh"
else
  GRAMMY_DIR="$GRAMMY_DIR" sh "$SCRIPT_DIR/check_source_trace_matrix.sh"
fi

section "G9.3 Upstream diff workflow"
if [ -n "${GRAMMY4CJ_UPSTREAM_DIFF_BASE:-}" ] || [ -n "${GRAMMY4CJ_UPSTREAM_DIFF_HEAD:-}" ]; then
  if GRAMMY_DIR="$GRAMMY_DIR" sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" \
      --base "${GRAMMY4CJ_UPSTREAM_DIFF_BASE:-}" \
      --head "${GRAMMY4CJ_UPSTREAM_DIFF_HEAD:-}"; then
    :
  else
    record_failure
  fi
else
  if sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --validate-only; then
    :
  else
    record_failure
  fi
fi
section "G9.2 Phase status"
write_phase_status_artifact

if [ "$failures" -ne 0 ]; then
  printf '\nupstream contract checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf '\nupstream contract checks passed\n'
