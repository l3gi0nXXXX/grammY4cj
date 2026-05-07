# Contributing

grammY4cj is being ported gate by gate from upstream grammY. Keep every change
small, source-traced, isolated in a git worktree, and validated against the
pinned upstream checkout before handoff.

## Worktree Safety

- Work only in the active isolated worktree unless a task explicitly names a
  different path.
- Do not rewrite, reset, revert, or cherry-pick over another agent's branch.
- Preserve unrelated dirty files. If a required edit conflicts with another
  change, stop and ask before proceeding.
- Manual file edits must be made with `apply_patch`.

## Upstream References

Before changing a gate, set `GRAMMY_DIR` to the upstream grammY checkout and
read the matching upstream files under that directory. Gate 8 and Gate 9 work
must read at least:

- `$GRAMMY_DIR/README.md`
- `$GRAMMY_DIR/src/README.md`
- `$GRAMMY_DIR/CONTRIBUTING.md`
- The local `README.md`, `src/README.md`, and `CONTRIBUTING.md`
- `scripts/check_upstream_contract.sh`
- `scripts/check_source_trace_matrix.sh`
- `scripts/check_dependency_boundaries.sh`
- `develop_steps/grammY4cj-framework-grammy-layer0-layer1-analysis-2026-05-06.md` when present in the worktree or main workspace

## Gate Start Flow

1. Create or enter the gate-specific worktree and verify the branch with
   `git status --short --branch`.
2. Read the matching upstream source and tests before changing Cangjie code or
   docs.
3. Identify the public API, control-flow, payload, or docs contract that the
   gate claims.
4. Add or update Cangjie tests that observe the changed public interface.
5. Keep tests hermetic: no Telegram network, no real token, no real user config,
   and no mutation of user files.
6. Run the full validation set.
7. Commit one focused change on the gate branch and report changed files,
   validation output, and residual gaps.

## Gate Workflow

Run gates in this order unless a maintainer explicitly changes the plan:

1. G8.1 API method diff.
2. G8.2 Context `this.api.*` callsite and target diff.
3. G8.3 Composer 20-control diff.
4. G8.4 Test count per file diff.
5. G8.5 Docs heading diff.
6. G9.1 Baseline pin check.
7. G9.2 Source trace matrix check.
8. G9.3 Test parity ledger update.
9. G9.4 README and source docs update.
10. G9.5 Root export and baseline constant check.
11. G9.6 CI validation handoff.

## Validation and CI

Run the full local acceptance set before handing off:

```sh
sh scripts/check_upstream_contract.sh
sh scripts/check_source_trace_matrix.sh
sh scripts/check_dependency_boundaries.sh
source "$CANGJIE_SDK_HOME/envsetup.sh"
cjpm clean && cjpm build -i && cjpm test
```

If OpenSSL linkage fails on macOS, export the OpenSSL 3 library path before
running the same Cangjie gate:

```sh
export DYLD_LIBRARY_PATH="$OPENSSL3_LIB_DIR:$DYLD_LIBRARY_PATH"
source "$CANGJIE_SDK_HOME/envsetup.sh"
cjpm clean && cjpm build -i && cjpm test
```

The contract script has two modes:

| Mode | Command | Behavior |
|---|---|---|
| Report mode | `sh scripts/check_upstream_contract.sh` | Fails on pinned baseline drift and API wrapper drift; reports known implementation gaps. |
| Hard-fail mode | `GRAMMY4CJ_HARD_FAIL=1 sh scripts/check_upstream_contract.sh` | Also fails on Context missing targets, Composer missing controls, upstream test ledger mismatches, and unexplained docs heading drift. |

Structured artifacts can be written without changing repository files:

```sh
GRAMMY4CJ_ARTIFACT_DIR="$TMPDIR/grammy4cj-sync" sh scripts/check_upstream_contract.sh
```

That command emits TSV files for source trace rows, source trace summary, and
Gate 8/9 phase status. Use a temporary directory for artifacts; do not write
them into source-controlled runtime paths unless a task explicitly asks for it.

## Documentation Notes

Root README and `src/README.md` must either mirror upstream headings or record a
concrete grammY4cj-specific exemption. The check script looks for these markers:

- `grammy4cj:docs-heading-exemptions root`
- `grammy4cj:docs-heading-exemptions src`

`develop_steps/` is ignored by git in this repository, but gate analysis files
still need to be written there for local handoff. When integrating a docs-sync
branch, manually append the ignored `develop_steps` section in the main
worktree or intentionally force-add it if the maintainer wants that history in
git.
