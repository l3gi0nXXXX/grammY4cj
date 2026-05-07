#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/grammy4cj-sync-process.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

failures=0

record_failure() {
  failures=$((failures + 1))
}

expect_success() {
  name="$1"
  shift
  output="$TMP_DIR/$name.out"
  if "$@" > "$output" 2>&1; then
    printf 'ok %s\n' "$name"
  else
    printf 'FAIL %s expected success\n' "$name"
    cat "$output"
    record_failure
  fi
}

expect_failure_with() {
  name="$1"
  expected="$2"
  shift 2
  output="$TMP_DIR/$name.out"
  if "$@" > "$output" 2>&1; then
    printf 'FAIL %s expected failure\n' "$name"
    cat "$output"
    record_failure
    return
  fi
  if grep -F "$expected" "$output" >/dev/null 2>&1; then
    printf 'ok %s\n' "$name"
  else
    printf 'FAIL %s missing expected output: %s\n' "$name" "$expected"
    cat "$output"
    record_failure
  fi
}

expect_success validate_current_process sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --validate-only

cat > "$TMP_DIR/known_changed_files" <<'EOF'
.all-contributorsrc
README.md
src/context.ts
src/convenience/frameworks.ts
src/filter.ts
test/context.test.ts
EOF
expect_success current_upstream_diff_fixture sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --changed-files "$TMP_DIR/known_changed_files"

cat > "$TMP_DIR/unknown_changed_files" <<'EOF'
src/experimental/new_surface.ts
.github/workflows/new_policy.yml
EOF
expect_failure_with unknown_paths_get_gate_suggestions 'suggested_gate=' \
  sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --changed-files "$TMP_DIR/unknown_changed_files"

cat > "$TMP_DIR/masked_true_gap.tsv" <<'EOF'
key	upstream_count	port_count	classification	gate	upstream_file	port_files	owner_artifact	rationale
context	2	1	necessary-extra	G4	test/context.test.ts	src/context/context_test.cj	scripts/check_upstream_contract.sh	fixture row must fail because port_count is lower than upstream_count
EOF
expect_failure_with necessary_extra_cannot_mask_true_gap 'necessary-extra masks possible true-gap' \
  env GRAMMY4CJ_TEST_PARITY_LEDGER="$TMP_DIR/masked_true_gap.tsv" sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --validate-only

printf 'key\tupstream_count\tport_count\tclassification\tgate\tupstream_file\tport_files\towner_artifact\trationale\n' > "$TMP_DIR/missing_owner.tsv"
printf 'context\t1\t2\tnecessary-extra\tG4\ttest/context.test.ts\tsrc/context/context_test.cj\t\t\n' >> "$TMP_DIR/missing_owner.tsv"
expect_failure_with necessary_extra_requires_owner_and_rationale 'necessary-extra missing owner artifact or rationale' \
  env GRAMMY4CJ_TEST_PARITY_LEDGER="$TMP_DIR/missing_owner.tsv" sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --validate-only

cat > "$TMP_DIR/true_gap.tsv" <<'EOF'
key	upstream_count	port_count	classification	gate	upstream_file	port_files	owner_artifact	rationale
context	2	1	true-gap	G4	test/context.test.ts	src/context/context_test.cj	scripts/check_upstream_contract.sh	fixture row must fail because true-gap cannot pass the sync process
EOF
expect_failure_with true_gap_is_blocking 'true-gap must not pass sync process silently' \
  env GRAMMY4CJ_TEST_PARITY_LEDGER="$TMP_DIR/true_gap.tsv" sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --validate-only

printf 'key\tupstream_count\tport_count\tclassification\tgate\tupstream_file\tport_files\towner_artifact\trationale\n' > "$TMP_DIR/unclassified.tsv"
printf 'context\t1\t1\tunclassified\tG4\ttest/context.test.ts\tsrc/context/context_test.cj\tscripts/check_upstream_contract.sh\tfixture row must fail because unclassified is not a terminal state\n' >> "$TMP_DIR/unclassified.tsv"
expect_failure_with unclassified_is_blocking 'parity row is unclassified' \
  env GRAMMY4CJ_TEST_PARITY_LEDGER="$TMP_DIR/unclassified.tsv" sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --validate-only

if [ "$failures" -ne 0 ]; then
  printf 'upstream sync process checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'upstream sync process checks passed\n'
