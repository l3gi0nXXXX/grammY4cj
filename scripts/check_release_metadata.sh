#!/usr/bin/env sh
set -eu

LC_ALL=C
export LC_ALL

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"

EXPECTED_PACKAGE_NAME="grammy4cj"
EXPECTED_PACKAGE_VERSION="0.1.0"
EXPECTED_BOT_API_VERSION="9.6"
EXPECTED_UPSTREAM_HEAD="c865dd3a4d26911b01c83695e3845c7245870a5d"
EXPECTED_UPSTREAM_TAG="v1.42.0-5-gc865dd3"

CI_WORKFLOW="$REPO_DIR/.github/workflows/ci.yml"
RELEASE_WORKFLOW="$REPO_DIR/.github/workflows/release.yml"
RELEASE_NOTES="$REPO_DIR/.github/release.yml"

failures=0

record_failure() {
  failures=$((failures + 1))
}

fail() {
  printf 'FAIL %s\n' "$1"
  record_failure
}

ok() {
  printf 'ok %s\n' "$1"
}

check_file() {
  file="$1"
  label="$2"
  if [ -f "$file" ]; then
    ok "found $label"
  else
    fail "missing $label: ${file#$REPO_DIR/}"
  fi
}

check_contains() {
  file="$1"
  pattern="$2"
  label="$3"
  if grep -F "$pattern" "$file" >/dev/null 2>&1; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_eq() {
  label="$1"
  actual="$2"
  expected="$3"
  if [ "$actual" = "$expected" ]; then
    printf 'ok %s=%s\n' "$label" "$actual"
  else
    printf 'FAIL %s expected=%s actual=%s\n' "$label" "$expected" "$actual"
    record_failure
  fi
}

extract_toml_string() {
  key="$1"
  file="$2"
  sed -n "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" | head -n 1
}

extract_cj_string_constant() {
  name="$1"
  file="$2"
  awk -v n="$name" '
    $0 ~ "public let " n {
      split($0, parts, "\"")
      print parts[2]
      exit
    }
  ' "$file"
}

extract_bot_api_badge_version() {
  sed -n 's/.*Bot%20API-\([0-9.][0-9.]*\)-blue.*/\1/p' "$1" | head -n 1
}

check_workflow_forbidden_markers() {
  workflow="$1"
  label="$2"
  local_home="/Users/l3""gi0n"
  workspace_marker="workspace_""cangjie"
  toolchain_marker="cangjie""100"
  internal_command="r""tk"
  forbidden_pattern="$local_home|$workspace_marker|$toolchain_marker|$internal_command"

  if grep -En "$forbidden_pattern" "$workflow" >/dev/null 2>&1; then
    printf 'FAIL %s contains forbidden local or internal marker\n' "$label"
    grep -En "$forbidden_pattern" "$workflow" || true
    record_failure
  else
    ok "$label has no forbidden local or internal marker"
  fi
}

check_ci_workflow() {
  check_file "$CI_WORKFLOW" ".github/workflows/ci.yml"
  [ -f "$CI_WORKFLOW" ] || return

  check_workflow_forbidden_markers "$CI_WORKFLOW" "ci workflow"
  for job in "architecture:" "public-docs:" "upstream-contract:" "build-test:"; do
    check_contains "$CI_WORKFLOW" "$job" "ci workflow contains job $job"
  done
  for step in \
    "scripts/check_architecture_artifacts.sh" \
    "scripts/check_formal_substitute_ledger.sh" \
    "scripts/check_optional_integration_plan.sh" \
    "scripts/check_dependency_boundaries.sh" \
    "scripts/check_upstream_sync_process.sh" \
    "scripts/check_public_docs.sh" \
    "scripts/check_release_metadata.sh" \
    "scripts/check_upstream_contract.sh" \
    "scripts/check_source_trace_matrix.sh" \
    "cjpm clean && cjpm build -i && cjpm test"
  do
    check_contains "$CI_WORKFLOW" "$step" "ci workflow contains step $step"
  done
  check_contains "$CI_WORKFLOW" "self-hosted" "ci build-test is self-hosted"
  check_contains "$CI_WORKFLOW" "cangjie" "ci build-test requires Cangjie toolchain label"
}

check_release_workflow() {
  check_file "$RELEASE_WORKFLOW" ".github/workflows/release.yml"
  [ -f "$RELEASE_WORKFLOW" ] || return

  check_workflow_forbidden_markers "$RELEASE_WORKFLOW" "release workflow"
  check_contains "$RELEASE_WORKFLOW" "tags:" "release workflow is tag-triggered"
  check_contains "$RELEASE_WORKFLOW" "\"v*\"" "release workflow tag pattern"
  check_contains "$RELEASE_WORKFLOW" "scripts/check_release_metadata.sh" "release workflow checks release metadata before publication"
  check_contains "$RELEASE_WORKFLOW" "scripts/check_public_docs.sh" "release workflow checks public docs"
  check_contains "$RELEASE_WORKFLOW" "scripts/check_upstream_contract.sh" "release workflow checks upstream contract"
  check_contains "$RELEASE_WORKFLOW" "GRAMMY4CJ_HARD_FAIL=1" "release workflow runs hard-fail upstream contract"
  check_contains "$RELEASE_WORKFLOW" "scripts/check_source_trace_matrix.sh" "release workflow checks source trace"
  check_contains "$RELEASE_WORKFLOW" "scripts/check_dependency_boundaries.sh" "release workflow checks dependency boundaries"
  check_contains "$RELEASE_WORKFLOW" "scripts/check_architecture_artifacts.sh" "release workflow checks architecture artifacts"
  check_contains "$RELEASE_WORKFLOW" "cjpm clean && cjpm build -i && cjpm test" "release workflow runs full Cangjie gate"
  check_contains "$RELEASE_WORKFLOW" "softprops/action-gh-release" "release workflow publishes GitHub release"
  check_contains "$RELEASE_WORKFLOW" "dist/SHA256SUMS" "release workflow writes artifact checksums"
  if grep -En 'TELEGRAM|BOT_TOKEN|TOKEN' "$RELEASE_WORKFLOW" >/dev/null 2>&1; then
    printf 'FAIL release workflow must not reference Telegram token configuration\n'
    grep -En 'TELEGRAM|BOT_TOKEN|TOKEN' "$RELEASE_WORKFLOW" || true
    record_failure
  else
    ok "release workflow does not reference Telegram token configuration"
  fi
}

check_release_notes() {
  check_file "$RELEASE_NOTES" ".github/release.yml"
  [ -f "$RELEASE_NOTES" ] || return

  check_contains "$RELEASE_NOTES" "changelog:" "release notes config has changelog"
  check_contains "$RELEASE_NOTES" "documentation" "release notes config excludes documentation label"
}

check_package_metadata() {
  readme="$REPO_DIR/README.md"
  cjpm="$REPO_DIR/cjpm.toml"
  mod="$REPO_DIR/src/mod.cj"
  constants="$REPO_DIR/src/convenience/constants.cj"

  for file in "$readme" "$cjpm" "$mod" "$constants"; do
    if [ ! -f "$file" ]; then
      fail "missing metadata source: ${file#$REPO_DIR/}"
      return
    fi
  done

  readme_bot_api="$(extract_bot_api_badge_version "$readme")"
  package_name="$(extract_toml_string name "$cjpm")"
  package_version="$(extract_toml_string version "$cjpm")"
  mod_version="$(extract_cj_string_constant GRAMMY4CJ_VERSION "$mod")"
  mod_head="$(extract_cj_string_constant GRAMMY_BASELINE_HEAD "$mod")"
  mod_tag="$(extract_cj_string_constant GRAMMY_BASELINE_TAG "$mod")"
  bot_api="$(extract_cj_string_constant TELEGRAM_BOT_API_VERSION "$constants")"
  constants_head="$(extract_cj_string_constant GRAMMY_UPSTREAM_BASELINE_HEAD "$constants")"
  constants_tag="$(extract_cj_string_constant GRAMMY_UPSTREAM_BASELINE_TAG "$constants")"

  check_eq "README Bot API badge" "$readme_bot_api" "$EXPECTED_BOT_API_VERSION"
  check_eq "cjpm package name" "$package_name" "$EXPECTED_PACKAGE_NAME"
  check_eq "cjpm package version" "$package_version" "$EXPECTED_PACKAGE_VERSION"
  check_eq "src/mod.cj GRAMMY4CJ_VERSION" "$mod_version" "$package_version"
  check_eq "src/mod.cj GRAMMY_BASELINE_HEAD" "$mod_head" "$EXPECTED_UPSTREAM_HEAD"
  check_eq "src/mod.cj GRAMMY_BASELINE_TAG" "$mod_tag" "$EXPECTED_UPSTREAM_TAG"
  check_eq "TELEGRAM_BOT_API_VERSION" "$bot_api" "$EXPECTED_BOT_API_VERSION"
  check_eq "constants upstream baseline head" "$constants_head" "$EXPECTED_UPSTREAM_HEAD"
  check_eq "constants upstream baseline tag" "$constants_tag" "$EXPECTED_UPSTREAM_TAG"
}

check_public_docs() {
  if sh "$SCRIPT_DIR/check_public_docs.sh"; then
    ok "public docs safety scan"
  else
    fail "public docs safety scan"
  fi
}

check_ci_workflow
check_release_workflow
check_release_notes
check_package_metadata
check_public_docs

if [ "$failures" -ne 0 ]; then
  printf 'release metadata checks failed: %s issue(s)\n' "$failures"
  exit 1
fi

printf 'release metadata checks passed\n'
