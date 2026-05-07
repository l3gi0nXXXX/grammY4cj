# grammY4cj Source Map

This directory contains the Cangjie port of the pinned grammY baseline
`c865dd3a4d26911b01c83695e3845c7245870a5d`
(`v1.42.0-5-gc865dd3`). The port is organized by runtime layer rather than by a
1:1 TypeScript file layout, so the source trace matrix is the authoritative map
for upstream coverage.

## Layer Layout

- `src/core`: API wrapper names, client options, payload handling, cancellation,
  and error envelopes.
- `src/types`: the Telegram object subset required by the current Layer 1
  runtime.
- `src/context`: Context properties, predicates, and the first shortcut slice.
- `src/composer`: middleware composition, branching, routing, lazy middleware,
  and error boundaries.
- `src/convenience`: constants, keyboards, inline query helpers, input media,
  sessions, framework adapters, and webhook callback helpers.
- `src/platform`: Cangjie platform abstraction that represents the upstream
  Deno, Node, web, and shim files.
- `src/test_support`: local fakes used by the Cangjie unit tests.

## Upstream Trace

Run the trace matrix directly when reviewing source coverage:

```sh
rtk sh scripts/check_source_trace_matrix.sh
```

The matrix covers all 25 upstream runtime files, including `src/README.md`, and
all 18 upstream test files. The main contract script also embeds the matrix and
adds API, Context, Composer, test, and heading diffs.

## Known Gate 8 Diffs

- API wrappers: 180 upstream methods are present in `src/core/api.cj` and
  `src/core/api_wrapper_table.cj`.
- Context shortcuts: upstream has 142 `this.api.*` callsites and 136 unique
  targets; this port currently exposes the Layer 1 shortcut subset.
- Composer controls: upstream exposes 20 controls; this port implements the
  middleware core subset and reports missing controls in the sync script.
- Tests: upstream declarations are counted per file and compared with local
  `@TestCase` counts. This is a parity ledger, not a pass/fail coverage claim.

## Session Quickstart

The current Cangjie port uses a static `SessionContext<T>` wrapper instead of
mutating `Context` dynamically. This keeps the implementation compatible with
the existing `Context` and `Composer` skeletons.

```cangjie
import grammy4cj.convenience.{MemorySessionStorage, SessionContext, SessionOptions, session}
import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.types.{Update, UserFromGetMe}

class CounterSession {
    public var count: Int64

    public init(count: Int64) {
        this.count = count
    }
}

func offlineQuickstart(): Int64 {
    let storage = MemorySessionStorage<CounterSession>()
    let options = SessionOptions<CounterSession>({ => CounterSession(0) }, storage)
    let middleware = session<CounterSession>(options)

    // Offline fixture only. This does not call Telegram or start polling.
    let ctx = Context(Update(1001), Api("test-token"), UserFromGetMe(42, true, "grammY4cj", "bot"))

    middleware.handle(ctx, { sessionCtx: SessionContext<CounterSession> =>
        let data = sessionCtx.session()
        data.count += 1
    })

    match (storage.read("1001")) {
        case Some(data) => data.count
        case None => 0
    }
}
```

`lazySession` has the same shape, but it does not read storage until
`sessionCtx.session()` or `sessionCtx.maybeSession()` is called.
