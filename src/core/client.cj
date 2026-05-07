package grammy4cj.core

import std.collection.ArrayList

import grammy4cj.platform.BaseFetchConfig
import grammy4cj.types.ApiResponse
import grammy4cj.types.ResponseParameters

public type ApiCallFn = (String, Payload, CancelSignal) -> ApiResponse
public type Transformer = (ApiCallFn, String, Payload, CancelSignal) -> ApiResponse

private func emptyBaseFetchConfig(): BaseFetchConfig {
    BaseFetchConfig("", "", false, false, true)
}

public class CoreHttpRequest {
    public let method: String
    public let url: String
    public let headers: String
    public let body: String
    public let payload: RequestPayload
    public let baseFetchConfig: BaseFetchConfig
    public let baseFetchConfigSummary: String

    public init(method: String, url: String, headers: String, body: String) {
        this.method = method
        this.url = url
        this.headers = headers
        this.body = body
        this.payload = RequestPayload(method, headers, body)
        this.baseFetchConfig = emptyBaseFetchConfig()
        this.baseFetchConfigSummary = this.baseFetchConfig.summary()
    }

    public init(method: String, url: String, headers: String, body: String, baseFetchConfig: BaseFetchConfig) {
        this.method = method
        this.url = url
        this.headers = headers
        this.body = body
        this.payload = RequestPayload(method, headers, body)
        this.baseFetchConfig = baseFetchConfig
        this.baseFetchConfigSummary = baseFetchConfig.summary()
    }

    public init(url: String, payload: RequestPayload) {
        this.method = payload.method
        this.url = url
        this.headers = payload.headers
        this.body = payload.body
        this.payload = payload
        this.baseFetchConfig = emptyBaseFetchConfig()
        this.baseFetchConfigSummary = this.baseFetchConfig.summary()
    }

    public init(url: String, payload: RequestPayload, baseFetchConfig: BaseFetchConfig) {
        this.method = payload.method
        this.url = url
        this.headers = payload.headers
        this.body = payload.body
        this.payload = payload
        this.baseFetchConfig = baseFetchConfig
        this.baseFetchConfigSummary = baseFetchConfig.summary()
    }
}

public class CoreFetchResponse {
    public let status: Int64
    public let statusText: String
    public let body: String
    public let apiResponse: ApiResponse
    public let hasApiResponse: Bool
    public let hasTransportError: Bool
    public let transportErrorMessage: String
    public var delayMillis: Int64 = 0

    public init(status: Int64, statusText: String, body: String) {
        this.status = status
        this.statusText = statusText
        this.body = body
        this.apiResponse = ApiResponse.success(body)
        this.hasApiResponse = false
        this.hasTransportError = false
        this.transportErrorMessage = ""
    }

    public init(response: ApiResponse) {
        this.status = 200
        this.statusText = "OK"
        this.body = response.result
        this.apiResponse = response
        this.hasApiResponse = true
        this.hasTransportError = false
        this.transportErrorMessage = ""
    }

    public init(message: String, status: Int64, statusText: String) {
        this.status = status
        this.statusText = statusText
        this.body = ""
        this.apiResponse = ApiResponse.success("")
        this.hasApiResponse = false
        this.hasTransportError = true
        this.transportErrorMessage = message
    }

    public static func success(result: String): CoreFetchResponse {
        CoreFetchResponse(ApiResponse.success(result))
    }

    public static func api(response: ApiResponse): CoreFetchResponse {
        CoreFetchResponse(response)
    }

    public static func networkError(message: String): CoreFetchResponse {
        CoreFetchResponse(message, 0, "")
    }

    public static func telegramError(status: Int64, statusText: String, message: String): CoreFetchResponse {
        CoreFetchResponse(message, status, statusText)
    }

    public func withDelay(delayMillis: Int64): CoreFetchResponse {
        this.delayMillis = delayMillis
        this
    }
}

public interface CoreFetch {
    func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse
}

public class NoopCoreFetch <: CoreFetch {
    public init() {}

    public func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse {
        signal.throwIfCancelled()
        CoreFetchResponse.networkError("No HTTP client configured for " + request.method + " " + request.url)
    }
}

public class WebhookReplyEnvelope {
    public var sent: Bool = false
    public var payload: String = ""

    public init() {}

    public func send(payload: String): Unit {
        this.sent = true
        this.payload = payload
    }
}

public class ApiClient {
    public let config: ApiClientOptions
    public var installedTransformers: ArrayList<String> = ArrayList<String>()
    public var installedTransformerFunctions: ArrayList<Transformer> = ArrayList<Transformer>()
    public var hasUsedWebhookReply: Bool = false
    public let webhookReplyEnvelope: WebhookReplyEnvelope
    private let fetcher: CoreFetch

    public init(config: ApiClientOptions) {
        this.config = config
        this.webhookReplyEnvelope = WebhookReplyEnvelope()
        this.fetcher = NoopCoreFetch()
    }

