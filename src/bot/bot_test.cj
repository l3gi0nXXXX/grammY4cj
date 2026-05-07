package grammy4cj.bot

import std.unittest.*

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
}
