package grammy4cj.convenience

import std.unittest.*

import grammy4cj.bot.Bot
import grammy4cj.bot.BotConfig
import grammy4cj.bot.FakeBotRuntime
import grammy4cj.bot.PollingOptions
import grammy4cj.bot.RecordingBotUpdateHandler
import grammy4cj.types.Update
import grammy4cj.types.UserFromGetMe

private class WebhookConflictProbe {
    public var threw: Bool = false

    public init() {}

    public func createCallback(bot: Bot): Unit {
        try {
            let _ = webhookCallback(bot, "callback")
        } catch (e: WebhookLongPollingConflictError) {
            this.threw = true
        }
    }

    public func handleCallback(callback: WebhookCallback): Unit {
        try {
            let _ = callback.handle(WebhookRequest(Update(203), WebhookHeaders(), "callback"))
        } catch (e: WebhookLongPollingConflictError) {
            this.threw = true
        }
    }
}

private class TimeoutCallbackProbe {
    public var count: Int64 = 0

    public init() {}

    public func record(): Unit {
        this.count += 1
    }
}

@Test
public class WebhookCallbackTest {
    @TestCase
    public func botWebhookCallbackInitializesAndHandlesUpdatesViaPublicApi(): Unit {
        let runtime = FakeBotRuntime()
        let recording = RecordingBotUpdateHandler()
        runtime.getMeResult = UserFromGetMe(42, true, "Webhook", "webhook_bot")
        let bot = Bot("fake-token", BotConfig(runtime: runtime, updateHandler: recording))
        let callback = webhookCallback(bot, "callback")

        let first = callback.handle(WebhookRequest(Update(201), WebhookHeaders(), "callback"))
        let second = callback.handle(WebhookRequest(Update(202), WebhookHeaders(), "callback"))

        @Expect(first.response.ended, true)
        @Expect(second.response.ended, true)
        @Expect(runtime.getMeCalls, 1)
        @Expect(recording.contexts.size, 2)
        @Expect(recording.contexts[0].update.updateId, 201)
        @Expect(recording.contexts[1].update.updateId, 202)
    }

    @TestCase
    public func botWebhookCallbackRejectsWhileLongPollingIsRunning(): Unit {
        let runtime = FakeBotRuntime()
        let bot = Bot(
            "fake-token",
            BotConfig(botInfo: Some(UserFromGetMe(43, true, "Poll", "poll_bot")), runtime: runtime)
        )
        let probe = WebhookConflictProbe()

        bot.start(PollingOptions(
            maxFetchCycles: 1,
            onStart: Some({ _info: UserFromGetMe =>
                probe.createCallback(bot)
            })
        ))

        @Expect(probe.threw, true)
    }

    @TestCase
    public func webhookHandleRejectsIfLongPollingStartsAfterSetup(): Unit {
        let runtime = FakeBotRuntime()
        let bot = Bot(
            "fake-token",
            BotConfig(botInfo: Some(UserFromGetMe(44, true, "Poll", "poll_bot")), runtime: runtime)
        )
        let callback = webhookCallback(bot, "callback")
        let probe = WebhookConflictProbe()

        bot.start(PollingOptions(
            maxFetchCycles: 1,
            onStart: Some({ _info: UserFromGetMe =>
                probe.handleCallback(callback)
            })
        ))

        @Expect(probe.threw, true)
    }

    @TestCase
    public func secretHeaderAllowsCanonicalAndLowercaseNames(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "callback", WebhookOptions("shared-secret"))
        let canonical = WebhookHeaders().set(SECRET_HEADER, "shared-secret")
        let lower = WebhookHeaders().set(SECRET_HEADER_LOWERCASE, "shared-secret")

        let first = callback.handle(WebhookRequest(Update(204), canonical, "callback"))
        let second = callback.handle(WebhookRequest(Update(205), lower, "callback"))