    public init(config: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope) {
        this.config = config
        this.webhookReplyEnvelope = webhookReplyEnvelope
        this.fetcher = NoopCoreFetch()
    }

    public init(config: ApiClientOptions, fetcher: CoreFetch) {
        this.config = config
        this.webhookReplyEnvelope = WebhookReplyEnvelope()
        this.fetcher = fetcher
    }

    public init(config: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope, fetcher: CoreFetch) {
        this.config = config
        this.webhookReplyEnvelope = webhookReplyEnvelope
        this.fetcher = fetcher
    }

    public func endpoint(token: String, method: String): String {
        this.config.buildUrl(token, method)
    }

    public func use(transformerName: String): ApiClient {
        this.installedTransformers.add(transformerName)
        this
    }

    public func use(transformer: Transformer): ApiClient {
        this.installedTransformers.add("function")
        this.installedTransformerFunctions.add(transformer)
        this
    }

    public func use(transformerName: String, transformer: Transformer): ApiClient {
        this.installedTransformers.add(transformerName)
        this.installedTransformerFunctions.add(transformer)
        this
    }

    public func jsonRequest(token: String, method: String, payload: Payload): CoreHttpRequest {
        let req = createJsonPayload(payload)
        CoreHttpRequest(req.method, this.endpoint(token, method), req.headers, req.body, this.config.baseFetchConfig)
    }

    public func formRequest(token: String, method: String, payload: Payload, boundary: String, attachIdPrefix: String): CoreHttpRequest {
        let req = createFormDataPayload(payload, boundary, attachIdPrefix)
        CoreHttpRequest(this.endpoint(token, method), req, this.config.baseFetchConfig)
    }

    public func maybeUseWebhookReply(method: String, payload: Payload): Bool {
        if (this.hasUsedWebhookReply || requiresFormDataUpload(payload) || !this.config.canUseWebhookReplyFor(method)) {
            return false
        }
        this.webhookReplyEnvelope.send(createJsonPayloadWithMethod(payload, method).body)
        this.hasUsedWebhookReply = true
        true
    }

    public func dispatchRaw(method: String): Payload {
        Payload("{}").addValue("__method", method)
    }

    public func dispatchRaw(method: String, payload: Payload): Payload {
        payload.addValue("__method", method)
    }

    public func resultOrThrow(method: String, payload: Payload, response: ApiResponse): String {
        if (response.ok) {
            return response.result
        }
        throw toGrammyError(response.error, method, payload)
    }

    public func httpErrorFor(method: String, url: String, message: String): HttpError {
        HttpError(message, 599, method, url)
    }

    public func timeoutConfig(): TimeoutConfig {
        TimeoutConfig(this.config.timeoutSeconds * 1000)
    }

    public func copyInstalledTransformersTo(target: ApiClient): ApiClient {
        for (name in this.installedTransformers) {
            target.installedTransformers.add(name)
        }
        for (transformer in this.installedTransformerFunctions) {
            target.installedTransformerFunctions.add(transformer)
        }
        target
    }

    public func callApi(token: String, method: String, payload: Payload): String {
        this.callApi(token, method, payload, CancelSignal())
    }

    public func callApi(token: String, method: String, payload: Payload, signal: CancelSignal): String {
        let response = this.callWithTransformers(token, method, payload, signal)
        this.resultOrThrow(method, payload, response)
    }

    private func callWithTransformers(token: String, method: String, payload: Payload, signal: CancelSignal): ApiResponse {
        var call: ApiCallFn = { m: String, p: Payload, s: CancelSignal => this.performCall(token, m, p, s) }
        for (transformer in this.installedTransformerFunctions) {
            let previous = call
            call = { m: String, p: Payload, s: CancelSignal => transformer(previous, m, p, s) }
        }
        call(method, payload, signal)
    }

    private func performCall(token: String, method: String, payload: Payload, signal: CancelSignal): ApiResponse {
        try {
            signal.throwIfCancelled()
        } catch (err: Exception) {
            throw toHttpError(method, this.config.sensitiveLogs, err)
        }
        if (this.maybeUseWebhookReply(method, payload)) {
            return ApiResponse.success("true")
        }

        let requestPayload = if (requiresFormDataUpload(payload)) {
            createFormDataPayload(payload, "----grammy4cj-boundary", "attach")
        } else {
            createJsonPayload(payload)
        }
        let request = CoreHttpRequest(this.endpoint(token, method), requestPayload, this.config.baseFetchConfig)

        if (requestPayload.stream.hasError && requestPayload.stream.errorAfterMillis == 0) {
            throw toHttpError(method, this.config.sensitiveLogs, Exception(requestPayload.stream.errorMessage))
        }

        var response = CoreFetchResponse.success("")
        try {
            response = this.fetcher.fetch(request, signal)
        } catch (err: Exception) {
            throw toHttpError(method, this.config.sensitiveLogs, err)
        }
        this.resolveTransportRace(method, requestPayload, response, signal)
    }

