# grammY4cj Session Quickstart

This phase exposes session building blocks from `grammy4cj.convenience`.
The root package should re-export them from `src/mod.cj` during final integration.

The current Cangjie port uses a static `SessionContext<T>` wrapper instead of mutating
`Context` dynamically. This keeps the implementation compatible with the existing
`Context` and `Composer` skeletons.

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
