#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
STEP_NO=0

run_step() {
  STEP_NO=$((STEP_NO + 1))
  printf '\n[%s] %s\n' "$STEP_NO" "$1"
  shift
  "$@"
}

skip_step() {
  STEP_NO=$((STEP_NO + 1))
  printf '\n[%s] %s\n' "$STEP_NO" "$1"
  printf 'skip: %s\n' "$2"
}

run_cjpm_gate() {
  if [ -z "${CANGJIE_SDK_HOME:-}" ]; then
    printf 'FAIL cjpm full gate requires CANGJIE_SDK_HOME. Set it to the Cangjie SDK root, or set GRAMMY4CJ_SKIP_CJPM=1.\n'
    exit 2
  fi
  if [ ! -d "$CANGJIE_SDK_HOME" ]; then
    printf 'FAIL CANGJIE_SDK_HOME is not a directory: %s\n' "$CANGJIE_SDK_HOME"
    exit 2
  fi
  if [ ! -f "$CANGJIE_SDK_HOME/envsetup.sh" ]; then
    printf 'FAIL missing Cangjie SDK envsetup.sh under CANGJIE_SDK_HOME: %s/envsetup.sh\n' "$CANGJIE_SDK_HOME"
    exit 2
  fi

  : "${DYLD_LIBRARY_PATH:=}"
  export DYLD_LIBRARY_PATH
  . "$CANGJIE_SDK_HOME/envsetup.sh"

  if ! command -v cjpm >/dev/null 2>&1; then
    printf 'FAIL cjpm was not found after loading CANGJIE_SDK_HOME/envsetup.sh\n'
    exit 2
  fi

  (
    CDPATH= cd "$REPO_DIR"
    cjpm clean
    cjpm build -i
    cjpm test
  )
}

run_step "check_architecture_artifacts" sh "$SCRIPT_DIR/check_architecture_artifacts.sh"
run_step "check_formal_substitute_ledger" sh "$SCRIPT_DIR/check_formal_substitute_ledger.sh"
run_step "check_root_public_surface" sh "$SCRIPT_DIR/check_root_public_surface.sh"
run_step "check_optional_integration_plan" sh "$SCRIPT_DIR/check_optional_integration_plan.sh"
run_step "check_public_docs" sh "$SCRIPT_DIR/check_public_docs.sh"

if [ "${GRAMMY4CJ_SKIP_RELEASE_METADATA:-0}" = "1" ]; then
  skip_step "check_release_metadata" "GRAMMY4CJ_SKIP_RELEASE_METADATA=1"
elif [ -f "$SCRIPT_DIR/check_release_metadata.sh" ]; then
  run_step "check_release_metadata" sh "$SCRIPT_DIR/check_release_metadata.sh"
else
  skip_step "check_release_metadata" "scripts/check_release_metadata.sh not present"
fi

run_step "check_source_trace_matrix" sh "$SCRIPT_DIR/check_source_trace_matrix.sh"
run_step "check_dependency_boundaries" sh "$SCRIPT_DIR/check_dependency_boundaries.sh"
run_step "check_upstream_diff_workflow" sh "$SCRIPT_DIR/check_upstream_diff_workflow.sh" --base v1.42.0 --head HEAD
run_step "check_upstream_contract" sh "$SCRIPT_DIR/check_upstream_contract.sh"
run_step "check_upstream_contract hard-fail" sh "$SCRIPT_DIR/check_upstream_contract.sh" --hard-fail

if [ "${GRAMMY4CJ_SKIP_CJPM:-0}" = "1" ]; then
  skip_step "cjpm full gate" "GRAMMY4CJ_SKIP_CJPM=1"
else
  run_step "cjpm full gate" run_cjpm_gate
fi

printf '\nrelease gate passed\n'
