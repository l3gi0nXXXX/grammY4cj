#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"

PARITY_LEDGER="$REPO_DIR/src/architecture/upstream_test_parity_ledger.tsv"
PHASE_STATUS="$REPO_DIR/src/architecture/phase_status.tsv"
GATE_STATUS="$REPO_DIR/src/architecture/gate_status.tsv"
WORKFLOW_LEDGER="$REPO_DIR/src/architecture/upstream_diff_workflow.tsv"
ROOT_EXPORT_MANIFEST="$REPO_DIR/src/architecture/root_public_export_manifest.tsv"
PLATFORM_SOURCE="$REPO_DIR/src/platform/platform.cj"
CORE_CLIENT_SOURCE="$REPO_DIR/src/core/client.cj"
INPUT_FILE_SOURCE="$REPO_DIR/src/types/input_file.cj"

failures=0

record_failure() {
  failures=$((failures + 1))
}

check_header() {
  file="$1"
  expected="$2"
  if [ ! -f "$file" ]; then
    printf 'FAIL missing architecture artifact: %s\n' "$file"
    record_failure
    return
  fi

  actual="$(sed -n '1p' "$file")"
  if [ "$actual" = "$expected" ]; then
    printf 'ok header %s\n' "${file#$REPO_DIR/}"
  else
    printf 'FAIL header %s\n' "${file#$REPO_DIR/}"
    printf '  expected: %s\n' "$expected"
    printf '  actual:   %s\n' "$actual"
    record_failure
  fi
}

check_header "$PARITY_LEDGER" 'key	upstream_count	port_count	classification	gate	upstream_file	port_files	owner_artifact	rationale'
check_header "$PHASE_STATUS" 'phase	phase_group	status	evidence	next_action'
check_header "$GATE_STATUS" 'gate	status	owner_artifact	acceptance	next_action'
check_header "$WORKFLOW_LEDGER" 'upstream_path	gate	required_checks	docs_impact	note'
check_header "$ROOT_EXPORT_MANIFEST" 'export_name	module	category	upstream_anchor	note'

check_no_shell_out() {
  label="$1"
  file="$2"
  if [ -f "$file" ]; then
    if grep -E 'std\.process\.executeWithOutput|executeWithOutput\(|curl|Curl' "$file" >/dev/null 2>&1; then
      printf 'FAIL %s runtime default still shells out through curl\n' "$label"
      record_failure
    else
      printf 'ok %s runtime default is not curl shell-out\n' "$label"
    fi
  fi
}

if [ -f "$PLATFORM_SOURCE" ]; then
  if grep -E 'std\.process\.executeWithOutput|CurlPlatform(HttpClient|FetchSourceAdapter)' "$PLATFORM_SOURCE" >/dev/null 2>&1; then
    printf 'FAIL platform runtime default still shells out through curl\n'
    record_failure
  else
    printf 'ok platform runtime default is not curl shell-out\n'
  fi
fi

check_no_shell_out "core client" "$CORE_CLIENT_SOURCE"
check_no_shell_out "input file fetch" "$INPUT_FILE_SOURCE"

if [ -f "$PARITY_LEDGER" ]; then
  parity_rows="$(awk -F '\t' 'NR > 1 && $1 != "" {count += 1} END {print count + 0}' "$PARITY_LEDGER")"
  parity_bad_class="$(awk -F '\t' '
    NR > 1 && $1 != "" && $4 != "necessary-extra" && $4 != "mapped-different-file" && $4 != "true-gap" {bad += 1}
    END {print bad + 0}
  ' "$PARITY_LEDGER")"
  parity_true_gap="$(awk -F '\t' 'NR > 1 && $4 == "true-gap" {count += 1} END {print count + 0}' "$PARITY_LEDGER")"
  parity_true_gap_gate_missing="$(awk -F '\t' 'NR > 1 && $4 == "true-gap" && $5 == "" {count += 1} END {print count + 0}' "$PARITY_LEDGER")"

  printf 'parity ledger rows=%s true_gaps=%s\n' "$parity_rows" "$parity_true_gap"
  if [ "$parity_rows" = "0" ]; then
    printf 'FAIL parity ledger must contain classified mismatch rows\n'
    record_failure
  fi
  if [ "$parity_bad_class" != "0" ]; then
    printf 'FAIL parity ledger invalid classifications=%s\n' "$parity_bad_class"
    record_failure
  fi
  if [ "$parity_true_gap_gate_missing" != "0" ]; then
    printf 'FAIL parity ledger true-gap rows missing gate=%s\n' "$parity_true_gap_gate_missing"
    record_failure
  fi
fi

