#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOW_LEDGER="${GRAMMY4CJ_UPSTREAM_DIFF_WORKFLOW:-$REPO_DIR/src/architecture/upstream_diff_workflow.tsv}"
PARITY_LEDGER="${GRAMMY4CJ_TEST_PARITY_LEDGER:-$REPO_DIR/src/architecture/upstream_test_parity_ledger.tsv}"
CHANGED_FILES=""
BASE_REF=""
HEAD_REF=""
VALIDATE_ONLY=0

validate_test_parity_process() {
  if [ ! -f "$PARITY_LEDGER" ]; then
    printf 'FAIL missing upstream test parity ledger: %s\n' "$PARITY_LEDGER"
    exit 1
  fi

  parity_header="$(sed -n '1p' "$PARITY_LEDGER")"
  parity_expected_header='key	upstream_count	port_count	classification	gate	upstream_file	port_files	owner_artifact	rationale'
  if [ "$parity_header" != "$parity_expected_header" ]; then
    printf 'FAIL upstream test parity ledger header mismatch\n'
    printf '  expected: %s\n' "$parity_expected_header"
    printf '  actual:   %s\n' "$parity_header"
    exit 1
  fi

  if ! awk -F '\t' -v repo="$REPO_DIR" '
    function shell_quote(value, quoted) {
      quoted = value
      gsub(/\047/, "\047\\\047\047", quoted)
      return "\047" quoted "\047"
    }
    NR > 1 && $1 != "" {
      rows += 1
      cls = $4
      if (NF < 9) {
        printf "FAIL parity row has fewer than 9 fields: %s\n", $1
        failures += 1
      }
      if (cls == "" || cls == "unclassified") {
        printf "FAIL parity row is unclassified: %s\n", $1
        failures += 1
      } else if (cls != "necessary-extra" && cls != "mapped-different-file" && cls != "true-gap") {
        printf "FAIL parity row has invalid classification: %s class=%s\n", $1, cls
        failures += 1
      }
      if ($5 !~ /^G([0-9]|10)(\.[0-9]+)?$/) {
        printf "FAIL parity row missing valid gate: %s gate=%s\n", $1, $5
        failures += 1
      }
      if (cls == "necessary-extra") {
        necessary += 1
        if ($8 == "" || $8 == "UNKNOWN" || $9 == "" || $9 == "UNKNOWN") {
          printf "FAIL necessary-extra missing owner artifact or rationale: %s\n", $1
          failures += 1
        }
        if (($3 + 0) < ($2 + 0)) {
          printf "FAIL necessary-extra masks possible true-gap: %s upstream=%s port=%s\n", $1, $2, $3
          failures += 1
        }
        artifact_count = split($8, owner_artifacts, ";")
        for (i = 1; i <= artifact_count; i++) {
          owner_path = owner_artifacts[i]
          if (owner_path != "" && owner_path !~ /^\//) {
            owner_path = repo "/" owner_path
          }
          if (owner_path != "" && system("test -e " shell_quote(owner_path)) != 0) {
            printf "FAIL necessary-extra owner artifact missing: %s owner=%s\n", $1, owner_artifacts[i]
            failures += 1
          }
        }
      } else if (cls == "true-gap") {
        true_gap += 1
        printf "FAIL true-gap must not pass sync process silently: %s gate=%s owner=%s\n", $1, $5, $8
        failures += 1
      }
    }
    END {
      printf "upstream test parity process: rows=%d necessary-extra=%d true-gap=%d failures=%d\n", rows + 0, necessary + 0, true_gap + 0, failures + 0
      if (rows == 0) {
        printf "FAIL upstream test parity ledger has no rows\n"
        failures += 1
      }
      if (failures > 0) exit 1
    }
  ' "$PARITY_LEDGER"; then
    exit 1
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --changed-files)
      CHANGED_FILES="$2"
      shift 2
      ;;
    --base)
      BASE_REF="$2"
      shift 2
      ;;
    --head)
      HEAD_REF="$2"
      shift 2
      ;;
    --validate-only)
      VALIDATE_ONLY=1
      shift
      ;;
    *)
      printf 'unknown argument: %s\n' "$1"
      exit 2
      ;;
  esac
