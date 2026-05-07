package grammy4cj.bot

import std.collection.ArrayList
import std.unittest.*

import grammy4cj.composer.BotError
import grammy4cj.composer.NextFunction
import grammy4cj.context.Context
import grammy4cj.core.GrammyError
import grammy4cj.core.HttpError
import grammy4cj.types.ResponseParameters
import grammy4cj.types.Update
import grammy4cj.types.UserFromGetMe

private class StartProbe {
    public var called: Bool = false
    public var runningWhenCalled: Bool = false
    public var username: String = ""

    public init() {}

    public func record(info: UserFromGetMe, running: Bool): Unit {
        this.called = true
        this.runningWhenCalled = running
        this.username = info.username
    }
}

private class StoppingHandler <: BotUpdateHandler {
    private let bot: Bot

    public init(bot: Bot) {
        this.bot = bot
    }

    override public func handle(ctx: BotUpdateContextBoundary): Unit {
        this.bot.stop()
    }
}

private class RecordingBotErrorHandler <: BotErrorHandler {
    public let errors: ArrayList<BotError> = ArrayList<BotError>()

    public init() {}

    override public func handle(error: BotError): Unit {
        this.errors.add(error)
    }
}

@Test
public class BotTest {
    @TestCase
    public func botOwnsTokenApiFacadeAndConfigBotInfo(): Unit {
        let me = UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot")
        let bot = Bot("fake-token", BotConfig(me))

        @Expect(bot.token, "fake-token")
        @Expect(bot.api.token, "fake-token")
        @Expect(bot.isInited(), true)
        @Expect(bot.botInfo.username, "grammy4cj_bot")
    }

    @TestCase
    public func botInitializationStateIsExplicit(): Unit {
        let bot = Bot("fake-token")
        bot.markInitialized()

        @Expect(bot.isInited(), true)
        @Expect(bot.botInfo.username, "grammy4cj_bot")
    }

    @TestCase
    public func initFetchesGetMeOnceAndRetriesTransientFailures(): Unit {
        let runtime = FakeBotRuntime()
        let clock = FakeBotClock()
        runtime.failGetMeOnce(HttpError("first network failure", 599))
        runtime.failGetMeOnce(HttpError("second network failure", 599))
        runtime.getMeResult = UserFromGetMe(7, true, "Retry", "retry_bot")
        let bot = Bot("fake-token", BotConfig(runtime: runtime, clock: clock))

        bot.`init`()
        bot.`init`()

        @Expect(bot.isInited(), true)
        @Expect(bot.botInfo.username, "retry_bot")
        @Expect(runtime.getMeCalls, 3)
        @Expect(bot.initRetryCount, 2)
        @Expect(clock.sleeps.size, 1)
        @Expect(clock.sleeps[0], 100)
    }

