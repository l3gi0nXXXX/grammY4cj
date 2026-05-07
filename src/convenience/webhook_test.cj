package grammy4cj.convenience

import std.unittest.*

import grammy4cj.types.Update

@Test
public class WebhookCallbackTest {
    @TestCase
    public func secretHeaderAllowsCanonicalAndLowercaseNames(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "callback", WebhookOptions("shared-secret"))
        let canonical = WebhookHeaders().set(SECRET_HEADER, "shared-secret")
        let lower = WebhookHeaders().set(SECRET_HEADER_LOWERCASE, "shared-secret")

        let first = callback.handle(WebhookRequest(Update(201), canonical, "callback"))
        let second = callback.handle(WebhookRequest(Update(202), lower, "callback"))

        @Expect(first.unauthorized, false)
        @Expect(second.unauthorized, false)
        @Expect(handler.initCount, 1)
        @Expect(handler.handleUpdateCount, 2)
    }

    @TestCase
    public func secretMismatchUsesUnauthorizedProtocol(): Unit {
        let handler = FakeWebhookUpdateHandler()
        let callback = webhookCallback(handler, "callback", WebhookOptions("expected"))
        let headers = WebhookHeaders().set(SECRET_HEADER, "actual")

        let result = callback.handle(WebhookRequest(Update(203), headers, "callback"))

        @Expect(result.unauthorized, true)
        @Expect(result.response.statusCode, 401)
        @Expect(result.response.body, WRONG_TOKEN_ERROR)
        @Expect(handler.handleUpdateCount, 0)
    }

    @TestCase
    public func webhookReplyRespondsWithJsonInsteadOfEnd(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.webhookReplyJson = "{\"method\":\"sendMessage\"}"
        let callback = webhookCallback(handler, "express")

        let result = callback.handle(WebhookRequest(Update(204), WebhookHeaders(), "express"))

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

        let result = callback.handle(WebhookRequest(Update(205), WebhookHeaders(), "http"))

        @Expect(result.usedWebhookReply, false)
        @Expect(result.response.ended, true)
        @Expect(result.response.statusCode, 200)
    }

    @TestCase
    public func timeoutReturnModeEndsWithoutHandlingUpdate(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.delayMilliseconds = 25
        let options = WebhookOptions(WEBHOOK_TIMEOUT_RETURN, 10, "")
        let callback = webhookCallback(handler, "callback", options)

        let result = callback.handle(WebhookRequest(Update(206), WebhookHeaders(), "callback"))

        @Expect(result.timedOut, true)
        @Expect(result.response.ended, true)
        @Expect(handler.handleUpdateCount, 0)
    }

    @TestCase
    public func timeoutThrowModeRaisesTimeoutError(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.delayMilliseconds = 25
        let options = WebhookOptions(WEBHOOK_TIMEOUT_THROW, 10, "")
        let callback = webhookCallback(handler, "callback", options)
        var thrown = false

        try {
            callback.handle(WebhookRequest(Update(207), WebhookHeaders(), "callback"))
        } catch (err: WebhookTimeoutError) {
            thrown = true
            @Expect(err.timeoutMilliseconds, 10)
        }

        @Expect(thrown, true)
        @Expect(handler.handleUpdateCount, 0)
    }

    @TestCase
    public func timeoutFunctionModeRunsFakeTimeoutCallback(): Unit {
        let handler = FakeWebhookUpdateHandler()
        handler.delayMilliseconds = 25
        let options = WebhookOptions(WEBHOOK_TIMEOUT_FUNCTION, 10, "")
        let callback = webhookCallback(handler, "callback", options)

        let result = callback.handle(WebhookRequest(Update(208), WebhookHeaders(), "callback"))

        @Expect(result.timedOut, true)
        @Expect(handler.timeoutCallbackCount, 1)
    }
}
