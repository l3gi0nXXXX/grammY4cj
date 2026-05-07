package grammy4cj.core

import grammy4cj.types.ApiResponse
import grammy4cj.types.InputFile
import grammy4cj.types.ResponseParameters
import std.collection.ArrayList
import std.unittest.*

private class CoreTestFakeHttp <: CoreFetch {
    public var called: Bool = false
    public var url: String = ""
    public var body: String = ""
    private let responses: ArrayList<CoreFetchResponse> = ArrayList<CoreFetchResponse>()

    public init() {}

    public func enqueue(response: CoreFetchResponse): CoreTestFakeHttp {
        this.responses.add(response)
        this
    }

    public func enqueueApi(response: ApiResponse): CoreTestFakeHttp {
        this.enqueue(CoreFetchResponse.api(response))
    }

    public func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse {
        signal.throwIfCancelled()
        this.called = true
        this.url = request.url
        this.body = request.body
        if (this.responses.size == 0) {
            return CoreFetchResponse.success("{}")
        }
        let response = this.responses[0]
        this.responses.remove(at: 0)
        response
    }
}

private func coreTestFailingStreamFile(message: String, filename: String): InputFile {
    InputFile("stream_error", message, filename)
}

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
        @Expect(envelope.payload, "{\"chat_id\":\"42\",\"method\":\"sendMessage\"}")
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

    @TestCase
    public func fakeFetchSeamReturnsApiResponsesWithoutNetwork(): Unit {
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.success("{\"id\":42}"))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"), fake)
        let result = client.callApi("token", "getMe", Payload("{}"))

        @Expect(result, "{\"id\":42}")
        @Expect(fake.called, true)
        @Expect(fake.url, "https://api.telegram.org/bottoken/getMe")
        @Expect(fake.body, "{}")
    }

    @TestCase
    public func rawApiFacadeInjectsEmptyPayloadForZeroArgMethods(): Unit {
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.success("{\"id\":42}"))
        let api = createRawApi("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        @Expect(api.raw.getMe(), "{\"id\":42}")
        @Expect(fake.body, "{}")
    }

    @TestCase
    public func transformerFunctionsWrapApiCallsInInstallOrder(): Unit {
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.success("ok"))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"), fake)
        let events = ArrayList<String>()

        client.use("first", { prev: ApiCallFn, method: String, payload: Payload, signal: CancelSignal =>
            events.add("first:before")
            let response = prev(method, payload.addValue("first", "1"), signal)
            events.add("first:after")
            response
        })
        client.use("second", { prev: ApiCallFn, method: String, payload: Payload, signal: CancelSignal =>
            events.add("second:before")
            let response = prev(method, payload.addValue("second", "2"), signal)
            events.add("second:after")
            response
        })

        @Expect(client.callApi("token", "sendMessage", Payload("").addValue("chat_id", "42")), "ok")
        @Expect(events[0], "second:before")
        @Expect(events[1], "first:before")
        @Expect(events[2], "first:after")
        @Expect(events[3], "second:after")
        @Expect(fake.body, "{\"chat_id\":\"42\",\"second\":\"2\",\"first\":\"1\"}")
    }

    @TestCase
    public func timeoutWinsTransportRaceAndCancelsSignal(): Unit {
        let fake = CoreTestFakeHttp().enqueue(CoreFetchResponse.success("{}").withDelay(3000))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 2, false, false), fake)
        let signal = CancelSignal()

        try {
            client.callApi("token", "getMe", Payload("{}"), signal)
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message, "Network request for 'getMe' failed!")
            @Expect(signal.cancelled, true)
        }
    }

    @TestCase
    public func streamErrorsWinBeforeDelayedFetch(): Unit {
        let fake = CoreTestFakeHttp().enqueue(CoreFetchResponse.success("{}").withDelay(1000))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, true, false), fake)
        let payload = Payload("").addFile("document", coreTestFailingStreamFile("stream exploded", "a.txt"))

        try {
            client.callApi("token", "sendDocument", payload)
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message.contains("stream exploded"), true)
        }
    }
}
