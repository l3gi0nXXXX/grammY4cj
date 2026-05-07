#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOW_LEDGER="${GRAMMY4CJ_UPSTREAM_DIFF_WORKFLOW:-$REPO_DIR/src/architecture/upstream_diff_workflow.tsv}"
CHANGED_FILES=""
BASE_REF=""
HEAD_REF=""
VALIDATE_ONLY=0

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
      printf "%s\tUNKNOWN\tunmapped\tunknown\tNo workflow mapping for changed upstream file\n", path
      unknown += 1
    }
  }
  END {
    printf "upstream diff workflow summary: mapped=%d unknown=%d\n", mapped + 0, unknown + 0
    if (unknown > 0) exit 1
  }
' "$WORKFLOW_LEDGER" "$CHANGED_FILES"
