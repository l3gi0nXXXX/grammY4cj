package grammy4cj.core

import grammy4cj.types.ApiResponse
import grammy4cj.types.InputFile
import grammy4cj.types.ResponseParameters
import std.collection.ArrayList
import std.unittest.*

private class CoreTestFakeHttp <: CoreFetch {
    public var called: Bool = false
    public var url: String = ""
    public var headers: String = ""
    public var body: String = ""
    public var baseFetchConfigSummary: String = ""
    public var throwOnFetch: Bool = false
    public var throwMessage: String = ""
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
        if (this.throwOnFetch) {
            throw Exception(this.throwMessage)
        }
        this.called = true
        this.url = request.url
        this.headers = request.headers
        this.body = request.body
        this.baseFetchConfigSummary = request.baseFetchConfigSummary
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

private func coreTestDelayedFailingStreamFile(message: String, filename: String): InputFile {
    InputFile("stream_error_after", message, filename)
}

private class MethodPredicateProbe {
    public var calls: Int64 = 0
    public let allowedMethod: String

    public init(allowedMethod: String) {
        this.allowedMethod = allowedMethod
    }

    public func test(method: String): Bool {
        this.calls += 1
        method == this.allowedMethod
    }
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
    public func customBuildUrlFetchSeamAndBaseFetchConfigAreUsed(): Unit {
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.success("{\"ok\":true}"))
        let base = BaseFetchConfig("custom-root", "custom-agent", false, true, false)
        let options = ApiClientOptions(
            "my-api-root",
            "test",
            500,
            false,
            { _method: String => false },
            { root: String, token: String, method: String, env: String =>
                root + "::" + env + "::" + token + "::" + method
            },
            base
        )
        let client = ApiClient(options, fake)

        @Expect(client.callApi("secret-token", "getMe", Payload("{}")), "{\"ok\":true}")
        @Expect(fake.called, true)
        @Expect(fake.url, "my-api-root::test::secret-token::getMe")
        @Expect(fake.baseFetchConfigSummary, "custom-agent:keepAlive=false:compress=true")
    }

    @TestCase
    public func baseFetchConfigMergesRuntimeDefaultsWithOverrides(): Unit {
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.success("ok"))
        let base = BaseFetchConfig("", "", false, false, false)
        let options = ApiClientOptions(
            "https://api.telegram.org",
            "prod",
            500,
            false,
            { _method: String => false },
            { root: String, token: String, method: String, env: String =>
                let prefix = if (env == "test") { "test/" } else { "" }
                root + "/bot" + token + "/" + prefix + method
            },
            base
        )
        let client = ApiClient(options, fake)

