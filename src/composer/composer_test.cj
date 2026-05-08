package grammy4cj.composer

import grammy4cj.context.{Context, ContextMatch, orThrow}
import grammy4cj.core.Api
import grammy4cj.types.{CallbackQuery, Chat, ChosenInlineResult, InlineQuery, Message, MessageEntity, MessageReactionUpdated, PreCheckoutQuery, ReactionType, ShippingQuery, Update, User, UserFromGetMe}
import std.collection.{ArrayList, HashMap}
import std.regex.Regex
import std.sync.Mutex
import std.unittest.*

private let eventMutex = Mutex()

private class AsyncSignal {
    private let mutex = Mutex()
    private var released: Bool = false

    public init() {}

    public func release(): Unit {
        synchronized(this.mutex) {
            this.released = true
        }
    }

    public func isReleased(): Bool {
        var value = false
        synchronized(this.mutex) {
            value = this.released
        }
        value
    }

    public func wait(): Unit {
        while (!this.isReleased()) {
            ()
        }
    }
}

private func testCtx(updateId: Int64, kind: String): Context {
    let chat = Chat(updateId, "private")
    let user = User(42, false, "Test", "test")
    if (kind == "message:text") {
        let update = Update(updateId, kind)
        update.message = Message(updateId, chat, "text", user)
        return Context(update, Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
    }
    if (kind == "message") {
        let update = Update(updateId, kind)
        let message = Message()
        message.messageId = updateId
        message.chat = chat
        message.user = user
        message.isPresent = true
        update.message = message
        return Context(update, Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
    }
    if (kind == "channel_post:text") {
        let update = Update(updateId, kind)
        update.channelPost = Message(updateId, chat, "text", user)
        return Context(update, Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
    }
    if (kind == "channel_post") {
        let update = Update(updateId, kind)
        let message = Message()
        message.messageId = updateId
        message.chat = chat
        message.isPresent = true
        update.channelPost = message
        return Context(update, Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
    }
    Context(Update(updateId, kind), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
}

private func matchText(value: Option<ContextMatch>): String {
    orThrow(value, "composer-test").text
}

private func recordingMiddleware(events: ArrayList<String>, name: String): MiddlewareFn {
    { _ctx: Context, next: NextFunction =>
        addEvent(events, name + ":pre")
        next()
        addEvent(events, name + ":post")
    }
}

private func eventMiddleware(events: ArrayList<String>, name: String): MiddlewareFn {
    { _ctx: Context, next: NextFunction =>
        addEvent(events, name)
        next()
    }
}

private func addEvent(events: ArrayList<String>, value: String): Unit {
    synchronized(eventMutex) {
        events.add(value)
    }
}

private func containsControl(values: Array<String>, value: String): Bool {
    for (item in values) {
        if (item == value) {
            return true
        }
    }
    false
}

private func countEvents(events: ArrayList<String>, value: String): Int64 {
    var count: Int64 = 0
    for (event in events) {
        if (event == value) {
            count += 1
        }
    }
    count
}

private func spinWork(iterations: Int64): Unit {
    var i: Int64 = 0
    while (i < iterations) {
        i += 1
    }
}

private func botInfo(): UserFromGetMe {
    UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")
}

private func api(): Api {
    Api("fake-token")
}

private func user(): User {
    User(301, false, "Ada", "ada")
}

private func privateChat(): Chat {
    Chat(201, "private")
}

private func messageCtx(updateId: Int64, text: String): Context {
    Context(Update.withMessage(updateId, Message(70, privateChat(), text, user())), api(), botInfo())
}

private func commandCtx(updateId: Int64, text: String, length: Int64): Context {
    let message = Message(71, privateChat(), text, user())
    message.addEntity(MessageEntity("bot_command", 0, length))
    Context(Update.withMessage(updateId, message), api(), botInfo())
}

private func chatTypeCtx(updateId: Int64, kind: String): Context {
    Context(Update.withMessage(updateId, Message(72, Chat(202, kind), "chat", user())), api(), botInfo())
}

private func callbackCtx(updateId: Int64, data: String): Context {
    Context(Update.withCallbackQuery(updateId, CallbackQuery(user(), data, Message(73, privateChat(), "callback", user()))), api(), botInfo())
}

private func gameCtx(updateId: Int64, game: String): Context {
    Context(Update.withCallbackQuery(updateId, CallbackQuery(user(), "", game, Message(74, privateChat(), "game", user()), "")), api(), botInfo())
}

private func inlineCtx(updateId: Int64, query: String): Context {
    Context(Update.withInlineQuery(updateId, InlineQuery(user(), query)), api(), botInfo())
}

private func preCheckoutCtx(updateId: Int64, payload: String): Context {
    Context(Update.withPreCheckoutQuery(updateId, PreCheckoutQuery(user(), payload)), api(), botInfo())
}

private func shippingCtx(updateId: Int64, payload: String): Context {
    Context(Update.withShippingQuery(updateId, ShippingQuery(user(), payload)), api(), botInfo())
}

@Test
public class ComposerMiddlewareTest {
    @TestCase
    public func controlMethodManifestListsTwentyComposerEntrypoints(): Unit {
        let methods = composerControlMethodNames()

        @Expect(methods.size, 20)
        @Expect(composerControlMethodCount(), 20)
        @Expect(containsControl(methods, "middleware"), true)
        @Expect(containsControl(methods, "hears"), true)
        @Expect(containsControl(methods, "gameQuery"), true)
        @Expect(containsControl(methods, "fork"), true)
        @Expect(containsControl(methods, "errorBoundary"), true)
    }

    @TestCase
    public func maybeTaskFacadeComposesSyncImmediateAndFutureMiddleware(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let immediate: MaybeMiddlewareFn = { _ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                addEvent(events, "maybe:pre")
                next().get()
                addEvent(events, "maybe:post")
            })
        }
        let futureBacked: MaybeMiddlewareFn = { _ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>(spawn { =>
                addEvent(events, "future:pre")
                next().get()
                addEvent(events, "future:post")
            })
        }
        composer.use(immediate)
        composer.use(futureBacked)
        composer.use(eventMiddleware(events, "leaf"))

        run(composer, testCtx(99, "message"))

        @Expect(events.size, 5)
        @Expect(events[0], "maybe:pre")
        @Expect(events[1], "future:pre")
        @Expect(events[2], "leaf")
        @Expect(events[3], "future:post")
        @Expect(events[4], "maybe:post")
    }

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
        let events = ArrayList<String>()
        composer.use({ _ctx: Context, next: NextFunction =>
            next()
            next()
        })
        composer.use(eventMiddleware(events, "child"))

        var thrown = false
        try {
            run(composer, testCtx(1, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message.contains("next"), true)
        }

        @Expect(thrown, true)
        @Expect(events.size, 1)
    }

    @TestCase
    public func concatDoesNotRunDownstreamWhenNextIsNotCalled(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.use({ _ctx: Context, _next: NextFunction =>
            addEvent(events, "stop")
        })
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(100, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "stop")
    }

    @TestCase
    public func asyncMiddlewareAwaitsNextBeforeContinuing(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let outer: AsyncMiddlewareFn = { _ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                addEvent(events, "outer:pre")
                next().get()
                addEvent(events, "outer:post")
            }
        }
        let inner: AsyncMiddlewareFn = { _ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                addEvent(events, "inner")
                next().get()
            }
        }
        composer.use(outer)
        composer.use(inner)

        run(composer, testCtx(80, "message"))

        @Expect(events.size, 3)
        @Expect(events[0], "outer:pre")
        @Expect(events[1], "inner")
        @Expect(events[2], "outer:post")
    }

    @TestCase
    public func runPropagatesRejectedMiddlewareFuture(): Unit {
        let failing: AsyncMiddlewareFn = { _ctx: Context, _next: AsyncNextFunction =>
            spawn { => throw Exception("async boom") }
        }

        var thrown = false
        try {
            run(failing, testCtx(81, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "async boom")
        }

        @Expect(thrown, true)
    }

    @TestCase
    public func asyncFilterAndDropPredicatesControlFlow(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let even: Predicate = { ctx: Context =>
            spawn { => ctx.updateId() % 2 == 0 }
        }
        composer.filter(even, eventMiddleware(events, "even"))
        composer.drop(even, eventMiddleware(events, "odd"))

        run(composer, testCtx(82, "message"))
        run(composer, testCtx(83, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "even")
        @Expect(events[1], "odd")
    }

    @TestCase
    public func asyncPredicateErrorsStopDownstreamAndPropagate(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let failing: Predicate = { _ctx: Context =>
            spawn { =>
                throw Exception("predicate boom")
                false
            }
        }
        composer.filter(failing, eventMiddleware(events, "filtered"))
        composer.use(eventMiddleware(events, "after"))

        var thrown = false
        try {
            run(composer, testCtx(84, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "predicate boom")
        }

        @Expect(thrown, true)
        @Expect(events.size, 0)
    }

    @TestCase
    public func asyncBranchSelectsTrueAndFalseMiddleware(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let even: Predicate = { ctx: Context =>
            spawn { => ctx.updateId() % 2 == 0 }
        }
        composer.branch(
            even,
            eventMiddleware(events, "true"),
            eventMiddleware(events, "false"),
        )

        run(composer, testCtx(86, "message"))
        run(composer, testCtx(87, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "true")
        @Expect(events[1], "false")
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
    public func onUsesSharedFilterShortcutParserForEntityQueries(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.on("::url", eventMiddleware(events, "url"))

        let chat = Chat(123, "private")
        let user = User(456, false, "Ada", "ada")
        let message = Message(47, chat, "visit https://example.test", user)
        message.addEntity(MessageEntity("url", 6, 20))
        let ctx = Context(Update.withMessage(85, message), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))

        run(composer, ctx)

        @Expect(events.size, 1)
        @Expect(events[0], "url")
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
            { ctx: Context => if (ctx.update.kind == "message:text") { Some("route") } else { None<String> } },
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

    @TestCase
    public func triggerControlMethodsRouteMatchingContexts(): Unit {
        let chat = Chat(201, "private")
        let groupChat = Chat(202, "group")
        let user = User(301, false, "Ada", "ada")
        let callbackMessage = Message(70, chat, "callback-message", user)
        let events = ArrayList<String>()
        let composer = Composer()

        composer.hears(["hello", "hi"], eventMiddleware(events, "hears"))
        composer.command(["start", "help"], eventMiddleware(events, "command"))
        composer.reaction(["heart", "plus"], eventMiddleware(events, "reaction"))
        composer.chatType(["group", "supergroup"], eventMiddleware(events, "chatType"))
        composer.callbackQuery(["cb", "other"], eventMiddleware(events, "callbackQuery"))
        composer.gameQuery(["game", "other"], eventMiddleware(events, "gameQuery"))
        composer.inlineQuery(["inline", "other"], eventMiddleware(events, "inlineQuery"))
        composer.chosenInlineResult(["chosen", "other"], eventMiddleware(events, "chosenInlineResult"))
        composer.preCheckoutQuery(["pre", "other"], eventMiddleware(events, "preCheckoutQuery"))
        composer.shippingQuery(["ship", "other"], eventMiddleware(events, "shippingQuery"))

        run(composer, testCtx(20, "empty"))

        let hearsMessage = Message(71, chat, "hello", user)
        run(composer, Context(Update.withMessage(21, hearsMessage), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))

        let commandMessage = Message(72, chat, "/start payload", user)
        commandMessage.addEntity(MessageEntity("bot_command", 0, 6))
        let commandCtx = Context(Update.withMessage(22, commandMessage), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
        run(composer, commandCtx)

        run(composer, Context(Update.withMessageReaction(23, MessageReactionUpdated(chat, user, 73, [], [ReactionType.emojiReaction("heart")])), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))
        run(composer, Context(Update.withMessage(24, Message(74, groupChat, "group text", user)), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))
        run(composer, Context(Update.withCallbackQuery(25, CallbackQuery(user, "cb", callbackMessage)), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))
        run(composer, Context(Update.withCallbackQuery(26, CallbackQuery(user, "", "game", callbackMessage, "")), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))
        run(composer, Context(Update.withInlineQuery(27, InlineQuery(user, "inline")), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))
        run(composer, Context(Update.withChosenInlineResult(28, ChosenInlineResult(user, "chosen", "inline-id")), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))
        run(composer, Context(Update.withPreCheckoutQuery(29, PreCheckoutQuery(user, "pre")), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))
        run(composer, Context(Update.withShippingQuery(30, ShippingQuery(user, "ship")), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")))

        @Expect(events.size, 10)
        @Expect(events[0], "hears")
        @Expect(events[1], "command")
        @Expect(matchText(commandCtx.`match`), "payload")
        @Expect(events[2], "reaction")
        @Expect(events[3], "chatType")
        @Expect(events[4], "callbackQuery")
        @Expect(events[5], "gameQuery")
        @Expect(events[6], "inlineQuery")
        @Expect(events[7], "chosenInlineResult")
        @Expect(events[8], "preCheckoutQuery")
        @Expect(events[9], "shippingQuery")
    }

    @TestCase
    public func regexpTriggerControlMethodsMirrorUpstreamComposerChaining(): Unit {
        let chat = Chat(203, "private")
        let user = User(302, false, "Barbara", "barbara")
        let callbackMessage = Message(80, chat, "callback-message", user)
        let events = ArrayList<String>()
        let composer = Composer()

        composer.hears(Regex("^x")).hears(Regex("x$"), eventMiddleware(events, "miss"))
        composer.hears(Regex("^he")).hears([Regex("llo$")], eventMiddleware(events, "hears"))
        composer.callbackQuery([Regex("^missing"), Regex("^cb")]).callbackQuery(Regex("^cb"), eventMiddleware(events, "callbackQuery"))
        composer.gameQuery([Regex("^missing"), Regex("^ga")]).gameQuery([Regex("^ga")], eventMiddleware(events, "gameQuery"))
        composer.inlineQuery([Regex("^missing"), Regex("^in")]).inlineQuery(Regex("^in"), eventMiddleware(events, "inlineQuery"))
        composer.chosenInlineResult([Regex("^missing"), Regex("^cho")]).chosenInlineResult([Regex("^cho")], eventMiddleware(events, "chosenInlineResult"))
        composer.preCheckoutQuery([Regex("^missing"), Regex("^pre")]).preCheckoutQuery(Regex("^pre"), eventMiddleware(events, "preCheckoutQuery"))
        composer.shippingQuery([Regex("^missing"), Regex("^ship")]).shippingQuery([Regex("^ship")], eventMiddleware(events, "shippingQuery"))

        let hearsCtx = Context(Update.withMessage(90, Message(81, chat, "hello", user)), Api("fake-token"), botInfo())
        run(composer, hearsCtx)
        @Expect(matchText(hearsCtx.`match`), "llo")

        let callbackCtx = Context(Update.withCallbackQuery(91, CallbackQuery(user, "cb-data", callbackMessage)), Api("fake-token"), botInfo())
        run(composer, callbackCtx)
        @Expect(matchText(callbackCtx.`match`), "cb")

        let gameCtx = Context(Update.withCallbackQuery(92, CallbackQuery(user, "", "game-data", callbackMessage, "")), Api("fake-token"), botInfo())
        run(composer, gameCtx)
        @Expect(matchText(gameCtx.`match`), "ga")

        let inlineCtx = Context(Update.withInlineQuery(93, InlineQuery(user, "inline-data")), Api("fake-token"), botInfo())
        run(composer, inlineCtx)
        @Expect(matchText(inlineCtx.`match`), "in")

        let chosenCtx = Context(Update.withChosenInlineResult(94, ChosenInlineResult(user, "chosen-data", "inline-id")), Api("fake-token"), botInfo())
        run(composer, chosenCtx)
        @Expect(matchText(chosenCtx.`match`), "cho")

        let preCheckoutCtx = Context(Update.withPreCheckoutQuery(95, PreCheckoutQuery(user, "pre-data")), Api("fake-token"), botInfo())
        run(composer, preCheckoutCtx)
        @Expect(matchText(preCheckoutCtx.`match`), "pre")

        let shippingCtx = Context(Update.withShippingQuery(96, ShippingQuery(user, "ship-data")), Api("fake-token"), botInfo())
        run(composer, shippingCtx)
        @Expect(matchText(shippingCtx.`match`), "ship")

        @Expect(events.size, 7)
        @Expect(events[0], "hears")
        @Expect(events[1], "callbackQuery")
        @Expect(events[2], "gameQuery")
        @Expect(events[3], "inlineQuery")
        @Expect(events[4], "chosenInlineResult")
        @Expect(events[5], "preCheckoutQuery")
        @Expect(events[6], "shippingQuery")
    }

    @TestCase
    public func botErrorWrapsExceptionMessageAndContext(): Unit {
        let ctx = testCtx(40, "message")
        let source = Exception("nope")
        let err = BotError(source, ctx)

        @Expect(err.message.contains("nope"), true)
        @Expect(err.ctx.updateId(), 40)
        @Expect(err.error.message, "nope")
    }

    @TestCase
    public func useCallsHandlers(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.use(eventMiddleware(events, "handler"))

        run(composer, testCtx(41, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "handler")
    }

    @TestCase
    public func constructorCallsHandlers(): Unit {
        let events = ArrayList<String>()
        let composer = Composer(eventMiddleware(events, "constructor"))

        run(composer, testCtx(42, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "constructor")
    }

    @TestCase
    public func useRunsMultipleHandlersInOneCall(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.use([eventMiddleware(events, "a"), eventMiddleware(events, "b"), eventMiddleware(events, "c")])

        run(composer, testCtx(43, "message"))

        @Expect(events.size, 3)
        @Expect(events[0], "a")
        @Expect(events[1], "b")
        @Expect(events[2], "c")
    }

    @TestCase
    public func useRunsMultipleHandlersAcrossCalls(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.use([eventMiddleware(events, "a"), eventMiddleware(events, "b")])
        composer.use([eventMiddleware(events, "c"), eventMiddleware(events, "d")])

        run(composer, testCtx(44, "message"))

        @Expect(events.size, 4)
        @Expect(events[0], "a")
        @Expect(events[1], "b")
        @Expect(events[2], "c")
        @Expect(events[3], "d")
    }

    @TestCase
    public func useReturnedComposerSubTrees(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let sub = composer.use(eventMiddleware(events, "root"))
        sub.use(eventMiddleware(events, "child"))

        run(composer, testCtx(45, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "root")
        @Expect(events[1], "child")
    }

    @TestCase
    public func useAcceptsComposerMiddlewareObjects(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let external = Composer(eventMiddleware(events, "external-root"))
        composer.use(external)
        external.use(eventMiddleware(events, "external-child"))

        run(composer, testCtx(30, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "external-root")
        @Expect(events[1], "external-child")
    }

    @TestCase
    public func useLetsErrorsBubble(): Unit {
        let composer = Composer()
        let evil: MiddlewareFn = { _ctx: Context, _next: NextFunction => throw Exception("evil") }
        composer.use({ _ctx: Context, next: NextFunction => next() })
            .use(evil)

        var thrown = false
        try {
            run(composer, testCtx(46, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "evil")
        }
        @Expect(thrown, true)
    }

    @TestCase
    public func onRunsFilterQueries(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.on("::bot_command", eventMiddleware(events, "command"))
        composer.on(["::code", "message:text"], eventMiddleware(events, "text"))

        run(composer, messageCtx(47, "test"))
        run(composer, testCtx(48, "channel_post"))

        @Expect(events.size, 1)
        @Expect(events[0], "text")
    }

    @TestCase
    public func onChainsFilterQueries(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.on([":text"]).on("message", eventMiddleware(events, "message-text"))

        run(composer, messageCtx(49, "test"))
        run(composer, testCtx(50, "channel_post:text"))

        @Expect(events.size, 1)
        @Expect(events[0], "message-text")
    }

    @TestCase
    public func hearsChecksText(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.hears("test", eventMiddleware(events, "hears"))

        run(composer, messageCtx(51, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hears")
    }

    @TestCase
    public func hearsChainsExactTriggers(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.hears(["nope"]).hears(["test"], eventMiddleware(events, "miss"))
        composer.hears(["test"]).hears(["nope"], eventMiddleware(events, "miss"))
        composer.hears(["test"]).hears(["test"], eventMiddleware(events, "hit"))

        run(composer, messageCtx(52, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func commandChecksCommandsAndStoresPayload(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let ctx = commandCtx(53, "/start payload", 6)
        composer.command("start", eventMiddleware(events, "command"))

        run(composer, ctx)

        @Expect(events.size, 1)
        @Expect(matchText(ctx.`match`), "payload")
    }

    @TestCase
    public func commandChainsCommands(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.command(["help"]).command(["start", "settings"], eventMiddleware(events, "miss"))
        composer.command(["help", "start"]).command(["settings"], eventMiddleware(events, "miss"))
        composer.command(["help", "start"]).command(["start", "settings"], eventMiddleware(events, "hit"))

        run(composer, commandCtx(54, "/start", 6))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func chatTypeChecksOneOfSeveralTypes(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.chatType("private", eventMiddleware(events, "private"))
        composer.chatType(["group", "supergroup"], eventMiddleware(events, "group"))

        run(composer, chatTypeCtx(55, "group"))

        @Expect(events.size, 1)
        @Expect(events[0], "group")
    }

    @TestCase
    public func chatTypeChainsChecks(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.chatType(["channel"]).chatType(["group", "supergroup"], eventMiddleware(events, "miss"))
        composer.chatType(["channel", "group"]).chatType(["supergroup"], eventMiddleware(events, "miss"))
        composer.chatType(["channel", "group"]).chatType(["group", "supergroup"], eventMiddleware(events, "hit"))

        run(composer, chatTypeCtx(56, "group"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func callbackQueryChecksData(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.callbackQuery("no-data", eventMiddleware(events, "miss"))
        composer.callbackQuery(["nope", "test"], eventMiddleware(events, "hit"))

        run(composer, callbackCtx(57, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func callbackQueryChainsDataChecks(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.callbackQuery(["nope"]).callbackQuery(["test"], eventMiddleware(events, "miss"))
        composer.callbackQuery(["nope", "test"]).callbackQuery(["nope"], eventMiddleware(events, "miss"))
        composer.callbackQuery(["nope", "test"]).callbackQuery(["test"], eventMiddleware(events, "hit"))

        run(composer, callbackCtx(58, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func gameQueryChecksData(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.gameQuery("no-data", eventMiddleware(events, "miss"))
        composer.gameQuery(["nope", "test"], eventMiddleware(events, "hit"))

        run(composer, gameCtx(59, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func gameQueryChainsDataChecks(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.gameQuery(["nope"]).gameQuery(["test"], eventMiddleware(events, "miss"))
        composer.gameQuery(["nope", "test"]).gameQuery(["nope"], eventMiddleware(events, "miss"))
        composer.gameQuery(["nope", "test"]).gameQuery(["test"], eventMiddleware(events, "hit"))

        run(composer, gameCtx(60, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func inlineQueryChecksData(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.inlineQuery("no-data", eventMiddleware(events, "miss"))
        composer.inlineQuery(["nope", "test"], eventMiddleware(events, "hit"))

        run(composer, inlineCtx(61, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func inlineQueryChainsDataChecks(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.inlineQuery(["nope"]).inlineQuery(["test"], eventMiddleware(events, "miss"))
        composer.inlineQuery(["nope", "test"]).inlineQuery(["nope"], eventMiddleware(events, "miss"))
        composer.inlineQuery(["nope", "test"]).inlineQuery(["test"], eventMiddleware(events, "hit"))

        run(composer, inlineCtx(62, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func preCheckoutQueryChecksPayload(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.preCheckoutQuery("no-data", eventMiddleware(events, "miss"))
        composer.preCheckoutQuery(["nope", "test"], eventMiddleware(events, "hit"))

        run(composer, preCheckoutCtx(63, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func preCheckoutQueryChainsPayload(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.preCheckoutQuery(["nope"]).preCheckoutQuery(["test"], eventMiddleware(events, "miss"))
        composer.preCheckoutQuery(["nope", "test"]).preCheckoutQuery(["nope"], eventMiddleware(events, "miss"))
        composer.preCheckoutQuery(["nope", "test"]).preCheckoutQuery(["test"], eventMiddleware(events, "hit"))

        run(composer, preCheckoutCtx(64, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func shippingQueryChecksPayload(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.shippingQuery("no-data", eventMiddleware(events, "miss"))
        composer.shippingQuery(["nope", "test"], eventMiddleware(events, "hit"))

        run(composer, shippingCtx(65, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func shippingQueryChainsPayload(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.shippingQuery(["nope"]).shippingQuery(["test"], eventMiddleware(events, "miss"))
        composer.shippingQuery(["nope", "test"]).shippingQuery(["nope"], eventMiddleware(events, "miss"))
        composer.shippingQuery(["nope", "test"]).shippingQuery(["test"], eventMiddleware(events, "hit"))

        run(composer, shippingCtx(66, "test"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func filterChecksPredicates(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.filter({ _ctx: Context => false }, eventMiddleware(events, "miss"))
        composer.filter({ _ctx: Context => true }, eventMiddleware(events, "hit"))

        run(composer, testCtx(67, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func filterChainsPredicates(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.filter({ _ctx: Context => true }).filter({ _ctx: Context => false }, eventMiddleware(events, "miss"))
        composer.filter({ _ctx: Context => false }).filter({ _ctx: Context => true }, eventMiddleware(events, "miss"))
        composer.filter({ _ctx: Context => true }).filter({ _ctx: Context => true }, eventMiddleware(events, "hit"))

        run(composer, testCtx(68, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func dropChecksNegatedPredicates(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.drop({ _ctx: Context => true }, eventMiddleware(events, "miss"))
        composer.drop({ _ctx: Context => false }, eventMiddleware(events, "hit"))

        run(composer, testCtx(69, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func dropChainsNegatedPredicates(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.drop({ _ctx: Context => true }).drop({ _ctx: Context => false }, eventMiddleware(events, "miss"))
        composer.drop({ _ctx: Context => false }).drop({ _ctx: Context => true }, eventMiddleware(events, "miss"))
        composer.drop({ _ctx: Context => false }).drop({ _ctx: Context => false }, eventMiddleware(events, "hit"))

        run(composer, testCtx(70, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "hit")
    }

    @TestCase
    public func forkRunsDownstreamAndForkedMiddleware(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.fork(eventMiddleware(events, "fork"))
        composer.use(eventMiddleware(events, "downstream"))

        run(composer, testCtx(71, "message"))

        @Expect(events.size, 2)
        @Expect(countEvents(events, "fork"), 1)
        @Expect(countEvents(events, "downstream"), 1)
    }

    @TestCase
    public func forkPropagatesForkErrors(): Unit {
        let composer = Composer()
        let forkBoom: MiddlewareFn = { _ctx: Context, _next: NextFunction => throw Exception("fork boom") }
        composer.fork(forkBoom)

        var thrown = false
        try {
            run(composer, testCtx(72, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "fork boom")
        }
        @Expect(thrown, true)
    }

    @TestCase
    public func forkStartsDownstreamAndForkedMiddlewareConcurrently(): Unit {
        let events = ArrayList<String>()
        let downstreamSeen = AsyncSignal()
        let forkSeen = AsyncSignal()
        let composer = Composer()
        let forked: AsyncMiddlewareFn = { _ctx: Context, _next: AsyncNextFunction =>
            spawn { =>
                addEvent(events, "fork:start")
                forkSeen.release()
                downstreamSeen.wait()
                addEvent(events, "fork:after-downstream")
            }
        }
        let downstream: AsyncMiddlewareFn = { _ctx: Context, _next: AsyncNextFunction =>
            spawn { =>
                addEvent(events, "downstream:start")
                downstreamSeen.release()
                forkSeen.wait()
                addEvent(events, "downstream:after-fork")
            }
        }
        composer.fork(forked)
        composer.use(downstream)

        run(composer, testCtx(88, "message"))

        @Expect(events.size, 4)
        @Expect(countEvents(events, "fork:start"), 1)
        @Expect(countEvents(events, "fork:after-downstream"), 1)
        @Expect(countEvents(events, "downstream:start"), 1)
        @Expect(countEvents(events, "downstream:after-fork"), 1)
    }

    @TestCase
    public func forkRejectsWithFastForkErrorBeforeSlowerDownstreamError(): Unit {
        let forkStarted = AsyncSignal()
        let composer = Composer()
        let forked: AsyncMiddlewareFn = { _ctx: Context, _next: AsyncNextFunction =>
            spawn { =>
                forkStarted.release()
                throw Exception("fork fast")
            }
        }
        let downstream: AsyncMiddlewareFn = { _ctx: Context, _next: AsyncNextFunction =>
            spawn { =>
                forkStarted.wait()
                spinWork(5000000)
                throw Exception("downstream late")
            }
        }
        composer.fork(forked)
        composer.use(downstream)

        var thrown = false
        try {
            run(composer, testCtx(89, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "fork fast")
        }

        @Expect(thrown, true)
    }

    @TestCase
    public func forkPropagatesDownstreamErrorsAndSharesContext(): Unit {
        let seen = ArrayList<String>()
        let forkSeen = AsyncSignal()
        let composer = Composer()
        let forked: MiddlewareFn = { ctx: Context, _next: NextFunction =>
            addEvent(seen, "fork:" + ctx.updateId().toString())
            forkSeen.release()
        }
        let downstream: MiddlewareFn = { ctx: Context, _next: NextFunction =>
            forkSeen.wait()
            addEvent(seen, "downstream:" + ctx.updateId().toString())
            throw Exception("downstream boom")
        }
        composer.fork(forked)
        composer.use(downstream)

        var thrown = false
        try {
            run(composer, testCtx(90, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "downstream boom")
        }

        @Expect(thrown, true)
        @Expect(countEvents(seen, "fork:90"), 1)
        @Expect(countEvents(seen, "downstream:90"), 1)
    }

    @TestCase
    public func lazyRunsCreatedMiddleware(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.lazy({ ctx: Context =>
            { _ctx: Context, next: NextFunction =>
                events.add("lazy:" + ctx.updateId().toString())
                next()
            }
        })

        run(composer, testCtx(73, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "lazy:73")
    }

    @TestCase
    public func lazyFactoryRunsOnceForEachUpdate(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.lazy({ ctx: Context =>
            addEvent(events, "factory")
            { _ctx: Context, next: NextFunction =>
                addEvent(events, "lazy:" + ctx.updateId().toString())
                next()
            }
        })

        run(composer, testCtx(101, "message"))
        run(composer, testCtx(102, "message"))

        @Expect(countEvents(events, "factory"), 2)
        @Expect(events.size, 4)
        @Expect(events[0], "factory")
        @Expect(events[1], "lazy:101")
        @Expect(events[2], "factory")
        @Expect(events[3], "lazy:102")
    }

    @TestCase
    public func maybeLazyFactoryReturnsMiddlewareArrays(): Unit {
        let events = ArrayList<String>()
        let factory: MaybeMiddlewareArrayFactory = { ctx: Context =>
            MaybeTask<Array<MaybeMiddlewareFn>>({ =>
                let first: MaybeMiddlewareFn = { _ctx: Context, next: MaybeNextFunction =>
                    MaybeTask<Unit>({ =>
                        addEvent(events, "maybe-array:" + ctx.updateId().toString())
                        next().get()
                    })
                }
                [first]
            })
        }
        let composer = Composer()
        composer.lazyMaybeArray(factory)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(103, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "maybe-array:103")
        @Expect(events[1], "after")
    }

    @TestCase
    public func lazyRunsCreatedMiddlewareArrays(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.lazy({ _ctx: Context =>
            [eventMiddleware(events, "a"), eventMiddleware(events, "b")]
        })

        run(composer, testCtx(74, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "a")
        @Expect(events[1], "b")
    }

    @TestCase
    public func lazyRunsCreatedComposersAndPropagatesFactoryErrors(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.lazy({ _ctx: Context => Composer(eventMiddleware(events, "composer")) })

        run(composer, testCtx(32, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "composer")

        let throwing = Composer()
        throwing.lazy({ _ctx: Context =>
            throw Exception("lazy factory boom")
            eventMiddleware(events, "never")
        })
        var thrown = false
        try {
            run(throwing, testCtx(33, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "lazy factory boom")
        }
        @Expect(thrown, true)
    }

    @TestCase
    public func lazyAwaitsAsyncMiddlewareFactories(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let factory: AsyncMiddlewareFactory = { ctx: Context =>
            spawn { =>
                addEvent(events, "factory:" + ctx.updateId().toString())
                eventMiddleware(events, "created")
            }
        }
        let asyncFactory: (Context) -> Future<AsyncMiddlewareFn> = { ctx: Context =>
            spawn { =>
                let middleware: AsyncMiddlewareFn = { _ctx: Context, next: AsyncNextFunction =>
                    spawn { =>
                        addEvent(events, "async-created:" + ctx.updateId().toString())
                        next().get()
                    }
                }
                middleware
            }
        }
        composer.lazy(factory)
        composer.lazyAsync(asyncFactory)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(91, "message"))

        @Expect(events.size, 4)
        @Expect(events[0], "factory:91")
        @Expect(events[1], "created")
        @Expect(events[2], "async-created:91")
        @Expect(events[3], "after")
    }

    @TestCase
    public func lazyAwaitsAsyncArraysAndComposers(): Unit {
        let events = ArrayList<String>()
        let emptyArrayFactory: AsyncMiddlewareArrayFactory = { _ctx: Context =>
            spawn { => Array<MiddlewareFn>() }
        }
        let composerFactory: AsyncComposerFactory = { ctx: Context =>
            spawn { =>
                Composer({ _ctx: Context, next: NextFunction =>
                    addEvent(events, "composer:" + ctx.updateId().toString())
                    next()
                })
            }
        }
        let composer = Composer()
        composer.lazy(emptyArrayFactory)
        composer.lazy(composerFactory)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(92, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "composer:92")
        @Expect(events[1], "after")
    }

    @TestCase
    public func routeRoutesContextObjects(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let routes = HashMap<String, MiddlewareFn>()
        routes["key"] = eventMiddleware(events, "route")
        composer.route({ _ctx: Context => Some("key") }, routes)

        run(composer, testCtx(75, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "route")
    }

    @TestCase
    public func routeUsesFallbackForMissingKey(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let routes = HashMap<String, MiddlewareFn>()
        routes["a"] = eventMiddleware(events, "a")
        composer.route({ _ctx: Context => Some("missing") }, routes, eventMiddleware(events, "fallback"))

        run(composer, testCtx(76, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "fallback")
    }

    @TestCase
    public func routeSupportsNoneFallbackAndRouteHits(): Unit {
        let events = ArrayList<String>()
        let routes = HashMap<String, MiddlewareFn>()
        routes["key"] = eventMiddleware(events, "route")
        let missing: SyncRouter = { _ctx: Context => None<String> }
        let hit: SyncRouter = { _ctx: Context => Some("key") }

        Composer().route(missing, routes, eventMiddleware(events, "fallback"))
            .middleware()(testCtx(34, "message"), { => () })
        Composer().route(hit, routes, eventMiddleware(events, "unused"))
            .middleware()(testCtx(35, "message"), { => () })

        @Expect(events.size, 2)
        @Expect(events[0], "fallback")
        @Expect(events[1], "route")
    }

    @TestCase
    public func routeAwaitsAsyncRouterAndFallbacks(): Unit {
        let events = ArrayList<String>()
        let routes = HashMap<String, MiddlewareFn>()
        routes["hit"] = eventMiddleware(events, "route")
        let router: Router = { ctx: Context =>
            spawn { =>
                if (ctx.updateId() == 93) {
                    Some("hit")
                } else if (ctx.updateId() == 94) {
                    Some("missing")
                } else {
                    None<String>
                }
            }
        }
        let composer = Composer()
        composer.route(router, routes, eventMiddleware(events, "fallback"))

        run(composer, testCtx(93, "message"))
        run(composer, testCtx(94, "message"))
        run(composer, testCtx(95, "message"))

        @Expect(events.size, 3)
        @Expect(events[0], "route")
        @Expect(events[1], "fallback")
        @Expect(events[2], "fallback")
    }

    @TestCase
    public func routeAwaitsAsyncHandlersAndAsyncFallback(): Unit {
        let events = ArrayList<String>()
        let routes = HashMap<String, AsyncMiddlewareFn>()
        routes["hit"] = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                addEvent(events, "async-route:" + ctx.updateId().toString())
                next().get()
            }
        }
        let fallback: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                addEvent(events, "async-fallback:" + ctx.updateId().toString())
                next().get()
            }
        }
        let router: Router = { ctx: Context =>
            spawn { =>
                if (ctx.updateId() == 106) {
                    Some("hit")
                } else {
                    Some("missing")
                }
            }
        }
        let composer = Composer()
        composer.route(router, routes, fallback)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(106, "message"))
        run(composer, testCtx(107, "message"))

        @Expect(events.size, 4)
        @Expect(events[0], "async-route:106")
        @Expect(events[1], "after")
        @Expect(events[2], "async-fallback:107")
        @Expect(events[3], "after")
    }

    @TestCase
    public func routeRunsMaybeHandlersAndNoneFallbackThroughMaybeTask(): Unit {
        let events = ArrayList<String>()
        let routes = HashMap<String, MaybeMiddlewareFn>()
        routes["hit"] = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                addEvent(events, "maybe-route:" + ctx.updateId().toString())
                next().get()
            })
        }
        let fallback: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>(spawn { =>
                addEvent(events, "maybe-fallback:" + ctx.updateId().toString())
                next().get()
            })
        }
        let router: MaybeRouter = { ctx: Context =>
            MaybeTask<Option<String>>({ =>
                if (ctx.updateId() == 108) {
                    Some("hit")
                } else {
                    None<String>
                }
            })
        }
        let composer = Composer()
        composer.route(router, routes, fallback)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(108, "message"))
        run(composer, testCtx(109, "message"))

        @Expect(events.size, 4)
        @Expect(events[0], "maybe-route:108")
        @Expect(events[1], "after")
        @Expect(events[2], "maybe-fallback:109")
        @Expect(events[3], "after")
    }

    @TestCase
    public func routePropagatesRouterErrorsBeforeFallbackOrDownstream(): Unit {
        let events = ArrayList<String>()
        let routes = HashMap<String, MiddlewareFn>()
        routes["hit"] = eventMiddleware(events, "route")
        let router: Router = { _ctx: Context =>
            spawn { =>
                throw Exception("router boom")
                None<String>
            }
        }
        let composer = Composer()
        composer.route(router, routes, eventMiddleware(events, "fallback"))
        composer.use(eventMiddleware(events, "after"))

        var thrown = false
        try {
            run(composer, testCtx(104, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "router boom")
        }

        @Expect(thrown, true)
        @Expect(events.size, 0)
    }

    @TestCase
    public func errorBoundaryRethrowsHandlerErrors(): Unit {
        let composer = Composer()
        let handler: ErrorHandler = { _err: BotError, _next: NextFunction => throw Exception("handler boom") }
        let inner: MiddlewareFn = { _ctx: Context, _next: NextFunction => throw Exception("inner boom") }
        composer.errorBoundary(handler, inner)

        var thrown = false
        try {
            run(composer, testCtx(77, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "handler boom")
        }
        @Expect(thrown, true)
    }

    @TestCase
    public func errorBoundaryMaybeHandlerReceivesBotErrorAndCanContinue(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let handler: MaybeErrorHandler = { err: BotError, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                addEvent(events, "caught:" + err.error.message + ":" + err.ctx.updateId().toString())
                next().get()
            })
        }
        let child: MaybeMiddlewareFn = { _ctx: Context, _next: MaybeNextFunction =>
            MaybeTask<Unit>({ => throw Exception("maybe child boom") })
        }
        composer.errorBoundary(handler, child)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(105, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "caught:maybe child boom:105")
        @Expect(events[1], "after")
    }

    @TestCase
    public func errorBoundaryCatchesChildMiddlewareAndCanContinue(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let child: MiddlewareFn = { _ctx: Context, _next: NextFunction => throw Exception("child boom") }
        composer.errorBoundary(
            { err: BotError, next: NextFunction =>
                events.add("caught:" + err.error.message)
                next()
            },
        ).use(child)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(36, "message"))

        @Expect(events.size, 2)
        @Expect(events[0], "caught:child boom")
        @Expect(events[1], "after")
    }

    @TestCase
    public func errorBoundaryDoesNotCatchDownstreamErrors(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        composer.errorBoundary(
            { _err: BotError, _next: NextFunction => events.add("caught") },
        )
        let downstream: MiddlewareFn = { _ctx: Context, _next: NextFunction => throw Exception("downstream boom") }
        composer.use(downstream)

        var thrown = false
        try {
            run(composer, testCtx(37, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "downstream boom")
        }
        @Expect(thrown, true)
        @Expect(events.size, 0)
    }

    @TestCase
    public func errorBoundaryAwaitsAsyncBoundMiddlewareBeforeContinuing(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let handler: AsyncErrorHandler = { _err: BotError, _next: AsyncNextFunction =>
            spawn { => addEvent(events, "unused") }
        }
        let child: AsyncMiddlewareFn = { _ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                addEvent(events, "child:pre")
                next().get()
                addEvent(events, "child:post")
            }
        }
        composer.errorBoundary(handler, child)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(96, "message"))

        @Expect(events.size, 3)
        @Expect(events[0], "child:pre")
        @Expect(events[1], "child:post")
        @Expect(events[2], "after")
    }

    @TestCase
    public func errorBoundaryAsyncHandlerCatchesAndContinuesAfterNextMarker(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let handler: AsyncErrorHandler = { err: BotError, next: AsyncNextFunction =>
            spawn { =>
                addEvent(events, "caught:" + err.error.message)
                next().get()
                addEvent(events, "handler:post")
            }
        }
        let child: AsyncMiddlewareFn = { _ctx: Context, _next: AsyncNextFunction =>
            spawn { => throw Exception("async child boom") }
        }
        composer.errorBoundary(handler, child)
        composer.use(eventMiddleware(events, "after"))

        run(composer, testCtx(97, "message"))

        @Expect(events.size, 3)
        @Expect(events[0], "caught:async child boom")
        @Expect(events[1], "handler:post")
        @Expect(events[2], "after")
    }

    @TestCase
    public func errorBoundaryPropagatesAsyncHandlerErrors(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let handler: AsyncErrorHandler = { _err: BotError, _next: AsyncNextFunction =>
            spawn { => throw Exception("async handler boom") }
        }
        let child: AsyncMiddlewareFn = { _ctx: Context, _next: AsyncNextFunction =>
            spawn { => throw Exception("async child boom") }
        }
        composer.errorBoundary(handler, child)
        composer.use(eventMiddleware(events, "after"))

        var thrown = false
        try {
            run(composer, testCtx(98, "message"))
        } catch (err: Exception) {
            thrown = true
            @Expect(err.message, "async handler boom")
        }

        @Expect(thrown, true)
        @Expect(events.size, 0)
    }

    @TestCase
    public func forkRunsReturnedSubtreeAndDownstreamMiddleware(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let forked = composer.fork(eventMiddleware(events, "fork-root"))
        forked.use(eventMiddleware(events, "fork-child"))
        composer.use(eventMiddleware(events, "downstream"))

        run(composer, testCtx(31, "message"))

        @Expect(events.size, 3)
        @Expect(countEvents(events, "downstream"), 1)
        @Expect(countEvents(events, "fork-root"), 1)
        @Expect(countEvents(events, "fork-child"), 1)
    }
}