done

if [ ! -f "$WORKFLOW_LEDGER" ]; then
  printf 'FAIL missing upstream diff workflow ledger: %s\n' "$WORKFLOW_LEDGER"
  exit 1
fi

header="$(sed -n '1p' "$WORKFLOW_LEDGER")"
expected_header='upstream_path	gate	required_checks	docs_impact	note'
if [ "$header" != "$expected_header" ]; then
  printf 'FAIL upstream diff workflow header mismatch\n'
  printf '  expected: %s\n' "$expected_header"
  printf '  actual:   %s\n' "$header"
  exit 1
fi

row_count="$(awk -F '\t' 'NR > 1 && $1 != "" {count += 1} END {print count + 0}' "$WORKFLOW_LEDGER")"
duplicate_count="$(awk -F '\t' 'NR > 1 && $1 != "" {seen[$1] += 1} END {for (k in seen) if (seen[k] > 1) count += 1; print count + 0}' "$WORKFLOW_LEDGER")"
invalid_count="$(awk -F '\t' '
  NR > 1 && $1 != "" {
    if ($2 !~ /^G([0-9]|10)(\.[0-9]+)?$/) bad += 1
    if ($3 == "" || $4 == "" || $5 == "") bad += 1
  }
  END {print bad + 0}
' "$WORKFLOW_LEDGER")"

if [ "$row_count" -lt 47 ]; then
  printf 'FAIL upstream diff workflow rows minimum=47 actual=%s\n' "$row_count"
  exit 1
fi
if [ "$duplicate_count" != "0" ]; then
  printf 'FAIL upstream diff workflow duplicate upstream paths=%s\n' "$duplicate_count"
  exit 1
fi
if [ "$invalid_count" != "0" ]; then
  printf 'FAIL upstream diff workflow invalid rows=%s\n' "$invalid_count"
  exit 1
fi

printf 'upstream diff workflow ledger: %s rows=%s\n' "$WORKFLOW_LEDGER" "$row_count"
validate_test_parity_process

if [ "$VALIDATE_ONLY" = "1" ]; then
  exit 0
fi

if [ -n "$BASE_REF" ] || [ -n "$HEAD_REF" ]; then
  if [ -z "$BASE_REF" ] || [ -z "$HEAD_REF" ]; then
    printf 'both --base and --head are required when using upstream refs\n'
    exit 2
  fi

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

  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/grammy4cj-diff-workflow.XXXXXX")"
  trap 'rm -rf "$TMP_DIR"' EXIT
  CHANGED_FILES="$TMP_DIR/changed_files"
  git -C "$GRAMMY_DIR" diff --name-only "$BASE_REF" "$HEAD_REF" > "$CHANGED_FILES"
fi

if [ -z "$CHANGED_FILES" ]; then
  printf 'upstream diff workflow mapping skipped: no changed files supplied\n'
  exit 0
fi
if [ ! -f "$CHANGED_FILES" ]; then
  printf 'FAIL changed file list not found: %s\n' "$CHANGED_FILES"
  exit 1
fi

