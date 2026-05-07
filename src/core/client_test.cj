package grammy4cj.core

import grammy4cj.types.ApiResponse
import grammy4cj.types.InputFile
import grammy4cj.types.ResponseParameters
import std.unittest.*

@Test
public class ApiClientTest {
    @TestCase
    public func apiClientOptionsBuildDefaultAndTestUrls(): Unit {
        let prod = ApiClientOptions("https://api.telegram.org", "prod")
        let test = ApiClientOptions("https://api.telegram.org", "test")

        @Expect(prod.buildUrl("token", "getMe"), "https://api.telegram.org/bottoken/getMe")
        @Expect(test.buildUrl("token", "getMe"), "https://api.telegram.org/bottoken/test/getMe")
    }

    @TestCase
    public func apiClientCreatesJsonHttpRequests(): Unit {
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"))
        let payload = Payload("").addValue("chat_id", "42")
        let req = client.jsonRequest("token", "sendMessage", payload)

        @Expect(req.method, "POST")
        @Expect(req.url, "https://api.telegram.org/bottoken/sendMessage")
        @Expect(req.headers.contains("application/json"), true)
        @Expect(req.body, "{\"chat_id\":\"42\"}")
    }

    @TestCase
    public func transformerInstallOrderIsRecorded(): Unit {
        let client = ApiClient(ApiClientOptions())
        client.use("first").use("second")

        @Expect(client.installedTransformers.size, 2)
        @Expect(client.installedTransformers[0], "first")
        @Expect(client.installedTransformers[1], "second")
    }

    @TestCase
    public func resultOrThrowMapsTelegramResponses(): Unit {
        let client = ApiClient(ApiClientOptions())
        let payload = Payload("").addValue("chat_id", "42")

        @Expect(client.resultOrThrow("sendMessage", payload, ApiResponse.success("{\"message_id\":1}")), "{\"message_id\":1}")
    }

    @TestCase
    public func rawDispatchRecordsMethodName(): Unit {
        let client = ApiClient(ApiClientOptions())
        let payload = client.dispatchRaw("getMe")

        @Expect(createJsonPayload(payload).body, "{\"__method\":\"getMe\"}")
    }

    @TestCase
    public func webhookReplyIsUsedAtMostOnceAndOnlyForJson(): Unit {
        let envelope = WebhookReplyEnvelope()
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, false, true), envelope)
        let payload = Payload("").addValue("chat_id", "42")

        @Expect(client.maybeUseWebhookReply("sendMessage", payload), true)
        @Expect(envelope.sent, true)
        @Expect(envelope.payload, "{\"chat_id\":\"42\"}")
        @Expect(client.maybeUseWebhookReply("sendMessage", payload), false)
    }

    @TestCase
    public func multipartPayloadDisablesWebhookReply(): Unit {
        let envelope = WebhookReplyEnvelope()
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, false, true), envelope)
        let payload = Payload("").addFile("document", InputFile.fromBytes("abc", "a.txt"))

        @Expect(client.maybeUseWebhookReply("sendDocument", payload), false)
        @Expect(envelope.sent, false)
    }

    @TestCase
    public func timeoutConfigUsesSecondsOption(): Unit {
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 2, false, false))

        @Expect(client.timeoutConfig().timeoutMillis, 2000)
    }

    @TestCase
    public func httpErrorKeepsUrlAndMethod(): Unit {
        let client = ApiClient(ApiClientOptions())
        let err = client.httpErrorFor("POST", "https://api.telegram.org/bottoken/getMe", "network failed")

        @Expect(err.status, 599)
        @Expect(err.method, "POST")
        @Expect(err.url, "https://api.telegram.org/bottoken/getMe")
    }
}
