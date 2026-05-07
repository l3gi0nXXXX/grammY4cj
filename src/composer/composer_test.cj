package grammy4cj.composer

import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.types.{Update, UserFromGetMe}
import std.collection.{ArrayList, HashMap}
import std.unittest.*

private func testCtx(updateId: Int64, kind: String): Context {
    Context(Update(updateId, kind), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
}

private func recordingMiddleware(events: ArrayList<String>, name: String): MiddlewareFn {
    { _ctx: Context, next: NextFunction =>
        events.add(name + ":pre")
        next()
        events.add(name + ":post")
    }
}

@Test
public class ComposerMiddlewareTest {
    @TestCase
    public func runUsesOnionExecutionOrder(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.use(recordingMiddleware(events, "a"))
        composer.use(recordingMiddleware(events, "b"))

        run(composer, testCtx(1, "message"))

        @Expect(events.size, 4)
        @Expect(events[0], "a:pre")
        @Expect(events[1], "b:pre")
        @Expect(events[2], "b:post")
        @Expect(events[3], "a:post")
    }

    @TestCase
    public func concatRejectsRepeatedNextCalls(): Unit {
        let composer = Composer()
        composer.use({ _ctx: Context, next: NextFunction =>
            next()
            next()
        })
        composer.use({ _ctx: Context, _next: NextFunction => () })

        var thrown = false
        try {
            run(composer, testCtx(1, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message.contains("next"), true)
        }

        @Expect(thrown, true)
    }

    @TestCase
    public func filterDropAndOnRouteControlFlow(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.filter(
            { ctx: Context => ctx.updateId() % 2 == 0 },
            { _ctx: Context, next: NextFunction =>
                events.add("even")
                next()
            },
        )
        composer.drop(
            { ctx: Context => ctx.updateId() % 2 == 0 },
            { _ctx: Context, next: NextFunction =>
                events.add("odd")
                next()
            },
        )
        composer.on("message:text", { _ctx: Context, _next: NextFunction =>
            events.add("text")
        })

        run(composer, testCtx(2, "message:text"))
        run(composer, testCtx(3, "message:text"))

        @Expect(events.size, 4)
        @Expect(events[0], "even")
        @Expect(events[1], "text")
        @Expect(events[2], "odd")
        @Expect(events[3], "text")
    }

    @TestCase
    public func branchRouteLazyAndErrorBoundaryRunSelectedMiddleware(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.branch(
            { ctx: Context => ctx.updateId() == 1 },
            { _ctx: Context, next: NextFunction =>
                events.add("true")
                next()
            },
            { _ctx: Context, next: NextFunction =>
                events.add("false")
                next()
            },
        )
        composer.lazy({ ctx: Context =>
            { _ctx: Context, next: NextFunction =>
                events.add("lazy:" + ctx.update.kind)
                next()
            }
        })
        let routes = HashMap<String, MiddlewareFn>()
        routes["route"] = { _ctx: Context, next: NextFunction =>
            events.add("route")
            next()
        }
        composer.route(
            { ctx: Context => if (ctx.update.kind == "message:text") { "route" } else { "" } },
            routes,
            { _ctx: Context, next: NextFunction =>
                events.add("fallback")
                next()
            },
        )
        composer.errorBoundary(
            { err: BotError, next: NextFunction =>
                events.add("caught:" + err.ctx.updateId().toString())
                next()
            },
            { _ctx: Context, _next: NextFunction =>
                events.add("unsafe")
                throw Exception("boom")
            },
        )
        composer.use({ _ctx: Context, _next: NextFunction =>
            events.add("after")
        })

        run(composer, testCtx(1, "message:text"))

        @Expect(events.size, 6)
        @Expect(events[0], "true")
        @Expect(events[1], "lazy:message:text")
        @Expect(events[2], "route")
        @Expect(events[3], "unsafe")
        @Expect(events[4], "caught:1")
        @Expect(events[5], "after")
    }
}
