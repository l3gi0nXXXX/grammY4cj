#!/usr/bin/env sh
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PLAN="${GRAMMY4CJ_OPTIONAL_INTEGRATION_PLAN:-$REPO_DIR/src/architecture/optional_integration_test_plan.tsv}"

if [ ! -f "$PLAN" ]; then
  printf 'FAIL missing optional integration plan: %s\n' "$PLAN"
  exit 1
fi

expected_header='id	upstream_scope	gate	layer	test_name	env_gate	required_adapter	requires_network	requires_file	requires_framework_server	default_skip	token_policy	isolation	pass_condition'
actual_header="$(sed -n '1p' "$PLAN")"
if [ "$actual_header" != "$expected_header" ]; then
  printf 'FAIL optional integration plan header mismatch\n'
  printf 'expected: %s\n' "$expected_header"
  printf 'actual:   %s\n' "$actual_header"
  exit 1
fi

awk -F '\t' '
BEGIN {
  failures = 0
}
NR == 1 { next }
{
  row_count += 1
  if (NF != 14) {
    printf("FAIL row %d has %d columns, expected 14\n", NR, NF)
    failures += 1
    next
  }
  if (seen[$1]++) {
    printf("FAIL duplicate id: %s\n", $1)
    failures += 1
  }
  if ($3 !~ /^G[0-9]+/) {
    printf("FAIL %s has invalid gate: %s\n", $1, $3)
    failures += 1
  }
  if ($4 != "fake-contract" && $4 != "real-adapter") {
    printf("FAIL %s has invalid layer: %s\n", $1, $4)
    failures += 1
  }
  if ($8 != "yes" && $8 != "no") {
    printf("FAIL %s has invalid requires_network: %s\n", $1, $8)
    failures += 1
  }
  if ($9 != "yes" && $9 != "no") {
    printf("FAIL %s has invalid requires_file: %s\n", $1, $9)
    failures += 1
  }
  if ($10 != "yes" && $10 != "no") {
    printf("FAIL %s has invalid requires_framework_server: %s\n", $1, $10)
    failures += 1
  }
  if ($11 != "yes") {
    printf("FAIL %s must be default skipped, got: %s\n", $1, $11)
    failures += 1
  }
  if ($6 !~ /GRAMMY4CJ_OPTIONAL_INTEGRATION=1/) {
    printf("FAIL %s missing global opt-in env gate\n", $1)
    failures += 1
  }
  if (($8 == "yes" || $9 == "yes" || $10 == "yes") && $6 !~ /GRAMMY4CJ_OPTIONAL_/) {
    printf("FAIL %s has real resource requirement without optional env gate\n", $1)
    failures += 1
  }
  if ($6 ~ /GRAMMY4CJ_TELEGRAM_BOT_TOKEN/ && $12 !~ /token-from-env-only/) {
    printf("FAIL %s uses Telegram token gate without token-from-env-only policy\n", $1)
    failures += 1
  }
  if ($6 ~ /GRAMMY4CJ_TELEGRAM_BOT_TOKEN/ && $12 !~ /redact-token/) {
    printf("FAIL %s uses Telegram token gate without redaction policy\n", $1)
    failures += 1
  }
  if ($0 ~ /[0-9]{6,}:[A-Za-z0-9_-]{20,}/) {
    printf("FAIL %s appears to contain a raw Telegram token\n", $1)
    failures += 1
  }
  if ($13 == "" || $14 == "") {
    printf("FAIL %s isolation and pass_condition must be non-empty\n", $1)
    failures += 1
  }
  if ($4 == "fake-contract") {
    fake_count += 1
    if ($8 != "no" || $9 != "no" || $10 != "no" || $12 != "no-token") {
      printf("FAIL %s fake-contract row must not require network, files, server, or token\n", $1)
      failures += 1
    }
  }
  if ($4 == "real-adapter") {
    real_count += 1
  }
  if ($7 ~ /CoreFetch/) core_seen = 1
  if ($7 ~ /BotRuntime|RealBotRuntime/) bot_seen = 1
  if ($7 ~ /framework|Framework|Webhook/) framework_seen = 1
  if ($7 ~ /InputFile|PlatformRawSource/) input_seen = 1
  if ($6 ~ /GRAMMY4CJ_TELEGRAM_BOT_TOKEN/) telegram_seen = 1
}
END {
  if (row_count < 10) {
    printf("FAIL optional integration plan rows minimum=10 actual=%d\n", row_count)
    failures += 1
  }
  if (fake_count < 4) {
    printf("FAIL fake-contract coverage minimum=4 actual=%d\n", fake_count)
    failures += 1
  }
  if (real_count < 4) {
    printf("FAIL real-adapter coverage minimum=4 actual=%d\n", real_count)
    failures += 1
  }
  if (!core_seen || !bot_seen || !framework_seen || !input_seen || !telegram_seen) {
    printf("FAIL missing required adapter coverage core=%d bot=%d framework=%d input=%d telegram=%d\n", core_seen + 0, bot_seen + 0, framework_seen + 0, input_seen + 0, telegram_seen + 0)
    failures += 1
  }
  if (failures > 0) {
    exit 1
  }
  printf("optional integration plan checks passed rows=%d fake=%d real=%d\n", row_count, fake_count, real_count)
}
' "$PLAN"
