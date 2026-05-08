# Contributing to grammY4cj

First of all, thanks for your interest in helping out!
grammY4cj is a Cangjie port of grammY, so every change should preserve the
public behavior, source layout intent, and development model of upstream grammY
as closely as Cangjie permits.

This project is developed gate by gate against a pinned upstream grammY
checkout. Keep changes small, source-traced, and validated before handoff.

## What Can I Do?

In short: anything that helps bring grammY's public API and behavior to
Cangjie.

If you are unsure whether your changes are welcome, open an issue or ask before
starting a large change. Core runtime, tests, docs, package metadata, and
release engineering are all useful, but each change must stay within its stated
scope.

## A Few Words on Cangjie and grammY

**TL;DR** working on grammY4cj means working on a Cangjie project whose public
contract is upstream grammY.

grammY is written in TypeScript and runs on Deno, Node.js, and web runtimes.
grammY4cj maps the same framework concepts to Cangjie Native: Bot, Context,
Composer, API wrappers, payload handling, filters, convenience builders,
sessions, webhook adapters, and platform boundaries.

The upstream source remains the contract. Cangjie-specific substitutions are
allowed only when they are documented, tested, and kept behind the same public
behavior.

## How to Contribute

There are several areas of contributions, and they have different ways to get
you started.

- **Docs.**
  Public docs should follow the upstream README and contributing-guide shape,
  while explaining Cangjie-specific commands where needed. Keep public docs in
  English and do not include local paths, private workspace names, or tool
  aliases.
- **Core.**
  Core changes should start from the matching upstream files and tests. Preserve
  the API surface unless the Cangjie language boundary requires a documented
  substitute.
- **Tests.**
  Tests must be hermetic. Do not call Telegram, do not load a real token, and
  do not mutate user files.
- **Release engineering.**
  Release work should only change docs, package metadata, and validation
  scripts unless the task explicitly asks for runtime code changes.
- **Issues, bugs, and everything else.**
  Reports and small follow-up fixes are welcome when they include enough source
  context to reproduce or verify the issue.

### Working on the Core of grammY4cj Using Cangjie (Recommended)

Before changing the port, point `GRAMMY_DIR` at the pinned upstream grammY
checkout and read the matching upstream files. For release and documentation
work, read at least:

- `$GRAMMY_DIR/README.md`
- `$GRAMMY_DIR/src/README.md`
- `$GRAMMY_DIR/CONTRIBUTING.md`
- The local `README.md`, `src/README.md`, and `CONTRIBUTING.md`
- `scripts/check_upstream_contract.sh`
- `scripts/check_source_trace_matrix.sh`
- `scripts/check_dependency_boundaries.sh`
- `scripts/check_public_docs.sh`

#### Coding

If you want to read or modify grammY4cj's code, you can do the following.

1. Install the Cangjie toolchain.
2. Clone this repo.
3. Create or enter an isolated worktree for the change.
4. Verify the branch and preserve unrelated dirty files.
5. Read the matching upstream source and tests before editing Cangjie files.
6. Run the release checks below before opening a pull request.

You are now ready to work on grammY4cj.

#### Release Checks

Run the full local release gate before handoff:

```sh
GRAMMY4CJ_HARD_FAIL=1 sh scripts/check_upstream_contract.sh
sh scripts/check_source_trace_matrix.sh
sh scripts/check_dependency_boundaries.sh
sh scripts/check_default_acceptance_matrix.sh
sh scripts/check_platform_gates.sh
sh scripts/check_root_public_surface.sh
sh scripts/check_public_docs.sh
source "$CANGJIE_SDK_HOME/envsetup.sh"
cjpm clean && cjpm build -i && cjpm test
```

The release gate covers:

- **Upstream contract.**
  The pinned upstream HEAD, tag, file counts, Bot API badge, constants, API
  wrappers, Context shortcut targets, Composer controls, docs headings, and test
  parity ledger must match or have an explicit accepted classification.
- **Hard fail.**
  `GRAMMY4CJ_HARD_FAIL=1` turns known Gate 8 drift categories into release
  blockers.
- **Source trace.**
  `scripts/check_source_trace_matrix.sh` must cover every pinned upstream
  runtime file and test file.
- **Dependency boundary.**
  `scripts/check_dependency_boundaries.sh` must keep core, context, platform,
  and convenience imports inside their documented layer boundaries.
- **Platform and package gates.**
  `scripts/check_platform_gates.sh`,
  `scripts/check_root_public_surface.sh`, and
  `scripts/check_default_acceptance_matrix.sh` must keep the Deno-equivalent,
  Node-equivalent, Web-equivalent, and Cangjie Native facades aligned with the
  root package manifest and the default offline acceptance matrix.
- **Build and test.**
  `cjpm clean && cjpm build -i && cjpm test` must pass after the Cangjie
  environment is loaded.
- **Public docs scan.**
  `scripts/check_public_docs.sh` must pass for `README.md`,
  `CONTRIBUTING.md`, `src/README.md`, and `LICENSE`.

#### Package Metadata

Keep `cjpm.toml`, `README.md`, `src/README.md`, root exports, platform facade
contracts, and exported baseline constants consistent. The package name is
`grammy4cj`, the package version must match the public `GRAMMY4CJ_VERSION`
constant, the README Bot API badge must match `TELEGRAM_BOT_API_VERSION`, and
the source map must describe the same pinned upstream baseline as the exported
baseline constants. Upstream TypeScript conditional exports and type-only
exports are tracked as Cangjie package-model boundaries, not as separate Cangjie
runtime entry files.