    private func resolveTransportRace(method: String, requestPayload: RequestPayload, response: CoreFetchResponse, signal: CancelSignal): ApiResponse {
        signal.throwIfCancelled()
        let timeoutMillis = this.timeoutConfig().timeoutMillis
        let streamFails = requestPayload.stream.hasError
        let streamMillis = requestPayload.stream.errorAfterMillis

        if (streamFails && streamMillis > 0 && (response.delayMillis == 0 || streamMillis <= response.delayMillis) && (timeoutMillis <= 0 || streamMillis <= timeoutMillis)) {
            throw toHttpError(method, this.config.sensitiveLogs, Exception(requestPayload.stream.errorMessage))
        }

        if (timeoutMillis > 0 && response.delayMillis > timeoutMillis) {
            let seconds = this.config.timeoutSeconds.toString()
            signal.cancelled = true
            signal.reason = "Request to '" + method + "' timed out after " + seconds + " seconds"
            throw toHttpError(method, this.config.sensitiveLogs, Exception(signal.reason))
        }

        if (response.hasTransportError) {
            throw toHttpError(method, this.config.sensitiveLogs, response.status, response.statusText, response.transportErrorMessage)
        }

        if (response.hasApiResponse) {
            return response.apiResponse
        }

        if (response.status >= 400) {
            throw toHttpError(method, this.config.sensitiveLogs, response.status, response.statusText, response.body)
        }
        ApiResponse.success(response.body)
    }
}

public class RawApiFacade {
    private let token: String
    private let client: ApiClient

    public init(token: String, client: ApiClient) {
        this.token = token
        this.client = client
    }

    public func call(method: String): String {
        this.call(method, Payload("{}"))
    }

    public func call(method: String, payload: Payload): String {
        this.client.callApi(this.token, method, payload)
    }

    public func call(method: String, payload: Payload, signal: CancelSignal): String {
        this.client.callApi(this.token, method, payload, signal)
    }

    public func getMe(): String {
        this.call("getMe", Payload("{}"))
    }

    public func getWebhookInfo(): String {
        this.call("getWebhookInfo", Payload("{}"))
    }

    public func getForumTopicIconStickers(): String {
        this.call("getForumTopicIconStickers", Payload("{}"))
    }

    public func getAvailableGifts(): String {
        this.call("getAvailableGifts", Payload("{}"))
    }

    public func logOut(): String {
        this.call("logOut", Payload("{}"))
    }

    public func close(): String {
        this.call("close", Payload("{}"))
    }

    public func getMyStarBalance(): String {
        this.call("getMyStarBalance", Payload("{}"))
    }

    public func removeMyProfilePhoto(): String {
        this.call("removeMyProfilePhoto", Payload("{}"))
    }

    public func sendMessage(payload: Payload): String {
        this.call("sendMessage", payload)
    }

    public func sendDocument(payload: Payload): String {
        this.call("sendDocument", payload)
    }
}

public class TransformableApi {
    public let raw: RawApiFacade
    public let installedTransformers: ArrayList<String>
    private let client: ApiClient

    public init(token: String) {
        this.client = ApiClient(ApiClientOptions())
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public init(token: String, options: ApiClientOptions) {
        this.client = ApiClient(options)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public init(token: String, options: ApiClientOptions, fetcher: CoreFetch) {
        this.client = ApiClient(options, fetcher)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public init(token: String, options: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope, fetcher: CoreFetch) {
        this.client = ApiClient(options, webhookReplyEnvelope, fetcher)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
    }

    public func use(transformerName: String): TransformableApi {
        this.client.use(transformerName)
        this
    }

    public func use(transformer: Transformer): TransformableApi {
        this.client.use(transformer)
        this
    }

    public func use(transformerName: String, transformer: Transformer): TransformableApi {
        this.client.use(transformerName, transformer)
        this
    }
}

public func createRawApi(token: String): TransformableApi {
    TransformableApi(token)
}

public func createRawApi(token: String, options: ApiClientOptions): TransformableApi {
    TransformableApi(token, options)
}

public func createRawApi(token: String, options: ApiClientOptions, fetcher: CoreFetch): TransformableApi {
    TransformableApi(token, options, fetcher)
}

public func createRawApi(token: String, options: ApiClientOptions, webhookReplyEnvelope: WebhookReplyEnvelope, fetcher: CoreFetch): TransformableApi {
    TransformableApi(token, options, webhookReplyEnvelope, fetcher)
}

public func zeroArgRawMethodNames(): Array<String> {
    [
        "getMe",
        "getWebhookInfo",
        "getForumTopicIconStickers",
        "getAvailableGifts",
        "logOut",
        "close",
        "getMyStarBalance",
        "removeMyProfilePhoto"
    ]
}

public func isZeroArgRawMethod(method: String): Bool {
    for (name in zeroArgRawMethodNames()) {
        if (name == method) {
            return true
        }
    }
    false
}