awk -F '\t' '
  function suggest(path,    gate, checks, docs, reason) {
    gate = "G8"
    checks = "scripts/check_upstream_contract.sh;scripts/check_architecture_artifacts.sh"
    docs = "unknown"
    reason = "new upstream path needs explicit workflow ledger row"

    if (path ~ /^src\/core\/api\.ts$/) {
      gate = "G3"; checks = "src/core/api_test.cj;scripts/check_upstream_contract.sh"; docs = "none"; reason = "core API wrapper surface changed"
    } else if (path ~ /^src\/core\// || path ~ /^test\/core\//) {
      gate = "G2"; checks = "src/core/client_test.cj;src/core/payload_test.cj;src/core/error_test.cj;scripts/check_upstream_contract.sh"; docs = "none"; reason = "core transport payload or error contract changed"
    } else if (path ~ /^src\/bot\.ts$/ || path ~ /^test\/bot\.test\.ts$/) {
      gate = "G5"; checks = "src/bot/bot_test.cj;scripts/check_upstream_contract.sh"; docs = "none"; reason = "Bot runtime contract changed"
    } else if (path ~ /^src\/composer\.ts$/ || path ~ /^src\/context\.ts$/ || path ~ /^src\/filter\.ts$/ || path ~ /^test\/(composer|context|filter)(\.type)?\.test\.ts$/) {
      gate = "G4"; checks = "src/composer/composer_test.cj;src/context/context_test.cj;src/filter/filter_test.cj;scripts/check_upstream_contract.sh"; docs = "none"; reason = "middleware context or filter semantics changed"
    } else if (path ~ /^src\/convenience\/(frameworks|webhook)\.ts$/ || path ~ /^test\/convenience\/(frameworks|webhook)\.test\.ts$/) {
      gate = "G6"; checks = "src/convenience/frameworks_test.cj;src/convenience/webhook_test.cj;scripts/check_upstream_contract.sh"; docs = "none"; reason = "framework adapter or webhook contract changed"
    } else if (path ~ /^src\/convenience\// || path ~ /^test\/convenience\//) {
      gate = "G7"; checks = "src/convenience/constants_test.cj;src/convenience/keyboard_test.cj;src/convenience/session_test.cj;scripts/check_upstream_contract.sh"; docs = "none"; reason = "convenience helper contract changed"
    } else if (path ~ /^src\/(platform|types|shim)\./ || path ~ /^types\.d\.ts$/ || path ~ /^test\/types\.test\.ts$/ || path ~ /^bundling\//) {
      gate = "G1"; checks = "src/types/types_test.cj;src/platform/platform_test.cj;scripts/check_upstream_contract.sh"; docs = "release-metadata"; reason = "platform type facade or bundle output changed"
    } else if (path ~ /^src\/mod\.ts$/) {
      gate = "G9.5"; checks = "src/mod_test.cj;scripts/check_source_trace_matrix.sh"; docs = "source-map"; reason = "root export surface changed"
    } else if (path ~ /^test\/deps\.test\.ts$/) {
      gate = "G7"; checks = "scripts/check_dependency_boundaries.sh;src/architecture/dependency_boundary_test.cj"; docs = "none"; reason = "dependency boundary policy changed"
    } else if (path ~ /(^|\/)README\.md$/ || path ~ /^(CONTRIBUTING|CODE_OF_CONDUCT|LICENSE)\.md$/ || path == ".all-contributorsrc") {
      gate = "G8"; checks = "scripts/check_upstream_contract.sh"; docs = "public-docs"; reason = "public documentation or contributor policy changed"
    } else if (path ~ /^(\.github\/|deno\.jsonc$|package\.json$|tsconfig\.json$|\.editorconfig$|\.gitignore$|\.vscode\/)/) {
      gate = "G8"; checks = "scripts/check_upstream_contract.sh;scripts/check_architecture_artifacts.sh"; docs = "release-metadata"; reason = "repository automation tooling or release metadata changed"
    }

    return "suggested_gate=" gate " suggested_checks=" checks " suggested_docs_impact=" docs " suggested_note=" reason
  }
  NR == FNR {
    if (FNR > 1 && $1 != "") {
      gate[$1] = $2
      checks[$1] = $3
      docs[$1] = $4
      note[$1] = $5
    }
    next
  }
  $0 != "" {
    path = $0
    if (path in gate) {
      printf "%s\t%s\t%s\t%s\t%s\n", path, gate[path], checks[path], docs[path], note[path]
      mapped += 1
    } else {
      printf "%s\tUNKNOWN\tunmapped\tunknown\tNo exact workflow mapping for changed upstream file; %s\n", path, suggest(path)
      unknown += 1
    }
  }
  END {
    printf "upstream diff workflow summary: mapped=%d unknown=%d\n", mapped + 0, unknown + 0
    if (unknown > 0) exit 1
  }
' "$WORKFLOW_LEDGER" "$CHANGED_FILES"
