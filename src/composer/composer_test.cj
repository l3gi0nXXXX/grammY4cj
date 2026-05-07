package grammy4cj.composer

import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.types.{CallbackQuery, Chat, ChosenInlineResult, InlineQuery, Message, MessageEntity, MessageReactionUpdated, PreCheckoutQuery, ReactionType, ShippingQuery, Update, User, UserFromGetMe}
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

private func eventMiddleware(events: ArrayList<String>, name: String): MiddlewareFn {
    { _ctx: Context, next: NextFunction =>
        events.add(name)
        next()
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
    public func forkRunsReturnedSubtreeAndDownstreamMiddleware(): Unit {
        let events = ArrayList<String>()
        let composer = Composer()
        let forked = composer.fork(eventMiddleware(events, "fork-root"))
        forked.use(eventMiddleware(events, "fork-child"))
        composer.use(eventMiddleware(events, "downstream"))

        run(composer, testCtx(31, "message"))

        @Expect(events.size, 3)
        @Expect(events[0], "downstream")
        @Expect(events[1], "fork-root")
        @Expect(events[2], "fork-child")
    }
}