        @Expect(client.callApi("token", "getMe", Payload("{}")), "ok")
        @Expect(fake.baseFetchConfigSummary, "https:keepAlive=false:compress=false")
    }

    @TestCase
    public func apiRootTrailingSlashMessageSuggestsCanonicalRoot(): Unit {
        try {
            ApiClientOptions("https://api.telegram.org/", "prod")
            @Expect(true, false)
        } catch (err: Exception) {
            @Expect(err.message, "Remove the trailing '/' from the 'apiRoot' option (use 'https://api.telegram.org' instead of 'https://api.telegram.org/')")
        }
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
    public func webhookReplyPredicateReceivesMethodAndControlsJsonShortcut(): Unit {
        let predicate = MethodPredicateProbe("sendMessage")
        let envelope = WebhookReplyEnvelope()
        let options = ApiClientOptions(
            "https://api.telegram.org",
            "prod",
            500,
            false,
            { method: String => predicate.test(method) },
            { root: String, token: String, method: String, env: String =>
                let prefix = if (env == "test") { "test/" } else { "" }
                root + "/bot" + token + "/" + prefix + method
            },
            BaseFetchConfig("https://api.telegram.org", "https", true, true, false)
        )
        let client = ApiClient(options, envelope, CoreTestFakeHttp())
        let payload = Payload("").addValue("chat_id", "42")

        @Expect(client.maybeUseWebhookReply("getMe", payload), false)
        @Expect(predicate.calls, 1)
        @Expect(client.maybeUseWebhookReply("sendMessage", payload), true)
        @Expect(predicate.calls, 2)
        @Expect(envelope.payload, "{\"chat_id\":\"42\",\"method\":\"sendMessage\"}")
    }

    @TestCase
    public func multipartPayloadDisablesWebhookReply(): Unit {
        let predicate = MethodPredicateProbe("sendDocument")
        let envelope = WebhookReplyEnvelope()
        let client = ApiClient(
            ApiClientOptions(
                "https://api.telegram.org",
                "prod",
                500,
                false,
                { method: String => predicate.test(method) },
                { root: String, token: String, method: String, env: String =>
                    let prefix = if (env == "test") { "test/" } else { "" }
                    root + "/bot" + token + "/" + prefix + method
                },
                BaseFetchConfig("https://api.telegram.org", "https", true, true, false)
            ),
            envelope
        )
        let payload = Payload("").addFile("document", InputFile.fromBytes("abc", "a.txt"))

        @Expect(client.maybeUseWebhookReply("sendDocument", payload), false)
        @Expect(envelope.sent, false)
        @Expect(predicate.calls, 0)
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
    public func apiClientMapsTelegramErrorResponses(): Unit {
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.failure(42, "evil", ResponseParameters()))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"), fake)

        try {
            client.callApi("token", "getMe", Payload("{}"))
            @Expect(true, false)
        } catch (err: GrammyError) {
            @Expect(err.message, "Call to 'getMe' failed! (42: evil)")
            @Expect(err.errorCode, 42)
        }
    }

    @TestCase
    public func apiClientParsesFetchJsonSuccessAndTelegramFailureBodies(): Unit {
        let successFake = CoreTestFakeHttp().enqueue(CoreFetchResponse(200, "OK", "{\"ok\":true,\"result\":{\"id\":42}}"))
        let successClient = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"), successFake)
        @Expect(successClient.callApi("token", "getMe", Payload("{}")), "{\"id\":42}")

        let failureFake = CoreTestFakeHttp().enqueue(CoreFetchResponse(200, "OK", "{\"ok\":false,\"error_code\":429,\"description\":\"Too Many Requests\",\"parameters\":{\"retry_after\":7}}"))
        let failureClient = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"), failureFake)
        try {
            failureClient.callApi("token", "getMe", Payload("{}"))
            @Expect(true, false)
        } catch (err: GrammyError) {
            @Expect(err.errorCode, 429)
            @Expect(err.description, "Too Many Requests")
            @Expect(err.parameters.retryAfter, 7)
        }
    }

    @TestCase
    public func apiClientMapsJsonParseFailuresToHttpError(): Unit {
        let fake = CoreTestFakeHttp().enqueue(CoreFetchResponse(200, "OK", "not-json"))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, true, false), fake)

        try {
            client.callApi("secret-token", "getMe", Payload("{}"))
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message.contains("Could not parse Telegram response JSON"), true)
            @Expect(err.url, "https://api.telegram.org/botsecret-token/getMe")
        }
    }

    @TestCase
    public func apiClientMapsHttpErrorResponses(): Unit {
        let fake = CoreTestFakeHttp().enqueue(CoreFetchResponse(502, "Bad Gateway", "upstream failed"))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"), fake)

        try {
            client.callApi("token", "getMe", Payload("{}"))
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message, "Network request for 'getMe' failed! (502: Bad Gateway)")
            @Expect(err.status, 502)
            @Expect(err.statusText, "Bad Gateway")
        }
    }

    @TestCase
    public func apiClientMapsNetworkErrorsAndThrownFetchErrors(): Unit {
        let networkFake = CoreTestFakeHttp().enqueue(CoreFetchResponse.networkError("socket closed"))
        let networkClient = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, true, false), networkFake)
        try {
            networkClient.callApi("token", "getMe", Payload("{}"))
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message, "Network request for 'getMe' failed! socket closed")
            @Expect(err.error, "socket closed")
        }

        let thrownFake = CoreTestFakeHttp()
        thrownFake.throwOnFetch = true
        thrownFake.throwMessage = "fetch exploded"
        let thrownClient = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, true, false), thrownFake)
        try {
            thrownClient.callApi("token", "getMe", Payload("{}"))
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message, "Network request for 'getMe' failed! fetch exploded")
            @Expect(err.error, "fetch exploded")
        }
    }

    @TestCase
    public func httpErrorsRecordRedactedUrlUnlessSensitiveLogsAreEnabled(): Unit {
        let hiddenFake = CoreTestFakeHttp().enqueue(CoreFetchResponse.networkError("socket closed"))
        let hiddenClient = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, false, false), hiddenFake)
        try {
            hiddenClient.callApi("secret-token", "getMe", Payload("{}"))
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.url, "https://api.telegram.org/bot<redacted>/getMe")
            @Expect(err.message.contains("secret-token"), false)
        }

        let sensitiveFake = CoreTestFakeHttp().enqueue(CoreFetchResponse.networkError("socket closed"))
        let sensitiveClient = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, true, false), sensitiveFake)
        try {
            sensitiveClient.callApi("secret-token", "getMe", Payload("{}"))
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.url, "https://api.telegram.org/botsecret-token/getMe")
            @Expect(err.message, "Network request for 'getMe' failed! socket closed")
        }
    }

    @TestCase
    public func rawApiFacadeInjectsEmptyPayloadForZeroArgMethods(): Unit {
        let fake = CoreTestFakeHttp()
        fake.enqueueApi(ApiResponse.success("getMe"))
        fake.enqueueApi(ApiResponse.success("getWebhookInfo"))
        fake.enqueueApi(ApiResponse.success("getForumTopicIconStickers"))
        fake.enqueueApi(ApiResponse.success("getAvailableGifts"))
        fake.enqueueApi(ApiResponse.success("logOut"))
        fake.enqueueApi(ApiResponse.success("close"))
        fake.enqueueApi(ApiResponse.success("getMyStarBalance"))
        fake.enqueueApi(ApiResponse.success("removeMyProfilePhoto"))
        let api = createRawApi("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        @Expect(api.raw.getMe(), "getMe")
        @Expect(api.raw.getWebhookInfo(), "getWebhookInfo")
        @Expect(api.raw.getForumTopicIconStickers(), "getForumTopicIconStickers")
        @Expect(api.raw.getAvailableGifts(), "getAvailableGifts")
        @Expect(api.raw.logOut(), "logOut")
        @Expect(api.raw.close(), "close")
        @Expect(api.raw.getMyStarBalance(), "getMyStarBalance")
        @Expect(api.raw.removeMyProfilePhoto(), "removeMyProfilePhoto")
        @Expect(fake.body, "{}")
        @Expect(zeroArgRawMethodNames().size, 8)
        @Expect(isZeroArgRawMethod("getAvailableGifts"), true)
        @Expect(isZeroArgRawMethod("sendMessage"), false)
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
    public func transformerCanShortCircuitWithoutCallingFetch(): Unit {
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.success("unused"))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"), fake)
        client.use("short", { _prev: ApiCallFn, method: String, payload: Payload, _signal: CancelSignal =>
            @Expect(method, "sendMessage")
            @Expect(createJsonPayload(payload).body, "{\"chat_id\":\"42\"}")
            ApiResponse.success("short-circuited")
        })

        @Expect(client.callApi("token", "sendMessage", Payload("").addValue("chat_id", "42")), "short-circuited")
        @Expect(fake.called, false)
    }

    @TestCase
    public func rawFacadeAllowsUnknownMethodsWithExplicitPayload(): Unit {
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.success("ok"))
        let api = createRawApi("token", ApiClientOptions("https://api.telegram.org", "prod"), fake)

        @Expect(api.raw.call("unknownMethod", Payload("").addValue("x", "1")), "ok")
        @Expect(fake.url, "https://api.telegram.org/bottoken/unknownMethod")
        @Expect(fake.body, "{\"x\":\"1\"}")
    }

    @TestCase
    public func installedTransformersCanBeCopiedWithoutSharingNameList(): Unit {
        let source = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"))
        source.use("source-name", { prev: ApiCallFn, method: String, payload: Payload, signal: CancelSignal =>
            prev(method, payload.addValue("copied", "yes"), signal)
        })
        let fake = CoreTestFakeHttp().enqueueApi(ApiResponse.success("ok"))
        let target = ApiClient(ApiClientOptions("https://api.telegram.org", "prod"), fake)

        source.copyInstalledTransformersTo(target)
        source.use("later")

        @Expect(target.installedTransformers.size, 1)
        @Expect(target.installedTransformers[0], "source-name")
        @Expect(target.callApi("token", "sendMessage", Payload("").addValue("chat_id", "42")), "ok")
        @Expect(fake.body, "{\"chat_id\":\"42\",\"copied\":\"yes\"}")
    }

    @TestCase
    public func abortedSignalsAreMappedToHttpError(): Unit {
        let fake = CoreTestFakeHttp().enqueue(CoreFetchResponse.success("{}"))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, true, false), fake)
        let signal = CancelSignal()
        signal.cancel("user abort")

        try {
            client.callApi("token", "getMe", Payload("{}"), signal)
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message, "Network request for 'getMe' failed! Operation cancelled: user abort")
            @Expect(fake.called, false)
        }
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
    public func streamErrorsWinBeforeFetchStarts(): Unit {
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

    @TestCase
    public func delayedStreamErrorsWinBeforeDelayedFetch(): Unit {
        let fake = CoreTestFakeHttp().enqueue(CoreFetchResponse.success("{}").withDelay(1000))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, true, false), fake)
        let payload = Payload("").addFile("document", coreTestDelayedFailingStreamFile("delayed stream exploded", "a.txt"))

        try {
            client.callApi("token", "sendDocument", payload)
            @Expect(true, false)
        } catch (err: HttpError) {
            @Expect(err.message.contains("delayed stream exploded"), true)
        }
    }

    @TestCase
    public func immediateFetchWinsDelayedStreamErrorRace(): Unit {
        let fake = CoreTestFakeHttp().enqueue(CoreFetchResponse.success("ok"))
        let client = ApiClient(ApiClientOptions("https://api.telegram.org", "prod", 500, true, false), fake)
        let payload = Payload("").addFile("document", coreTestDelayedFailingStreamFile("late stream exploded", "a.txt"))

        @Expect(client.callApi("token", "sendDocument", payload), "ok")
    }
}
