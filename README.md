# The Telegram Bot Framework

grammY4cj is the Cangjie port of upstream grammY. Its implementation target is
source-level parity with the pinned upstream checkout, not a reduced Telegram
bot framework.

Pinned upstream:

- Checkout: `/Users/l3gi0n/work/workspace_cangjie/grammY`
- HEAD: `c865dd3a4d26911b01c83695e3845c7245870a5d`
- Tag description: `v1.42.0-5-gc865dd3`

## _[docs.](https://grammy.dev) [reference.](https://grammy.dev/ref) [chat.](https://telegram.me/grammyjs) [news.](https://telegram.me/grammyjs_news)_

Use the upstream grammY docs and reference as the semantic authority. Use this
repository's sync scripts to check which Cangjie surfaces are already mapped to
that authority.

## Quickstart

Set up the Cangjie SDK before building:

```sh
rtk zsh -lc 'source /Users/l3gi0n/cangjie100/envsetup.sh && cjpm clean && cjpm build -i && cjpm test'
```

If local OpenSSL linkage fails, run the same gate with the Homebrew OpenSSL
library path in the same shell:

```sh
rtk zsh -lc 'export DYLD_LIBRARY_PATH="/opt/homebrew/opt/openssl@3/lib:$DYLD_LIBRARY_PATH" && source /Users/l3gi0n/cangjie100/envsetup.sh && cjpm clean && cjpm build -i && cjpm test'
```

Unit tests must use fakes only. Do not read real bot tokens, do not call the
Telegram network, and do not modify real user configuration or filesystem
state.

## Going Further

Gate work starts by reading the matching upstream grammY source and tests, then
updating the Cangjie implementation and tests inside an isolated git worktree.
Before handoff, every gate must run:

```sh
rtk sh scripts/check_upstream_contract.sh
rtk sh scripts/check_source_trace_matrix.sh
rtk sh scripts/check_dependency_boundaries.sh
rtk zsh -lc 'source /Users/l3gi0n/cangjie100/envsetup.sh && cjpm clean && cjpm build -i && cjpm test'
```

For Gate 10 or release-candidate checks, enable strict drift handling:

```sh
rtk env GRAMMY4CJ_HARD_FAIL=1 sh scripts/check_upstream_contract.sh
```

To write structured sync artifacts for review:

```sh
rtk env GRAMMY4CJ_ARTIFACT_DIR=/tmp/grammy4cj-sync sh scripts/check_upstream_contract.sh
```

## Resources

### [grammY website](https://grammy.dev)

Primary user documentation and the behavior reference for grammY4cj.

### [grammY API reference](https://grammy.dev/ref)

Public API reference used to check method names, payload shapes, and return
types when a Cangjie wrapper is added or changed.

### [grammY examples](https://github.com/grammyjs/examples)

Example bots used as behavioral references after the core Cangjie surface is
complete enough to run end-to-end examples.

### [Awesome grammY](https://github.com/grammyjs/awesome-grammY)

Ecosystem reference for future plugin compatibility, not a source of truth for
the core port.

### [grammY chat](https://t.me/grammyjs)

Upstream community channel. grammY4cj implementation decisions still need to be
verified against source code before being accepted.

### [grammY news](https://t.me/grammyjs_news)

Upstream release and ecosystem update channel. New upstream commits must go
through the sync flow before Cangjie code is changed.

### [Telegram Bot API Reference](https://core.telegram.org/bots/api)

Telegram's API reference. grammY source remains the primary framework contract;
Telegram docs are used to understand payload and object semantics.

## Deno Support

Upstream grammY is a TypeScript project with Deno-first source and Node/web
build targets. grammY4cj is a Cangjie port, so Deno is not a runtime dependency
for this repository. The heading is intentionally retained for README heading
parity with upstream.

## JavaScript Bundles

Upstream grammY publishes JavaScript bundles. grammY4cj does not publish
JavaScript bundles; this heading is retained so README heading drift is visible
and explicitly explained.

## [Contribution Guide »](./CONTRIBUTING.md)

See the contribution guide for worktree isolation, Gate start flow, validation
commands, and strict sync mode.

## Contributors ✨

Contributor attribution for this Cangjie port is maintained by the repository
history. The upstream all-contributors table is not copied because this
repository is a port, not the upstream project.

## grammY4cj Port Sync Contract

<!-- grammy4cj:docs-heading-exemptions root -->

This local heading is the only root README heading that is not present in
upstream grammY. It is exempt because this port needs a stable place for
Cangjie-specific SDK, OpenSSL, no-side-effect test, worktree, artifact, and
hard-fail sync instructions.

Heading policy:

| Heading source | Policy |
|---|---|
| Upstream README headings | Must be present in this README unless a future change records a concrete exemption here. |
| grammY4cj-specific headings | Must be listed in this section with a reason. |
| `src/README.md` headings | Checked separately by `scripts/check_upstream_contract.sh`. |

The contract script is both a report and a gate. Default mode reports known
implementation gaps and fails on baseline or API wrapper drift. Strict mode
(`GRAMMY4CJ_HARD_FAIL=1` or `--hard-fail`) also fails on Context missing
targets, Composer missing controls, upstream test ledger mismatches, and
unexplained docs heading drift.
