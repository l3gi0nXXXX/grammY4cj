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

private func webhookRequest(adapterName: String, updateId: Int64): WebhookRequest {
    WebhookRequest(Update(updateId), "{\"update_id\":${updateId}}", WebhookHeaders(), adapterName)
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

        @Expect(first.response.ended, false)
        @Expect(second.response.ended, false)
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
    public func legacyOptionsOverloadAndCustomAdapterAreAccepted(): Unit {
        let legacyHandler = FakeWebhookUpdateHandler()
        let legacy = webhookCallback(
            legacyHandler,
            "callback",
            WEBHOOK_TIMEOUT_RETURN,
            100,
            "shared-secret"
        )
        let legacyResult = legacy.handle(WebhookRequest(
            Update(239),
            WebhookHeaders().set(SECRET_HEADER, "shared-secret"),
            "callback"
        ))

        @Expect(legacyResult.unauthorized, false)
        @Expect(legacyHandler.handleUpdateCount, 1)

        let customHandler = FakeWebhookUpdateHandler()
        let custom = webhookCallback(customHandler, { request: WebhookRequest =>
            expressAdapter(request)
        }, WebhookOptions("custom-secret"))
        let customResult = custom.handle(WebhookRequest(
            Update(240),
            WebhookHeaders().set(SECRET_HEADER, "custom-secret"),
            "express"
        ))

        @Expect(customResult.unauthorized, false)
        @Expect(customResult.response.responseDelivery, "mutable-response")
        @Expect(customHandler.lastUpdateId, 240)
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
        @Expect(result.response.ended, false)
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
        @Expect(result.response.ended, false)
        @Expect(result.response.responded, false)
        @Expect(result.response.lateWebhookReplySent, true)
        @Expect(result.response.lateWebhookReplyPayload, "{\"ok\":true}")
    }

    @TestCase
    public func updateSourceFailureIsPropagatedBeforeTimeout(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "http", WebhookOptions(WEBHOOK_TIMEOUT_THROW, 200, ""))
        var thrown = false

        try {
            let _ = callback.handle(WebhookRequest.failing(
                Update(241),
                "{\"update_id\":241}",
                WebhookHeaders(),
                "http",
                "request body failed"
            ))
        } catch (e: WebhookUpdateSourceError) {
            thrown = true
            @Expect(e.message, "request body failed")
        }

        @Expect(thrown, true)
        @Expect(handler.handleUpdateCount, 0)
    }

    @TestCase
    public func updateSourceTimeoutUsesThrowOrReturnStrategy(): Unit {
        let returnHandler = FakeWebhookUpdateHandler()
        let returnCallback = webhookCallback(
            returnHandler,
            "http",
            WebhookOptions(WEBHOOK_TIMEOUT_RETURN, 10, "")
        )
        let returned = returnCallback.handle(WebhookRequest.delayed(
            Update(242),
            "{\"update_id\":242}",
            WebhookHeaders(),
            "http",
            25
        ))

        @Expect(returned.timedOut, true)
        @Expect(returned.response.ended, true)
        @Expect(returned.updateId, 0)
        @Expect(returnHandler.handleUpdateCount, 1)

        let throwHandler = FakeWebhookUpdateHandler()
        let throwCallback = webhookCallback(
            throwHandler,
            "http",
            WebhookOptions(WEBHOOK_TIMEOUT_THROW, 10, "")
        )
        var thrown = false
        try {
            let _ = throwCallback.handle(WebhookRequest.delayed(
                Update(243),
                "{\"update_id\":243}",
                WebhookHeaders(),
                "http",
                25
            ))
        } catch (e: WebhookTimeoutError) {
            thrown = true
            @Expect(e.timeoutMilliseconds, 10)
        }

        @Expect(thrown, true)
        @Expect(throwHandler.handleUpdateCount, 1)
    }

    @TestCase
    public func awsLambdaWebhookAdapterProcessesNormalRequest(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "aws-lambda")

        let result = callback.handle(webhookRequest("aws-lambda", 216))

        @Expect(result.response.ended, true)
        @Expect(result.response.responseDelivery, "lambda-callback")
        @Expect(handler.handleUpdateCount, 1)
        @Expect(handler.lastUpdateId, 216)
    }

    @TestCase
    public func awsLambdaAsyncWebhookAdapterResolvesHandlerReturn(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "aws-lambda-async")

        let result = callback.handle(webhookRequest("aws-lambda-async", 217))

        @Expect(result.response.ended, true)
        @Expect(result.response.handlerReturnAvailable, true)
        @Expect(result.response.handlerReturnResolved, true)
        @Expect(result.response.handlerReturnKind, "promise-lambda-result")
    }

    @TestCase
    public func azureWebhookAdapterUsesMutableResponse(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "azure")

        let result = callback.handle(webhookRequest("azure", 218))

        @Expect(result.response.ended, true)
        @Expect(result.response.responseDelivery, "mutable-response")
        @Expect(result.response.endProtocol, "context-res-status-200-empty-body")
    }

    @TestCase
    public func azureV4WebhookAdapterUsesHandlerReturn(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.webhookReplyJson = "{\"method\":\"sendMessage\"}"
        let callback = webhookCallback(handler, "azure-v4")

        let result = callback.handle(webhookRequest("azure-v4", 219))

        @Expect(result.usedWebhookReply, true)
        @Expect(result.response.handlerReturnAvailable, true)
        @Expect(result.response.handlerReturnResolved, true)
        @Expect(result.response.respondProtocol, "resolve-json-body")
    }

    @TestCase
    public func bunWebhookAdapterUsesResponseHandlerReturn(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.webhookReplyJson = "{\"method\":\"answerCallbackQuery\"}"
        let callback = webhookCallback(handler, "bun")

        let result = callback.handle(webhookRequest("bun", 220))

        @Expect(result.response.handlerReturnKind, "promise-response")
        @Expect(result.response.contentType, "application/json")
        @Expect(result.response.body, "{\"method\":\"answerCallbackQuery\"}")
    }

    @TestCase
    public func cloudflareWebhookAdapterUsesEventRespondWith(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "cloudflare")

        let result = callback.handle(webhookRequest("cloudflare", 221))

        @Expect(result.response.responseDelivery, "event-respond-with")
        @Expect(result.response.ended, true)
        @Expect(handler.lastUpdateId, 221)
    }

    @TestCase
    public func cloudflareModuleWebhookAdapterReturnsResponsePromise(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "cloudflare-mod")

        let result = callback.handle(webhookRequest("cloudflare-mod", 222))

        @Expect(result.response.handlerReturnAvailable, true)
        @Expect(result.response.handlerReturnKind, "promise-response")
        @Expect(result.response.handlerReturnResolved, true)
    }

    @TestCase
    public func elysiaWebhookAdapterReturnsStringPromise(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.webhookReplyJson = "{\"ok\":true}"
        let callback = webhookCallback(handler, "elysia")

        let result = callback.handle(webhookRequest("elysia", 223))

        @Expect(result.response.handlerReturnKind, "promise-string")
        @Expect(result.response.respondProtocol, "set-content-type-resolve-json")
        @Expect(result.response.body, "{\"ok\":true}")
    }

    @TestCase
    public func expressWebhookAdapterUsesResponseEndAndSend(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "express")

        let result = callback.handle(webhookRequest("express", 224))

        @Expect(result.response.responseDelivery, "mutable-response")
        @Expect(result.response.endProtocol, "response-end")
        @Expect(result.response.statusCode, 200)
    }

    @TestCase
    public func fastifyWebhookAdapterUsesReplySend(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.webhookReplyJson = "{\"ok\":true}"
        let callback = webhookCallback(handler, "fastify")

        let result = callback.handle(webhookRequest("fastify", 225))

        @Expect(result.response.respondProtocol, "reply-headers-send")
        @Expect(result.response.responded, true)
        @Expect(result.response.contentType, "application/json")
    }

    @TestCase
    public func honoWebhookAdapterReturnsResponsePromise(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "hono")

        let result = callback.handle(webhookRequest("hono", 226))

        @Expect(result.response.handlerReturnAvailable, true)
        @Expect(result.response.handlerReturnKind, "promise-response")
        @Expect(result.response.endProtocol, "resolve-empty-body")
    }

    @TestCase
    public func nodeHttpAndHttpsWebhookAdaptersShareRawJsonContract(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let http = webhookCallback(handler, "http")
        let https = webhookCallback(handler, "https")

        let httpResult = http.handle(webhookRequest("http", 227))
        let httpsResult = https.handle(webhookRequest("https", 228))

        @Expect(httpResult.response.updateSource, "node-raw-json-stream")
        @Expect(httpsResult.response.updateSource, "node-raw-json-stream")
        @Expect(handler.handleUpdateCount, 2)
    }

    @TestCase
    public func koaNextNhttpOakWebhookAdaptersUseMutableResponses(): Unit {
        let handler = FakeWebhookUpdateHandler()

        let koa = webhookCallback(handler, "koa").handle(webhookRequest("koa", 229))
        let next = webhookCallback(handler, "next-js").handle(webhookRequest("next-js", 230))
        let nhttp = webhookCallback(handler, "nhttp").handle(webhookRequest("nhttp", 231))
        let oak = webhookCallback(handler, "oak").handle(webhookRequest("oak", 232))

        @Expect(koa.response.responseDelivery, "mutable-response")
        @Expect(next.response.responseDelivery, "mutable-response")
        @Expect(nhttp.response.responseDelivery, "mutable-response")
        @Expect(oak.response.responseDelivery, "mutable-response")
        @Expect(handler.handleUpdateCount, 4)
    }

    @TestCase
    public func serveStdSveltekitWorktopWebhookAdaptersExposeReturnProtocols(): Unit {
        let handler = FakeWebhookUpdateHandler()

        let serve = webhookCallback(handler, "serveHttp").handle(webhookRequest("serveHttp", 233))
        let std = webhookCallback(handler, "std/http").handle(webhookRequest("std/http", 234))
        let svelte = webhookCallback(handler, "sveltekit").handle(webhookRequest("sveltekit", 235))
        let worktop = webhookCallback(handler, "worktop").handle(webhookRequest("worktop", 236))

        @Expect(serve.response.responseDelivery, "event-respond-with")
        @Expect(std.response.handlerReturnAvailable, true)
        @Expect(svelte.response.handlerReturnAvailable, true)
        @Expect(worktop.response.responseDelivery, "mutable-response")
        @Expect(handler.handleUpdateCount, 4)
    }

    @TestCase
    public func updateErrorBeforeTimeoutIsPropagated(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.failureMessage = "Update processing failed"
        handler.delayMilliseconds = 20
        let options = WebhookOptions(WEBHOOK_TIMEOUT_THROW, 200, "")
        let callback = webhookCallback(handler, "callback", options)
        var thrown = false

        try {
            let _ = callback.handle(webhookRequest("callback", 237))
        } catch (e: WebhookUpdateFailureError) {
            thrown = true
            @Expect(e.message, "Update processing failed")
        }

        @Expect(thrown, true)
        @Expect(handler.handleUpdateCount, 1)
        let noTimeoutHandler = FakeWebhookUpdateHandler()
        noTimeoutHandler.delayMilliseconds = 25
        let noTimeoutOptions = WebhookOptions(WEBHOOK_TIMEOUT_THROW, -1, "")
        let noTimeoutCallback = webhookCallback(noTimeoutHandler, "callback", noTimeoutOptions)

        let result = noTimeoutCallback.handle(webhookRequest("callback", 238))

        @Expect(result.timedOut, false)
        @Expect(result.response.ended, false)
        @Expect(noTimeoutHandler.handleUpdateCount, 1)
    }
}
