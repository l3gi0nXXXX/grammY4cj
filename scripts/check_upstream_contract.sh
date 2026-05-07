#!/usr/bin/env sh
set -eu

LC_ALL=C
export LC_ALL

GRAMMY_DIR="${GRAMMY_DIR:-/Users/l3gi0n/work/workspace_cangjie/grammY}"
EXPECTED_HEAD="c865dd3a4d26911b01c83695e3845c7245870a5d"
EXPECTED_TAG="v1.42.0-5-gc865dd3"

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
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

upstream_test_key() {
  printf '%s\n' "$1" | sed 's#^test/##; s#\.test\.ts$##'
}

port_test_key() {
  key="$(printf '%s\n' "$1" | sed 's#^src/##; s#_test\.cj$##')"
  case "$key" in
    bot/bot) key="bot" ;;
    composer/composer) key="composer" ;;
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
printf 'src README headings: upstream=%s port=%s\n' \
  "$(count_lines "$TMP_DIR/upstream_src_readme_headings")" \
  "$(count_lines "$TMP_DIR/port_src_readme_headings")"
show_set_diff "src README headings" "$TMP_DIR/upstream_src_readme_headings.sorted" "$TMP_DIR/port_src_readme_headings.sorted"

section "G9 Source trace matrix"
sh "$SCRIPT_DIR/check_source_trace_matrix.sh"

if [ "$failures" -ne 0 ]; then
  printf '\nupstream contract checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf '\nupstream contract checks passed\n'