    @TestCase
    public func apiTransformersAreCopiedAcrossHandleUpdateBoundary(): Unit {
        let handler = RecordingBotUpdateHandler()
        let me = UserFromGetMe(99, true, "Boundary", "boundary_bot")
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me), updateHandler: handler))
        bot.useApiTransformer("first")
        bot.useApiTransformer("second")

        bot.handleUpdate(Update(1001, "message"))
        let updateApi = handler.contexts[0].api
        updateApi.use("per-update")

        @Expect(handler.contexts.size, 1)
        @Expect(updateApi.installedTransformers().size, 3)
        @Expect(bot.installedApiTransformers().size, 2)
        @Expect(bot.installedApiTransformers()[0], "first")
        @Expect(bot.installedApiTransformers()[1], "second")
    }

    @TestCase
    public func handleUpdateRunsComposerMiddlewareWithPerUpdateContext(): Unit {
        let events = ArrayList<String>()
        let contexts = ArrayList<Context>()
        let me = UserFromGetMe(101, true, "Context", "context_bot")
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me)))

        bot.use({ ctx: Context, next: NextFunction =>
            events.add("outer:pre")
            contexts.add(ctx)
            next()
            events.add("outer:post")
        })
        bot.on("message", { ctx: Context, _next: NextFunction =>
            events.add("on:" + ctx.botInfoUsername())
        })

        bot.handleUpdate(Update(1101, "message"))

        @Expect(events.size, 3)
        @Expect(events[0], "outer:pre")
        @Expect(events[1], "on:context_bot")
        @Expect(events[2], "outer:post")
        @Expect(contexts.size, 1)
        @Expect(contexts[0].update.updateId, 1101)
        @Expect(contexts[0].api.token, "fake-token")
        @Expect(contexts[0].api.endpointFor("sendMessage"), "https://api.telegram.org/botfake-token/sendMessage")
    }

    @TestCase
    public func botOnObservesExpandedUpdateTypesForAllowedUpdateWarnings(): Unit {
        let runtime = FakeBotRuntime()
        let me = UserFromGetMe(102, true, "Observe", "observe_bot")
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me), runtime: runtime))

        bot.on(":text", { _ctx: Context, _next: NextFunction => () })
        bot.start(PollingOptions(
            allowedUpdates: ["message"],
            allowedUpdatesSpecified: true,
            maxFetchCycles: 1
        ))

        @Expect(bot.observedUpdateTypes().size, 2)
        @Expect(bot.observedUpdateTypes()[0], "message")
        @Expect(bot.observedUpdateTypes()[1], "channel_post")
        @Expect(bot.warningMessages().size, 1)
        @Expect(bot.warningMessages()[0].contains("channel_post"), true)
    }

    @TestCase
    public func handleUpdateRequiresInitialization(): Unit {
        let bot = Bot("fake-token")

        try {
            bot.handleUpdate(Update(10, "message"))
            @Expect("unreachable", "BotConfigError")
        } catch (e: BotConfigError) {
            @Expect(e.message.contains("not initialized"), true)
        }
    }

    @TestCase
    public func handleUpdateWrapsMiddlewareErrorsAsBotError(): Unit {
        let me = UserFromGetMe(103, true, "Error", "error_bot")
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me)))
        bot.use({ _ctx: Context, _next: NextFunction =>
            throw Exception("middleware boom")
        })

        var thrown = false
        try {
            bot.handleUpdate(Update(1201, "message"))
        } catch (e: BotError) {
            thrown = true
            @Expect(e.ctx.update.updateId, 1201)
            @Expect(e.error.message, "middleware boom")
        }

        @Expect(thrown, true)
    }

    @TestCase
    public func startInitializesDeletesWebhookWarnsAndFetchesUpdates(): Unit {
        let runtime = FakeBotRuntime()
        let handler = RecordingBotUpdateHandler()
        let probe = StartProbe()
        runtime.getMeResult = UserFromGetMe(5, true, "Start", "start_bot")
        runtime.enqueueUpdates([Update(20, "message")])
        let bot = Bot("fake-token", BotConfig(runtime: runtime, updateHandler: handler))
        bot.observeUpdateType("message")
        bot.observeUpdateType("chat_member")

        bot.start(PollingOptions(
            allowedUpdates: ["message"],
            allowedUpdatesSpecified: true,
            dropPendingUpdates: true,
            maxFetchCycles: 1,
            onStart: Some({ info: UserFromGetMe => probe.record(info, bot.isRunning()) })
        ))

        @Expect(runtime.getMeCalls, 1)
        @Expect(runtime.deleteWebhookCalls, 1)
        @Expect(runtime.lastDropPendingUpdates, true)
        @Expect(probe.called, true)
        @Expect(probe.runningWhenCalled, true)
        @Expect(probe.username, "start_bot")
        @Expect(runtime.pollingRequests.size, 1)
        @Expect(runtime.pollingRequests[0].offset, 1)
        @Expect(runtime.pollingRequests[0].includesAllowedUpdates, true)
        @Expect(runtime.pollingRequests[0].allowedUpdates[0], "message")
        @Expect(handler.contexts.size, 1)
        @Expect(bot.lastTriedUpdateId(), 20)
        @Expect(bot.warningMessages().size, 1)
        @Expect(bot.isRunning(), false)
    }

    @TestCase
    public func pollingRetriesRecoverableErrorsWithRetryAfter(): Unit {
        let runtime = FakeBotRuntime()
        let clock = FakeBotClock()
        let handler = RecordingBotUpdateHandler()
        let me = UserFromGetMe(6, true, "Poll", "poll_bot")
        runtime.enqueuePollingError(GrammyError("getUpdates", "{}", 429, "Too Many Requests", ResponseParameters(0, 2)))
        runtime.enqueueUpdates([Update(30, "message")])
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me), runtime: runtime, clock: clock, updateHandler: handler))

        bot.start(PollingOptions(maxFetchCycles: 1))

        @Expect(runtime.getUpdatesCalls, 2)
        @Expect(bot.pollingErrorCount, 1)
        @Expect(clock.sleeps.size, 1)
        @Expect(clock.sleeps[0], 2000)
        @Expect(handler.contexts.size, 1)
        @Expect(bot.lastTriedUpdateId(), 30)
    }

    @TestCase
    public func initRetriesBotApiRetryAfterAndDeleteWebhookTransientFailures(): Unit {
        let runtime = FakeBotRuntime()
        let clock = FakeBotClock()
        runtime.failGetMeOnce(GrammyError("getMe", "{}", 429, "Too Many Requests", ResponseParameters(0, 2)))
        runtime.failDeleteWebhookOnce(HttpError("delete webhook failed", 599))
        runtime.failDeleteWebhookOnce(HttpError("delete webhook failed again", 599))
        runtime.getMeResult = UserFromGetMe(9, true, "RetryAfter", "retry_after_bot")
        let bot = Bot("fake-token", BotConfig(runtime: runtime, clock: clock))

        bot.start(PollingOptions(maxFetchCycles: 1))

        @Expect(runtime.getMeCalls, 2)
        @Expect(runtime.deleteWebhookCalls, 3)
        @Expect(bot.botInfo.username, "retry_after_bot")
        @Expect(clock.sleeps.size, 2)
        @Expect(clock.sleeps[0], 2000)
        @Expect(clock.sleeps[1], 100)
    }

    @TestCase
    public func pollingRethrowsUnauthorizedAndConflictErrors(): Unit {
        let runtime = FakeBotRuntime()
        let me = UserFromGetMe(10, true, "Fatal", "fatal_bot")
        runtime.enqueuePollingError(GrammyError("getUpdates", "{}", 401, "Unauthorized", ResponseParameters()))
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me), runtime: runtime))

        var thrown = false
        try {
            bot.start(PollingOptions(maxFetchCycles: 1))
        } catch (e: GrammyError) {
            thrown = true
            @Expect(e.errorCode, 401)
        }

        @Expect(thrown, true)
        @Expect(runtime.getUpdatesCalls, 1)
        @Expect(bot.isRunning(), false)

        let conflictRuntime = FakeBotRuntime()
        conflictRuntime.enqueuePollingError(GrammyError("getUpdates", "{}", 409, "Conflict", ResponseParameters()))
        let conflictBot = Bot("fake-token", BotConfig(botInfo: Some(me), runtime: conflictRuntime))
        var conflictThrown = false
        try {
            conflictBot.start(PollingOptions(maxFetchCycles: 1))
        } catch (e: GrammyError) {
            conflictThrown = true
            @Expect(e.errorCode, 409)
        }

        @Expect(conflictThrown, true)
        @Expect(conflictRuntime.getUpdatesCalls, 1)
        @Expect(conflictBot.isRunning(), false)
    }

    @TestCase
    public func customPollingErrorHandlerLetsPollingContinueAfterMiddlewareErrors(): Unit {
        let runtime = FakeBotRuntime()
        let errors = RecordingBotErrorHandler()
        let handled = ArrayList<Int64>()
        let me = UserFromGetMe(11, true, "Catch", "catch_bot")
        runtime.enqueueUpdates([Update(40, "message")])
        runtime.enqueueUpdates([Update(41, "message")])
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me), runtime: runtime))
        bot.`catch`(errors)
        bot.use({ ctx: Context, next: NextFunction =>
            if (ctx.updateId() == 40) {
                throw Exception("poll middleware failed")
            }
            handled.add(ctx.updateId())
            next()
        })

        bot.start(PollingOptions(maxFetchCycles: 2))

        @Expect(errors.errors.size, 1)
        @Expect(errors.errors[0].ctx.update.updateId, 40)
        @Expect(handled.size, 1)
        @Expect(handled[0], 41)
        @Expect(runtime.getUpdatesCalls, 2)
        @Expect(bot.isRunning(), false)
    }

    @TestCase
    public func defaultPollingErrorHandlerStopsAndConfirmsOffset(): Unit {
        let runtime = FakeBotRuntime()
        let me = UserFromGetMe(12, true, "DefaultCatch", "default_catch_bot")
        runtime.enqueueUpdates([Update(60, "message")])
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me), runtime: runtime))
        bot.use({ _ctx: Context, _next: NextFunction =>
            throw Exception("unhandled middleware")
        })

        var thrown = false
        try {
            bot.start(PollingOptions(maxFetchCycles: 3))
        } catch (e: BotError) {
            thrown = true
            @Expect(e.ctx.update.updateId, 60)
        }

        @Expect(thrown, true)
        @Expect(runtime.getUpdatesCalls, 2)
        @Expect(runtime.pollingRequests[1].offset, 61)
        @Expect(runtime.pollingRequests[1].limit, 1)
        @Expect(bot.isRunning(), false)
    }

    @TestCase
    public func stopConfirmsLastTriedUpdateOffset(): Unit {
        let runtime = FakeBotRuntime()
        let me = UserFromGetMe(8, true, "Stop", "stop_bot")
        runtime.enqueueUpdates([Update(50, "message")])
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me), runtime: runtime))
        bot.setUpdateHandler(StoppingHandler(bot))

        bot.start(PollingOptions(maxFetchCycles: 3))

        @Expect(runtime.getUpdatesCalls, 2)
        @Expect(runtime.pollingRequests[1].offset, 51)
        @Expect(runtime.pollingRequests[1].limit, 1)
        @Expect(bot.isRunning(), false)
    }

    @TestCase
    public func startLocksFurtherMiddlewareRegistration(): Unit {
        let runtime = FakeBotRuntime()
        let me = UserFromGetMe(13, true, "Lock", "lock_bot")
        let bot = Bot("fake-token", BotConfig(botInfo: Some(me), runtime: runtime))

        bot.start(PollingOptions(maxFetchCycles: 1))

        var thrown = false
        try {
            bot.use({ _ctx: Context, _next: NextFunction => () })
        } catch (e: BotConfigError) {
            thrown = true
            @Expect(e.message.contains("Cannot register middleware"), true)
        }

        @Expect(thrown, true)
    }
}
