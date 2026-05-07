# Contributing

This repository is being ported gate by gate from upstream grammY. Keep changes
small, source-traced, and validated against the pinned upstream checkout.

## Worktree Safety

- Work only in the active isolated worktree unless a task explicitly names a
  different path.
- Do not rewrite, reset, or revert another agent's branch.
- Preserve unrelated dirty files. If a required edit conflicts with another
  change, stop and ask before proceeding.
- In this workspace, every shell command issued by Codex must use the `rtk`
  prefix.

## Upstream References

Before changing a gate, inspect the matching upstream files under
`/Users/l3gi0n/work/workspace_cangjie/grammY`. Gate 8 and Gate 9 work must
reference at least these files:

- `src/mod.ts`
- `README.md`
- all top-level `src/*.ts`
- all runtime files under `src/**`
- all tests under `test/**/*.ts`

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
rtk sh scripts/check_upstream_contract.sh
rtk sh scripts/check_dependency_boundaries.sh
rtk zsh -lc 'source /Users/l3gi0n/cangjie100/envsetup.sh && cjpm clean && cjpm build -i && cjpm test'
```

`scripts/check_upstream_contract.sh` is both a guard and a report. It fails on
unexpected upstream baseline changes and API wrapper drift. It prints known
Context, Composer, test, docs, and trace-matrix gaps so later gates can choose
the next implementation slice.

## Documentation Notes

`develop_steps/` is ignored by git in this repository, but gate analysis files
still need to be written there for local handoff. Treat those files as the
working log for source trace decisions and unresolved parity gaps.
