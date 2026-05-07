# grammY

This directory contains the Cangjie source map for the pinned grammY baseline
`c865dd3a4d26911b01c83695e3845c7245870a5d`
(`v1.42.0-5-gc865dd3`). The heading is kept aligned with upstream
`src/README.md`; the implementation language and module layout are Cangjie.

## Quickstart

Run the port's full local gate from the repository root:

```sh
source "$CANGJIE_SDK_HOME/envsetup.sh"
cjpm clean && cjpm build -i && cjpm test
```

Use fake fixtures for examples and tests. Do not call Telegram, do not load a
real token, and do not mutate real user configuration.

## grammY4cj Source Map

<!-- grammy4cj:docs-heading-exemptions src -->

This local heading is exempt from upstream heading parity because the port is
organized by Cangjie runtime layer rather than by a one-file-to-one-file
TypeScript layout. The source trace matrix is therefore the authoritative map
for upstream coverage.

Layer layout:

| Cangjie path | Upstream responsibility |
|---|---|
| `src/core` | API wrappers, client options, payload handling, cancellation, and error envelopes. |
| `src/types` | Telegram object facade and `InputFile` platform source model. |
| `src/context` | Context properties, predicates, and context-aware API shortcuts. |
| `src/composer` | Middleware composition, branching, routing, lazy middleware, fork, and error boundaries. |
| `src/convenience` | Constants, builders, sessions, framework adapters, and webhook helpers. |
| `src/platform` | Deno, Node, web, and shim runtime boundaries represented as Cangjie platform contracts. |
| `src/test_support` | Local fakes used by Cangjie unit tests. |

Trace commands:

```sh
sh scripts/check_source_trace_matrix.sh
GRAMMY4CJ_TRACE_ARTIFACT_DIR="$TMPDIR/grammy4cj-trace" sh scripts/check_source_trace_matrix.sh
```

The matrix covers all 25 upstream runtime files, including upstream
`src/README.md`, and all 18 upstream test files.
