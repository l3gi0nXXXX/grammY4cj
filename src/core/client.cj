package grammy4cj.core

import std.collection.ArrayList

import grammy4cj.types.ApiResponse
import grammy4cj.types.ResponseParameters

public type ApiCallFn = (String, Payload, CancelSignal) -> ApiResponse
public type Transformer = (ApiCallFn, String, Payload, CancelSignal) -> ApiResponse
public type CoreFetchFn = (CoreHttpRequest, CancelSignal) -> CoreFetchResponse

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

public class FunctionCoreFetch <: CoreFetch {
    private let fetchFn: CoreFetchFn

    public init(fetchFn: CoreFetchFn) {
        this.fetchFn = fetchFn
    }

    public func fetch(request: CoreHttpRequest, signal: CancelSignal): CoreFetchResponse {
        this.fetchFn(request, signal)
    }
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
            try {
                requestPayload.stream.raiseError()
            } catch (err: Exception) {
                throw toHttpError(method, this.config.sensitiveLogs, request.url, token, err)
            }
        }

        var response = CoreFetchResponse.success("")
        try {
            response = this.fetcher.fetch(request, signal)
        } catch (err: Exception) {
            throw toHttpError(method, this.config.sensitiveLogs, request.url, token, err)
        }
        this.resolveTransportRace(method, token, request.url, requestPayload, response, signal)
    }

    private func resolveTransportRace(method: String, token: String, url: String, requestPayload: RequestPayload, response: CoreFetchResponse, signal: CancelSignal): ApiResponse {
        signal.throwIfCancelled()
        let timeoutMillis = this.timeoutConfig().timeoutMillis
        let streamFails = requestPayload.stream.hasError
        let streamMillis = requestPayload.stream.errorAfterMillis

        if (streamFails && streamMillis > 0 && response.delayMillis > 0 && streamMillis <= response.delayMillis && (timeoutMillis <= 0 || streamMillis <= timeoutMillis)) {
            try {
                requestPayload.stream.raiseError()
            } catch (err: Exception) {
                throw toHttpError(method, this.config.sensitiveLogs, url, token, err)
            }
        }

        if (timeoutMillis > 0 && response.delayMillis > timeoutMillis) {
            let seconds = this.config.timeoutSeconds.toString()
            signal.cancelled = true
            signal.reason = "Request to '" + method + "' timed out after " + seconds + " seconds"
            throw toHttpError(method, this.config.sensitiveLogs, url, token, Exception(signal.reason))
        }

        if (response.hasTransportError) {
            throw toHttpError(method, this.config.sensitiveLogs, url, token, response.status, response.statusText, response.transportErrorMessage)
        }

        if (response.hasApiResponse) {
            return response.apiResponse
        }

        if (response.status >= 400) {
            throw toHttpError(method, this.config.sensitiveLogs, url, token, response.status, response.statusText, response.body)
        }
        try {
            return parseTelegramApiResponse(response.body)
        } catch (err: Exception) {
            throw toHttpError(method, this.config.sensitiveLogs, url, token, err)
        }
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

private func parseTelegramApiResponse(body: String): ApiResponse {
    let okValue = jsonFieldValue(body, "ok")
    if (okValue == "true") {
        let result = jsonFieldValue(body, "result")
        if (result.isEmpty()) {
            throw Exception("Could not parse Telegram response JSON: missing result")
        }
        return ApiResponse.success(result)
    }
    if (okValue == "false") {
        let errorCode = parseJsonInt(jsonFieldValue(body, "error_code"))
        let description = parseJsonString(jsonFieldValue(body, "description"))
        let parametersValue = jsonFieldValue(body, "parameters")
        return ApiResponse.failure(errorCode, description, parseResponseParameters(parametersValue))
    }
    throw Exception("Could not parse Telegram response JSON: missing ok")
}

private func parseResponseParameters(value: String): ResponseParameters {
    if (value.isEmpty()) {
        return ResponseParameters()
    }
    let migrateToChatId = parseJsonIntOrDefault(jsonFieldValue(value, "migrate_to_chat_id"), 0)
    let retryAfter = parseJsonIntOrDefault(jsonFieldValue(value, "retry_after"), 0)
    ResponseParameters(migrateToChatId, retryAfter)
}

private func jsonFieldValue(json: String, key: String): String {
    let pattern = "\"" + key + "\""
    let keyIndex = indexOfFrom(json, pattern, 0)
    if (keyIndex < 0) {
        return ""
    }
    var i = keyIndex + pattern.size
    while (i < json.size && isJsonWhitespace(json[i..i + 1])) {
        i += 1
    }
    if (i >= json.size || json[i..i + 1] != ":") {
        return ""
    }
    readJsonValue(json, i + 1)
}

private func readJsonValue(json: String, startIndex: Int64): String {
    var i = startIndex
    while (i < json.size && isJsonWhitespace(json[i..i + 1])) {
        i += 1
    }
    if (i >= json.size) {
        return ""
    }
    let first = json[i..i + 1]
    if (first == "\"") {
        return readJsonStringValue(json, i)
    }
    if (first == "{" || first == "[") {
        return readJsonCompositeValue(json, i)
    }
    let end = readJsonPrimitiveEnd(json, i)
    trimJson(json[i..end])
}

private func readJsonStringValue(json: String, startIndex: Int64): String {
    var i = startIndex + 1
    var escaped = false
    while (i < json.size) {
        let ch = json[i..i + 1]
        if (escaped) {
            escaped = false
        } else if (ch == "\\") {
            escaped = true
        } else if (ch == "\"") {
            return json[startIndex..i + 1]
        }
        i += 1
    }
    throw Exception("Could not parse Telegram response JSON: unterminated string")
}

private func readJsonCompositeValue(json: String, startIndex: Int64): String {
    var i = startIndex
    var depth: Int64 = 0
    var inString = false
    var escaped = false
    while (i < json.size) {
        let ch = json[i..i + 1]
        if (inString) {
            if (escaped) {
                escaped = false
            } else if (ch == "\\") {
                escaped = true
            } else if (ch == "\"") {
                inString = false
            }
        } else if (ch == "\"") {
            inString = true
        } else if (ch == "{" || ch == "[") {
            depth += 1
        } else if (ch == "}" || ch == "]") {
            depth -= 1
            if (depth == 0) {
                return json[startIndex..i + 1]
            }
        }
        i += 1
    }
    throw Exception("Could not parse Telegram response JSON: unterminated composite value")
}

private func readJsonPrimitiveEnd(json: String, startIndex: Int64): Int64 {
    var i = startIndex
    while (i < json.size) {
        let ch = json[i..i + 1]
        if (ch == "," || ch == "}" || ch == "]") {
            return i
        }
        i += 1
    }
    i
}

private func parseJsonString(value: String): String {
    let trimmed = trimJson(value)
    if (trimmed.size < 2 || trimmed[0..1] != "\"" || trimmed[trimmed.size - 1..trimmed.size] != "\"") {
        return trimmed
    }
    var out = ""
    var i: Int64 = 1
    while (i < trimmed.size - 1) {
        let ch = trimmed[i..i + 1]
        if (ch == "\\" && i + 1 < trimmed.size - 1) {
            let next = trimmed[i + 1..i + 2]
            if (next == "n") {
                out += "\n"
            } else if (next == "r") {
                out += "\r"
            } else if (next == "t") {
                out += "\t"
            } else {
                out += next
            }
            i += 2
        } else {
            out += ch
            i += 1
        }
    }
    out
}

private func parseJsonIntOrDefault(value: String, fallback: Int64): Int64 {
    if (value.isEmpty()) {
        return fallback
    }
    parseJsonInt(value)
}

private func parseJsonInt(value: String): Int64 {
    let trimmed = trimJson(value)
    if (trimmed.isEmpty()) {
        throw Exception("Could not parse Telegram response JSON: missing integer")
    }
    var sign: Int64 = 1
    var i: Int64 = 0
    if (trimmed[0..1] == "-") {
        sign = -1
        i = 1
    }
    var out: Int64 = 0
    var hasDigit = false
    while (i < trimmed.size) {
        let digit = digitValue(trimmed[i..i + 1])
        if (digit < 0) {
            break
        }
        hasDigit = true
        out = out * 10 + digit
        i += 1
    }
    if (!hasDigit) {
        throw Exception("Could not parse Telegram response JSON: invalid integer")
    }
    out * sign
}

private func digitValue(ch: String): Int64 {
    if (ch == "0") { return 0 }
    if (ch == "1") { return 1 }
    if (ch == "2") { return 2 }
    if (ch == "3") { return 3 }
    if (ch == "4") { return 4 }
    if (ch == "5") { return 5 }
    if (ch == "6") { return 6 }
    if (ch == "7") { return 7 }
    if (ch == "8") { return 8 }
    if (ch == "9") { return 9 }
    -1
}

private func trimJson(value: String): String {
    var start: Int64 = 0
    var end = value.size
    while (start < end && isJsonWhitespace(value[start..start + 1])) {
        start += 1
    }
    while (end > start && isJsonWhitespace(value[end - 1..end])) {
        end -= 1
    }
    value[start..end]
}

private func isJsonWhitespace(ch: String): Bool {
    ch == " " || ch == "\n" || ch == "\r" || ch == "\t"
}

private func indexOfFrom(value: String, needle: String, startIndex: Int64): Int64 {
    if (needle.isEmpty()) {
        return startIndex
    }
    var i = startIndex
    while (i + needle.size <= value.size) {
        if (value[i..i + needle.size] == needle) {
            return i
        }
        i += 1
    }
    -1
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
