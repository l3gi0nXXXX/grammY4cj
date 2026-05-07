#!/usr/bin/env sh
set -eu

GRAMMY_DIR="${GRAMMY_DIR:-/Users/l3gi0n/work/workspace_cangjie/grammY}"
SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"

runtime_rows=0
test_rows=0
missing_files=0

print_header() {
  printf '%-38s | %-58s | %-6s | %s\n' "upstream" "grammY4cj trace" "gate" "note"
  printf '%-38s-+-%-58s-+-%-6s-+-%s\n' \
    "--------------------------------------" \
    "----------------------------------------------------------" \
    "------" \
    "------------------------------"
}

trace_row() {
  kind="$1"
  upstream="$2"
  port_files="$3"
  gate="$4"
  note="$5"
  status="$note"

  if [ "$kind" = "runtime" ]; then
    runtime_rows=$((runtime_rows + 1))
  else
    test_rows=$((test_rows + 1))
  fi

  if [ ! -f "$GRAMMY_DIR/$upstream" ]; then
    status="$status; missing upstream file"
    missing_files=$((missing_files + 1))
  fi

  for port_file in $port_files; do
    if [ ! -e "$REPO_DIR/$port_file" ]; then
      status="$status; missing port file $port_file"
      missing_files=$((missing_files + 1))
    fi
  done

  printf '%-38s | %-58s | %-6s | %s\n' "$upstream" "$port_files" "$gate" "$status"
}

printf 'Runtime source trace\n'
print_header
trace_row runtime "src/README.md" "src/README.md" "G9.4" "module docs and source map"
trace_row runtime "src/bot.ts" "src/bot/bot.cj src/bot/internal_runtime.cj src/bot/bot_test.cj" "G6" "Bot shell and polling contracts"
trace_row runtime "src/composer.ts" "src/composer/composer.cj src/composer/composer_test.cj" "G8.3" "20-control diff tracked"
trace_row runtime "src/context.ts" "src/context/context.cj src/context/context_test.cj" "G8.2" "shortcut target diff tracked"
trace_row runtime "src/convenience/constants.ts" "src/convenience/constants.cj src/convenience/constants_test.cj" "G5" "constants parity"
trace_row runtime "src/convenience/frameworks.ts" "src/convenience/frameworks.cj src/convenience/frameworks_test.cj" "G5" "framework adapter names"
trace_row runtime "src/convenience/inline_query.ts" "src/convenience/inline_query.cj src/convenience/inline_query_test.cj" "G5" "inline result builders"
trace_row runtime "src/convenience/input_media.ts" "src/convenience/input_media.cj src/convenience/input_media_test.cj" "G5" "input media builders"
trace_row runtime "src/convenience/keyboard.ts" "src/convenience/keyboard.cj src/convenience/keyboard_test.cj" "G5" "keyboard builders"
trace_row runtime "src/convenience/session.ts" "src/convenience/session.cj src/convenience/session_test.cj" "G5" "session storage contracts"
trace_row runtime "src/convenience/webhook.ts" "src/convenience/webhook.cj src/convenience/webhook_test.cj" "G5" "webhook callback adapters"
trace_row runtime "src/core/api.ts" "src/core/api.cj src/core/api_wrapper_table.cj src/core/api_test.cj" "G8.1" "180 wrapper names"
trace_row runtime "src/core/client.ts" "src/core/client.cj src/core/client_test.cj" "G3" "client options and fake HTTP"
trace_row runtime "src/core/error.ts" "src/core/error.cj src/core/error_test.cj" "G3" "error envelopes"
trace_row runtime "src/core/payload.ts" "src/core/payload.cj src/core/payload_test.cj" "G3" "payload serialization"
trace_row runtime "src/filter.ts" "src/filter/filter.cj src/filter/filter_test.cj" "G4" "filter query matcher"
trace_row runtime "src/mod.ts" "src/mod.cj src/mod_test.cj" "G9.5" "root exports and baseline constants"
trace_row runtime "src/platform.deno.ts" "src/platform/platform.cj src/platform/platform_test.cj" "G2" "platform abstraction"
trace_row runtime "src/platform.node.ts" "src/platform/platform.cj src/platform/platform_test.cj" "G2" "platform abstraction"
trace_row runtime "src/platform.web.ts" "src/platform/platform.cj src/platform/platform_test.cj" "G2" "platform abstraction"
trace_row runtime "src/shim.node.ts" "src/platform/platform.cj src/platform/platform_test.cj" "G2" "node shim represented by platform"
trace_row runtime "src/types.deno.ts" "src/types/telegram_types.cj src/types/types_test.cj" "G1" "type facade"
trace_row runtime "src/types.node.ts" "src/types/telegram_types.cj src/types/types_test.cj" "G1" "type facade"
trace_row runtime "src/types.ts" "src/types/telegram_types.cj src/types/input_file.cj src/types/types_test.cj" "G1" "Telegram object subset"
trace_row runtime "src/types.web.ts" "src/types/telegram_types.cj src/types/types_test.cj" "G1" "type facade"

printf '\nTest source trace\n'
print_header
trace_row test "test/bot.test.ts" "src/bot/bot_test.cj" "G6" "Bot tests"
trace_row test "test/composer.test.ts" "src/composer/composer_test.cj" "G8.3" "runtime Composer subset"
trace_row test "test/composer.type.test.ts" "src/composer/composer_test.cj" "G9.3" "type-level parity noted as gap"
trace_row test "test/context.test.ts" "src/context/context_test.cj" "G8.2" "runtime Context subset"
trace_row test "test/context.type.test.ts" "src/context/context_test.cj" "G9.3" "type-level parity noted as gap"
trace_row test "test/convenience/constants.test.ts" "src/convenience/constants_test.cj" "G5" "constants tests"
trace_row test "test/convenience/frameworks.test.ts" "src/convenience/frameworks_test.cj" "G5" "framework tests"
trace_row test "test/convenience/inline_query.test.ts" "src/convenience/inline_query_test.cj" "G5" "inline query tests"
trace_row test "test/convenience/input_media.test.ts" "src/convenience/input_media_test.cj" "G5" "input media tests"
trace_row test "test/convenience/keyboard.test.ts" "src/convenience/keyboard_test.cj" "G5" "keyboard tests"
trace_row test "test/convenience/session.test.ts" "src/convenience/session_test.cj" "G5" "session tests"
trace_row test "test/convenience/webhook.test.ts" "src/convenience/webhook_test.cj" "G5" "webhook tests"
trace_row test "test/core/client.test.ts" "src/core/client_test.cj" "G3" "client tests"
trace_row test "test/core/error.test.ts" "src/core/error_test.cj" "G3" "error tests"
trace_row test "test/core/payload.test.ts" "src/core/payload_test.cj" "G3" "payload tests"
trace_row test "test/deps.test.ts" "scripts/check_dependency_boundaries.sh src/architecture/dependency_boundary_test.cj" "G7" "dependency boundary"
trace_row test "test/filter.test.ts" "src/filter/filter_test.cj" "G4" "filter tests"
trace_row test "test/types.test.ts" "src/types/types_test.cj" "G1" "type shape tests"

printf '\nsource trace matrix summary: runtime_rows=%s test_rows=%s missing_files=%s\n' \
  "$runtime_rows" "$test_rows" "$missing_files"

if [ "$runtime_rows" != "25" ] || [ "$test_rows" != "18" ] || [ "$missing_files" != "0" ]; then
  exit 1
fi
