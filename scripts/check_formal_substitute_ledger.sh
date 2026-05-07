#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"

LEDGER="$REPO_DIR/src/architecture/formal_substitute_ledger.tsv"
GATE_STATUS="$REPO_DIR/src/architecture/gate_status.tsv"
EXPECTED_HEADER='formal_substitute	upstream_mechanism	cangjie_substitute	gate	owner_artifact	test_artifact	acceptance	drift_trigger'

failures=0

record_failure() {
  failures=$((failures + 1))
}

fail() {
  printf 'FAIL %s\n' "$1"
  record_failure
}

if [ ! -f "$LEDGER" ]; then
  fail "missing src/architecture/formal_substitute_ledger.tsv"
else
  actual_header="$(sed -n '1p' "$LEDGER")"
  if [ "$actual_header" = "$EXPECTED_HEADER" ]; then
    printf 'ok header src/architecture/formal_substitute_ledger.tsv\n'
  else
    printf 'FAIL header src/architecture/formal_substitute_ledger.tsv\n'
    printf '  expected: %s\n' "$EXPECTED_HEADER"
    printf '  actual:   %s\n' "$actual_header"
    record_failure
  fi
fi

if [ -f "$LEDGER" ]; then
  row_count="$(awk -F '\t' 'NR > 1 && $1 != "" {count += 1} END {print count + 0}' "$LEDGER")"
  bad_width="$(awk -F '\t' 'NR > 1 && $1 != "" && NF != 8 {bad += 1} END {print bad + 0}' "$LEDGER")"
  blank_fields="$(awk -F '\t' '
    NR > 1 && $1 != "" {
      for (i = 1; i <= 8; i += 1) {
        if ($i == "") bad += 1
      }
    }
    END {print bad + 0}
  ' "$LEDGER")"
  duplicate_keys="$(awk -F '\t' '
    NR > 1 && $1 != "" {
      seen[$1] += 1
      if (seen[$1] == 2) dup += 1
    }
    END {print dup + 0}
  ' "$LEDGER")"
  bad_gate="$(awk -F '\t' '
    NR == FNR && NR > 1 && $1 != "" {gates[$1] = 1; next}
    FNR > 1 && $1 != "" && !($4 in gates) {bad += 1}
    END {print bad + 0}
  ' "$GATE_STATUS" "$LEDGER")"

  printf 'formal substitute ledger rows=%s\n' "$row_count"
  if [ "$row_count" -lt 7 ]; then
    fail "formal substitute ledger must contain at least 7 rows"
  fi
  if [ "$bad_width" != "0" ]; then
    fail "formal substitute ledger rows with wrong column count=$bad_width"
  fi
  if [ "$blank_fields" != "0" ]; then
    fail "formal substitute ledger blank required fields=$blank_fields"
  fi
  if [ "$duplicate_keys" != "0" ]; then
    fail "formal substitute ledger duplicate formal_substitute keys=$duplicate_keys"
  fi
  if [ "$bad_gate" != "0" ]; then
    fail "formal substitute ledger rows with unknown gate=$bad_gate"
  fi

  for required_key in \
    telegram_types_subset_alias_trace \
    input_file_fake_raw_contract \
    api_generics_other_payload_schema \
    context_has_type_predicate_surface \
    composer_maybe_promise_fork_contract \
    session_property_accessor_contract \
    framework_fake_req_res_adapter_contract
  do
    if awk -F '\t' -v key="$required_key" 'NR > 1 && $1 == key {found = 1} END {exit found ? 0 : 1}' "$LEDGER"; then
      printf 'ok key %s\n' "$required_key"
    else
      fail "missing formal substitute key: $required_key"
    fi
  done

  awk -F '\t' 'NR > 1 && $1 != "" {print $5 "\n" $6}' "$LEDGER" |
    tr ';' '\n' |
    while IFS= read -r artifact; do
      [ -n "$artifact" ] || continue
      if [ ! -e "$REPO_DIR/$artifact" ]; then
        printf 'FAIL missing referenced artifact: %s\n' "$artifact"
        exit 1
      fi
    done || record_failure
fi

if [ "$failures" -ne 0 ]; then
  printf 'formal substitute ledger checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'formal substitute ledger checks passed\n'