if [ -f "$PHASE_STATUS" ]; then
  phase_rows="$(awk -F '\t' 'NR > 1 && $1 != "" {count += 1} END {print count + 0}' "$PHASE_STATUS")"
  phase_bad_status="$(awk -F '\t' '
    NR > 1 && $1 != "" {
      ok = $3 == "passed" || $3 == "passed_with_formal_substitute" || $3 == "monitoring"
      if (!ok) bad += 1
    }
    END {print bad + 0}
  ' "$PHASE_STATUS")"
  phase_drift_terms="$(awk -F '\t' '
    NR > 1 && $1 != "" && ($0 ~ /(^|\t|_)partial($|\t|_)/ || $0 ~ /(^|\t|_)pending($|\t|_)/) {bad += 1}
    END {print bad + 0}
  ' "$PHASE_STATUS")"
  phase_passed_gate_drift="$phase_drift_terms"
  if [ -f "$GATE_STATUS" ]; then
    phase_passed_gate_drift="$(awk -F '\t' '
      NR == FNR {
        if (FNR > 1 && $1 != "" && ($2 == "passed" || $2 == "mostly_passed")) passed_gate = 1
        next
      }
      passed_gate && FNR > 1 && $1 != "" && ($0 ~ /(^|\t|_)partial($|\t|_)/ || $0 ~ /(^|\t|_)pending($|\t|_)/) {bad += 1}
      END {print bad + 0}
    ' "$GATE_STATUS" "$PHASE_STATUS")"
  fi

  printf 'phase status rows=%s\n' "$phase_rows"
  if [ "$phase_rows" != "63" ]; then
    printf 'FAIL phase status rows expected=63 actual=%s\n' "$phase_rows"
    record_failure
  fi
  if [ "$phase_bad_status" != "0" ]; then
    printf 'FAIL phase status invalid statuses=%s\n' "$phase_bad_status"
    record_failure
  fi
  if awk -F '\t' 'NR > 1 && $3 == "mostly_passed_release_gap" {found = 1} END {exit found ? 0 : 1}' "$PHASE_STATUS"; then
    printf 'FAIL phase status contains closed release gap status mostly_passed_release_gap\n'
    record_failure
  fi
  if [ "$phase_drift_terms" != "0" ]; then
    printf 'FAIL phase status contains drift terms partial/pending=%s\n' "$phase_drift_terms"
    record_failure
  fi
  if [ "$phase_passed_gate_drift" != "0" ]; then
    printf 'FAIL passed gate phase status drift rows=%s\n' "$phase_passed_gate_drift"
    record_failure
  fi
fi

if [ -f "$GATE_STATUS" ]; then
  gate_rows="$(awk -F '\t' 'NR > 1 && $1 != "" {count += 1} END {print count + 0}' "$GATE_STATUS")"
  gate_bad_status="$(awk -F '\t' '
    NR > 1 && $1 != "" {
      ok = $2 == "passed" || $2 == "partial" || $2 == "mostly_passed" || $2 == "failed" || $2 == "name_count_passed_semantic_partial" || $2 == "count_passed_semantic_partial"
      if (!ok) bad += 1
    }
    END {print bad + 0}
  ' "$GATE_STATUS")"
  g8_status="$(awk -F '\t' 'NR > 1 && $1 == "G8" {print $2; found = 1} END {if (!found) print ""}' "$GATE_STATUS")"

  printf 'gate status rows=%s\n' "$gate_rows"
  if [ "$gate_rows" != "11" ]; then
    printf 'FAIL gate status rows expected=11 actual=%s\n' "$gate_rows"
    record_failure
  fi
  if [ "$gate_bad_status" != "0" ]; then
    printf 'FAIL gate status invalid statuses=%s\n' "$gate_bad_status"
    record_failure
  fi
  if [ "$g8_status" != "passed" ]; then
    printf 'FAIL G8 status expected=passed actual=%s\n' "$g8_status"
    record_failure
  fi
fi

if [ -f "$SCRIPT_DIR/check_release_metadata.sh" ]; then
  if sh "$SCRIPT_DIR/check_release_metadata.sh"; then
    printf 'release metadata fixture passed\n'
  else
    record_failure
  fi
fi

if ! sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --validate-only; then
  record_failure
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/grammy4cj-artifacts.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
cat > "$TMP_DIR/changed_files" <<'EOF'
src/context.ts
test/core/client.test.ts
README.md
EOF

if sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --changed-files "$TMP_DIR/changed_files" > "$TMP_DIR/diff_output"; then
  if ! grep -F 'src/context.ts	G4	' "$TMP_DIR/diff_output" >/dev/null 2>&1; then
    printf 'FAIL workflow fixture missing src/context.ts -> G4 mapping\n'
    record_failure
  fi
  if ! grep -F 'test/core/client.test.ts	G2	' "$TMP_DIR/diff_output" >/dev/null 2>&1; then
    printf 'FAIL workflow fixture missing test/core/client.test.ts -> G2 mapping\n'
    record_failure
  fi
  if ! grep -F 'README.md	G8	' "$TMP_DIR/diff_output" >/dev/null 2>&1; then
    printf 'FAIL workflow fixture missing README.md -> G8 mapping\n'
    record_failure
  fi
  printf 'upstream diff workflow fixture passed\n'
else
  cat "$TMP_DIR/diff_output"
  record_failure
fi

if [ "$failures" -ne 0 ]; then
  printf 'architecture artifact checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'architecture artifact checks passed\n'
