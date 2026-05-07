#!/usr/bin/env sh
set -eu

GRAMMY_DIR="${GRAMMY_DIR:-/Users/l3gi0n/work/workspace_cangjie/grammY}"
EXPECTED_HEAD="c865dd3a4d26911b01c83695e3845c7245870a5d"
EXPECTED_TAG="v1.42.0-5-gc865dd3"

actual_head="$(git -C "$GRAMMY_DIR" rev-parse HEAD)"
actual_tag="$(git -C "$GRAMMY_DIR" describe --tags --always)"
runtime_files="$(find "$GRAMMY_DIR/src" -type f \( -name '*.ts' -o -name '*.md' \) | wc -l | tr -d ' ')"
runtime_ts_files="$(find "$GRAMMY_DIR/src" -type f -name '*.ts' | wc -l | tr -d ' ')"
test_files="$(find "$GRAMMY_DIR/test" -type f -name '*.ts' | wc -l | tr -d ' ')"
api_wrappers="$(perl -0ne 'while(/^    (?!private|constructor)(?:async\s+)?([A-Za-z_]\w*)\s*\(/mg){$c++} END{print $c+0}' "$GRAMMY_DIR/src/core/api.ts")"
bdd_tests="$(rg -n '\bit\(' "$GRAMMY_DIR/test" -g '*.ts' | wc -l | tr -d ' ')"
deno_tests="$(rg -n '\bDeno\.test\(' "$GRAMMY_DIR/test" -g '*.ts' | wc -l | tr -d ' ')"

if [ "$actual_head" != "$EXPECTED_HEAD" ]; then
  echo "unexpected grammY HEAD: $actual_head"
  exit 1
fi

if [ "$actual_tag" != "$EXPECTED_TAG" ]; then
  echo "unexpected grammY tag description: $actual_tag"
  exit 1
fi

if [ "$runtime_files" != "25" ]; then
  echo "unexpected src file count including README.md: $runtime_files"
  exit 1
fi

if [ "$runtime_ts_files" != "24" ]; then
  echo "unexpected runtime ts file count: $runtime_ts_files"
  exit 1
fi

if [ "$test_files" != "18" ]; then
  echo "unexpected test file count: $test_files"
  exit 1
fi

if [ "$api_wrappers" != "180" ]; then
  echo "unexpected public Api wrapper count: $api_wrappers"
  exit 1
fi

if [ "$bdd_tests" != "317" ]; then
  echo "unexpected BDD it(...) test count: $bdd_tests"
  exit 1
fi

if [ "$deno_tests" != "10" ]; then
  echo "unexpected Deno.test count: $deno_tests"
  exit 1
fi

echo "upstream contract checks passed"
