# grammY4cj

grammY4cj is a Cangjie port of the grammY framework surface. The current
repository tracks the upstream grammY baseline below and implements a Layer 0
to Layer 1 runtime subset with explicit sync reports for the larger upstream
surface.

## Upstream Baseline

- Upstream checkout: `/Users/l3gi0n/work/workspace_cangjie/grammY`
- Baseline HEAD: `c865dd3a4d26911b01c83695e3845c7245870a5d`
- Baseline tag description: `v1.42.0-5-gc865dd3`
- Required upstream references: `src/mod.ts`, `README.md`, all `src/*.ts`,
  all runtime files under `src/**`, and all `test/**/*.ts`.

## Current Gate State

- `Api` wrapper names are synchronized with upstream `src/core/api.ts`: 180
  upstream methods and 180 Cangjie wrappers.
- `Context` shortcuts are intentionally partial at this gate. The sync script
  reports upstream `this.api.*` callsites and target diffs so the next gate can
  implement missing shortcuts without guessing.
- `Composer` implements the Layer 1 middleware core and reports the missing
  upstream control methods from the 20-control upstream surface.
- Tests are counted per upstream test file and per Cangjie test file. The
  report is a planning ledger, not a claim of full parity.
- `scripts/check_source_trace_matrix.sh` records the source-to-port mapping for
  all 25 upstream runtime files and all 18 upstream test files.

## Validation

Run these commands from this worktree:

```sh
rtk sh scripts/check_upstream_contract.sh
rtk sh scripts/check_dependency_boundaries.sh
rtk zsh -lc 'source /Users/l3gi0n/cangjie100/envsetup.sh && cjpm clean && cjpm build -i && cjpm test'
```

The upstream contract check is expected to pass on the current baseline while
printing known diffs for Context, Composer, tests, docs headings, and the source
trace matrix. API method drift is a hard failure because this gate claims API
wrapper parity.

## Gate Execution Order

1. G8.1: Compare upstream `Api` method names with `src/core/api.cj` and
   `src/core/api_wrapper_table.cj`.
2. G8.2: Count and diff upstream Context `this.api.*` callsites and unique
   target methods against `src/context/context.cj`.
3. G8.3: Diff the 20 upstream Composer controls against
   `src/composer/composer.cj`.
4. G8.4: Count test declarations per upstream and Cangjie test file.
5. G8.5: Diff upstream README headings against local README headings.
6. G9.1: Keep the upstream HEAD and tag pinned in code and scripts.
7. G9.2: Maintain the runtime and test source trace matrix.
8. G9.3: Use the per-file test ledger to pick the next parity slice.
9. G9.4: Update README and `src/README.md` whenever sync scope changes.
10. G9.5: Keep `src/mod.cj` exports and baseline constants aligned with the
    implemented surface.
11. G9.6: Run the validation commands before handing off a gate.

## CI Contract

CI for this repository should run the same three validation commands listed
above. If the CI runner does not provide `rtk`, use equivalent shell commands
inside that runner, but Codex-driven local work in this workspace must keep the
`rtk` prefix.
