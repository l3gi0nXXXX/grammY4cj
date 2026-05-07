package grammy4cj.composer

import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.types.{CallbackQuery, Chat, ChosenInlineResult, InlineQuery, Message, MessageEntity, MessageReactionUpdated, PreCheckoutQuery, ReactionType, ShippingQuery, Update, User, UserFromGetMe}
import std.collection.{ArrayList, HashMap}
import std.sync.Mutex
import std.unittest.*

private let eventMutex = Mutex()

private func testCtx(updateId: Int64, kind: String): Context {
    Context(Update(updateId, kind), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
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
        @Expect(commandCtx.`match`, "payload")
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
    public func useLetsErrorsBubble(): Unit {
        let composer = Composer()
        composer.use({ _ctx: Context, next: NextFunction => next() })
            .use({ _ctx: Context, _next: NextFunction => throw Exception("evil") })

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
        @Expect(ctx.`match`, "payload")
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
        composer.fork({ _ctx: Context, _next: NextFunction => throw Exception("fork boom") })

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
    public func routeRoutesContextObjects(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let routes = HashMap<String, MiddlewareFn>()
        routes["key"] = eventMiddleware(events, "route")
        composer.route({ _ctx: Context => "key" }, routes)

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
        composer.route({ _ctx: Context => "missing" }, routes, eventMiddleware(events, "fallback"))

        run(composer, testCtx(76, "message"))

        @Expect(events.size, 1)
        @Expect(events[0], "fallback")
    }

    @TestCase
    public func errorBoundaryRethrowsHandlerErrors(): Unit {
        let composer = Composer()
        composer.errorBoundary(
            { _err: BotError, _next: NextFunction => throw Exception("handler boom") },
            { _ctx: Context, _next: NextFunction => throw Exception("inner boom") },
        )

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