        @Expect(first.unauthorized, false)
        @Expect(second.unauthorized, false)
        @Expect(handler.initCount, 1)
        @Expect(handler.handleUpdateCount, 2)
    }

    @TestCase
    public func secretMismatchUsesAdapterUnauthorizedProtocol(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "callback", WebhookOptions("expected"))
        let headers = WebhookHeaders().set(SECRET_HEADER, "actual")

        let result = callback.handle(WebhookRequest(Update(206), headers, "callback"))

        @Expect(result.unauthorized, true)
        @Expect(result.response.statusCode, 401)
        @Expect(result.response.body, "\"unauthorized\"")
        @Expect(handler.handleUpdateCount, 0)
    }

    @TestCase
    public func emptyConfiguredSecretRequiresPresentEmptyHeader(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "callback", WebhookOptions(""))
        let missing = callback.handle(WebhookRequest(Update(207), WebhookHeaders(), "callback"))
        let present = callback.handle(WebhookRequest(Update(208), WebhookHeaders().set(SECRET_HEADER, ""), "callback"))

        @Expect(missing.unauthorized, true)
        @Expect(present.unauthorized, false)
        @Expect(handler.handleUpdateCount, 1)
    }

    @TestCase
    public func secretComparisonIsConstantPathAndLengthAware(): Unit {
        @Expect(secretTokenMatches("", "", false, false), true)
        @Expect(secretTokenMatches("abc", "abc", true, true), true)
        @Expect(secretTokenMatches("abx", "abc", true, true), false)
        @Expect(secretTokenMatches("abcx", "abc", true, true), false)
        @Expect(secretTokenMatches("", "", true, true), true)
        @Expect(secretTokenMatches("", "", true, false), false)
    }

    @TestCase
    public func webhookReplyRespondsWithJsonInsteadOfEnd(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.webhookReplyJson = "{\"method\":\"sendMessage\"}"
        let callback = webhookCallback(handler, "express")

        let result = callback.handle(WebhookRequest(Update(209), WebhookHeaders(), "express"))

        @Expect(result.usedWebhookReply, true)
        @Expect(result.response.responded, true)
        @Expect(result.response.ended, false)
        @Expect(result.response.contentType, "application/json")
        @Expect(result.response.body, "{\"method\":\"sendMessage\"}")
    }

    @TestCase
    public func noWebhookReplyEndsRequest(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "http")

        let result = callback.handle(WebhookRequest(Update(210), WebhookHeaders(), "http"))

        @Expect(result.usedWebhookReply, false)
        @Expect(result.response.ended, true)
        @Expect(result.response.statusCode, 200)
    }

    @TestCase
    public func timeoutReturnModeEndsAndRecordsBackgroundUpdate(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.delayMilliseconds = 25
        let options = WebhookOptions(WEBHOOK_TIMEOUT_RETURN, 10, "")
        let callback = webhookCallback(handler, "callback", options)

        let result = callback.handle(WebhookRequest(Update(211), WebhookHeaders(), "callback"))

        @Expect(result.timedOut, true)
        @Expect(result.response.ended, true)
        @Expect(handler.handleUpdateCount, 1)
        @Expect(handler.lastUpdateId, 211)
    }

    @TestCase
    public func timeoutThrowModeRaisesTimeoutErrorAfterStartingUpdate(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.delayMilliseconds = 25
        let options = WebhookOptions(WEBHOOK_TIMEOUT_THROW, 10, "")
        let callback = webhookCallback(handler, "callback", options)
        var thrown = false

        try {
            callback.handle(WebhookRequest(Update(212), WebhookHeaders(), "callback"))
        } catch (err: WebhookTimeoutError) {
            thrown = true
            @Expect(err.timeoutMilliseconds, 10)
        }

        @Expect(thrown, true)
        @Expect(handler.handleUpdateCount, 1)
    }

    @TestCase
    public func timeoutFunctionModeRunsFakeTimeoutCallback(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.delayMilliseconds = 25
        let options = WebhookOptions(WEBHOOK_TIMEOUT_FUNCTION, 10, "")
        let callback = webhookCallback(handler, "callback", options)

        let result = callback.handle(WebhookRequest(Update(213), WebhookHeaders(), "callback"))

        @Expect(result.timedOut, true)
        @Expect(handler.timeoutCallbackCount, 1)
        @Expect(handler.handleUpdateCount, 1)
    }

    @TestCase
    public func timeoutFunctionOptionRunsCustomCallback(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.delayMilliseconds = 25
        let probe = TimeoutCallbackProbe()
        let options = WebhookOptions({ =>
            probe.record()
        }, 10, "")
        let callback = webhookCallback(handler, "callback", options)

        let result = callback.handle(WebhookRequest(Update(214), WebhookHeaders(), "callback"))

        @Expect(result.timedOut, true)
        @Expect(probe.count, 1)
        @Expect(handler.timeoutCallbackCount, 0)
    }

    @TestCase
    public func webhookReplyAfterTimeoutIsRecordedAsLateReply(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.delayMilliseconds = 25
        handler.webhookReplyJson = "{\"ok\":true}"
        let options = WebhookOptions(WEBHOOK_TIMEOUT_RETURN, 10, "")
        let callback = webhookCallback(handler, "callback", options)

        let result = callback.handle(WebhookRequest(Update(215), WebhookHeaders(), "callback"))

        @Expect(result.timedOut, true)
        @Expect(result.response.ended, true)
        @Expect(result.response.responded, false)
        @Expect(result.response.lateWebhookReplySent, true)
        @Expect(result.response.lateWebhookReplyPayload, "{\"ok\":true}")
    }
}
