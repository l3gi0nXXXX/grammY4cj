package grammy4cj.core

import std.collection.ArrayList

import grammy4cj.types.Chat
import grammy4cj.types.InputFile
import grammy4cj.types.Message
import grammy4cj.types.Update
import grammy4cj.types.User

public type ApiBuildUrl = (String, String, String, String) -> String
public type WebhookReplyPredicate = (String) -> Bool

public class ApiResult<T> {
    public let body: String
    public let value: T
    public let result: T
    public let typeTrace: String
    public let fields: ArrayList<PayloadField> = ArrayList<PayloadField>()

    public init(body: String, value: T, typeTrace: String) {
        this.body = body
        this.value = value
        this.result = value
        this.typeTrace = typeTrace
    }

    public init(body: String, value: T, typeTrace: String, tracePayload: Payload) {
        this.body = body
        this.value = value
        this.result = value
        this.typeTrace = typeTrace
        for (field in tracePayload.fields) {
            this.fields.add(field)
        }
    }
}

public class ApiClientOptions {
    public let apiRoot: String
    public let environment: String
    public let timeoutSeconds: Int64
    public let sensitiveLogs: Bool
    public let canUseWebhookReply: Bool
    public let buildUrlFn: ApiBuildUrl
    public let canUseWebhookReplyFn: WebhookReplyPredicate
    public let baseFetchConfig: BaseFetchConfig

    public init() {
        this.apiRoot = "https://api.telegram.org"
        this.environment = "prod"
        this.timeoutSeconds = 500
        this.sensitiveLogs = false
        this.canUseWebhookReply = false
        this.buildUrlFn = defaultBuildUrl
        this.canUseWebhookReplyFn = rejectWebhookReply
        this.baseFetchConfig = defaultBaseFetchConfig(this.apiRoot)
    }

    public init(apiRoot: String, environment: String) {
        validateApiRoot(apiRoot)
        this.apiRoot = apiRoot
        this.environment = environment
        this.timeoutSeconds = 500
        this.sensitiveLogs = false
        this.canUseWebhookReply = false
        this.buildUrlFn = defaultBuildUrl
        this.canUseWebhookReplyFn = rejectWebhookReply
        this.baseFetchConfig = defaultCoreBaseFetchConfig(this.apiRoot)
    }

    public init(apiRoot: String, environment: String, timeoutSeconds: Int64, sensitiveLogs: Bool, canUseWebhookReply: Bool) {
        validateApiRoot(apiRoot)
        this.apiRoot = apiRoot
        this.environment = environment
        this.timeoutSeconds = timeoutSeconds
        this.sensitiveLogs = sensitiveLogs
        this.canUseWebhookReply = canUseWebhookReply
        this.buildUrlFn = defaultBuildUrl
        this.canUseWebhookReplyFn = if (canUseWebhookReply) {
            allowWebhookReply
        } else {
            rejectWebhookReply
        }
        this.baseFetchConfig = defaultCoreBaseFetchConfig(this.apiRoot)
    }

    public init(
        apiRoot: String,
        environment: String,
        timeoutSeconds: Int64,
        sensitiveLogs: Bool,
        canUseWebhookReply: WebhookReplyPredicate,
        buildUrl: ApiBuildUrl,
        baseFetchConfig: BaseFetchConfig
    ) {
        validateApiRoot(apiRoot)
        this.apiRoot = apiRoot
        this.environment = environment
        this.timeoutSeconds = timeoutSeconds
        this.sensitiveLogs = sensitiveLogs
        this.canUseWebhookReply = true
        this.buildUrlFn = buildUrl
        this.canUseWebhookReplyFn = canUseWebhookReply
        this.baseFetchConfig = mergeBaseFetchConfig(this.apiRoot, baseFetchConfig)
    }

    public func buildUrl(token: String, method: String): String {
        this.buildUrlFn(this.apiRoot, token, method, this.environment)
    }

    public func canUseWebhookReplyFor(method: String): Bool {
        this.canUseWebhookReplyFn(method)
    }

    public func baseFetchConfigSummary(): String {
        this.baseFetchConfig.summary()
    }
}

private func defaultBuildUrl(root: String, token: String, method: String, environment: String): String {
    let prefix = if (environment == "test") {
        "test/"
    } else {
        ""
    }
    root + "/bot" + token + "/" + prefix + method
}

private func defaultBaseFetchConfig(apiRoot: String): BaseFetchConfig {
    defaultCoreBaseFetchConfig(apiRoot)
}

private func validateApiRoot(apiRoot: String): Unit {
    if (apiRoot.endsWith("/")) {
        let suggested = apiRoot[0..apiRoot.size - 1]
        throw Exception("Remove the trailing '/' from the 'apiRoot' option (use '" + suggested + "' instead of '" + apiRoot + "')")
    }
}

private func rejectWebhookReply(_method: String): Bool {
    false
}

private func allowWebhookReply(_method: String): Bool {
    true
}

private func clonePayloadField(field: PayloadField): PayloadField {
    let copied = PayloadField(
        field.key,
        field.value,
        field.isNull,
        field.isInputFile,
        field.filename,
        field.sourceKind,
        field.valueKind
    )
    copied.inputFile = field.inputFile
    for (child in field.children) {
        copied.children.add(clonePayloadField(child))
    }
    copied
}

private func mergeOtherPayload(payload: Payload, other: Payload): Payload {
    for (field in other.fields) {
        payload.fields.add(clonePayloadField(field))
    }
    payload
}

public func tracePayload(method: String, payload: Payload): Payload {
    Payload("").addValue("__method", method).addValue("__payload", createJsonPayload(payload).body)
}

private func tracedApiResult<T>(trace: Payload, value: T, typeTrace: String): ApiResult<T> {
    ApiResult<T>(trace.body, value, typeTrace, trace)
}

private func apiParseRawBody(body: String): String {
    let result = apiJsonFieldValue(body, "result")
    if (result == "") {
        return body
    }
    let trimmed = apiTrimJson(result)
    if (trimmed.size >= 2 && trimmed[0..1] == "\"" && trimmed[trimmed.size - 1..trimmed.size] == "\"") {
        return apiParseJsonString(trimmed)
    }
    trimmed
}

private func apiJsonFieldValue(json: String, key: String): String {
    let pattern = "\"" + key + "\""
    let keyIndex = apiIndexOfFrom(json, pattern, 0)
    if (keyIndex < 0) {
        return ""
    }
    var i = keyIndex + pattern.size
    while (i < json.size && apiIsJsonWhitespace(json[i..i + 1])) {
        i += 1
    }
    if (i >= json.size || json[i..i + 1] != ":") {
        return ""
    }
    apiReadJsonValue(json, i + 1)
}

private func apiReadJsonValue(json: String, startIndex: Int64): String {
    var i = startIndex
    while (i < json.size && apiIsJsonWhitespace(json[i..i + 1])) {
        i += 1
    }
    if (i >= json.size) {
        return ""
    }
    let first = json[i..i + 1]
    if (first == "\"") {
        return apiReadJsonStringValue(json, i)
    }
    if (first == "{" || first == "[") {
        return apiReadJsonCompositeValue(json, i)
    }
    let end = apiReadJsonPrimitiveEnd(json, i)
    apiTrimJson(json[i..end])
}

private func apiReadJsonStringValue(json: String, startIndex: Int64): String {
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
    ""
}

private func apiReadJsonCompositeValue(json: String, startIndex: Int64): String {
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
    ""
}

private func apiReadJsonPrimitiveEnd(json: String, startIndex: Int64): Int64 {
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

private func apiParseJsonString(value: String): String {
    let trimmed = apiTrimJson(value)
    if (trimmed.size < 2 || trimmed[0..1] != "\"" || trimmed[trimmed.size - 1..trimmed.size] != "\"") {
        return trimmed
    }
    var out = ""
    var i: Int64 = 1
    while (i < trimmed.size - 1) {
        let ch = trimmed[i..i + 1]
        if (ch == "\\" && i + 1 < trimmed.size - 1) {
            out += trimmed[i + 1..i + 2]
            i += 2
        } else {
            out += ch
            i += 1
        }
    }
    out
}

private func apiParseJsonBoolOrDefault(value: String, fallback: Bool): Bool {
    let trimmed = apiTrimJson(value)
    if (trimmed == "true") {
        return true
    }
    if (trimmed == "false") {
        return false
    }
    fallback
}

private func apiParseJsonIntOrDefault(value: String, fallback: Int64): Int64 {
    let trimmed = apiTrimJson(value)
    if (trimmed.isEmpty()) {
        return fallback
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
        let digit = apiDigitValue(trimmed[i..i + 1])
        if (digit < 0) {
            break
        }
        hasDigit = true
        out = out * 10 + digit
        i += 1
    }
    if (!hasDigit) {
        return fallback
    }
    out * sign
}

private func apiDigitValue(ch: String): Int64 {
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

private func apiTrimJson(value: String): String {
    var start: Int64 = 0
    var end = value.size
    while (start < end && apiIsJsonWhitespace(value[start..start + 1])) {
        start += 1
    }
    while (end > start && apiIsJsonWhitespace(value[end - 1..end])) {
        end -= 1
    }
    value[start..end]
}

private func apiIsJsonWhitespace(ch: String): Bool {
    ch == " " || ch == "\n" || ch == "\r" || ch == "\t"
}

private func apiIndexOfFrom(value: String, needle: String, startIndex: Int64): Int64 {
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

private func apiParseUser(body: String): User {
    User(
        apiParseJsonIntOrDefault(apiJsonFieldValue(body, "id"), 0),
        apiParseJsonBoolOrDefault(apiJsonFieldValue(body, "is_bot"), false),
        apiParseJsonString(apiJsonFieldValue(body, "first_name")),
        apiParseJsonString(apiJsonFieldValue(body, "username"))
    )
}

private func apiParseMessage(body: String): Message {
    Message(
        apiParseJsonIntOrDefault(apiJsonFieldValue(body, "message_id"), 0),
        Chat(apiParseJsonIntOrDefault(apiJsonFieldValue(apiJsonFieldValue(body, "chat"), "id"), 0), apiParseJsonString(apiJsonFieldValue(apiJsonFieldValue(body, "chat"), "type"))),
        apiParseJsonString(apiJsonFieldValue(body, "text"))
    )
}

private func apiParseUpdates(body: String): ArrayList<Update> {
    let updates = ArrayList<Update>()
    var i: Int64 = 0
    while (i < body.size) {
        if (body[i..i + 1] == "{") {
            let object = apiReadJsonCompositeValue(body, i)
            if (!object.isEmpty()) {
                updates.add(Update(apiParseJsonIntOrDefault(apiJsonFieldValue(object, "update_id"), 0), ""))
                i += object.size
                continue
            }
        }
        i += 1
    }
    updates
}

private func payloadHasField(payload: Payload, key: String): Bool {
    for (field in payload.fields) {
        if (field.key == key && !field.isNull && field.valueKind != "null") {
            return true
        }
    }
    false
}

private func addChatId(payload: Payload, chatId: Int64): Payload {
    payload.addInt("chat_id", chatId)
}

private func addChatId(payload: Payload, chatId: String): Payload {
    payload.addValue("chat_id", chatId)
}

private func addPollOptions(payload: Payload, options: Array<String>): Payload {
    let array = payload.addArray("options")
    for (option in options) {
        let item = array.addObjectItem()
        item.addValue("text", option)
    }
    payload
}

private func requiredTextPayload(chatId: Int64, text: String): Payload {
    let payload = Payload("")
    addChatId(payload, chatId)
    payload.addValue("text", text)
    payload
}

private func requiredTextPayload(chatId: String, text: String): Payload {
    let payload = Payload("")
    addChatId(payload, chatId)
    payload.addValue("text", text)
    payload
}

private func mediaPayload(chatId: Int64, field: String, value: String): Payload {
    let payload = Payload("")
    addChatId(payload, chatId)
    payload.addValue(field, value)
    payload
}

private func mediaPayload(chatId: String, field: String, value: String): Payload {
    let payload = Payload("")
    addChatId(payload, chatId)
    payload.addValue(field, value)
    payload
}

private func mediaPayload(chatId: Int64, field: String, value: InputFile): Payload {
    let payload = Payload("")
    addChatId(payload, chatId)
    payload.addFile(field, value)
    payload
}

private func mediaPayload(chatId: String, field: String, value: InputFile): Payload {
    let payload = Payload("")
    addChatId(payload, chatId)
    payload.addFile(field, value)
    payload
}

public class ApiWrapperPayloadBuilder {
    public let methodName: String
    public let payload: Payload

    public init(methodName: String) {
        this.methodName = methodName
        this.payload = Payload("")
    }

    public func setString(field: String, value: String): ApiWrapperPayloadBuilder {
        this.payload.addValue(field, value)
        this
    }

    public func setInt(field: String, value: Int64): ApiWrapperPayloadBuilder {
        this.payload.addInt(field, value)
        this
    }

    public func setBool(field: String, value: Bool): ApiWrapperPayloadBuilder {
        this.payload.addBool(field, value)
        this
    }

    public func setRawJson(field: String, value: String): ApiWrapperPayloadBuilder {
        this.payload.addRawJson(field, value)
        this
    }

    public func setFile(field: String, value: InputFile): ApiWrapperPayloadBuilder {
        this.payload.addFile(field, value)
        this
    }

    public func build(): Payload {
        let signature = apiWrapperSignatureTraceFor(this.methodName)
        if (signature.requiredParameterTrace != "") {
            for (field in signature.requiredParameterTrace.split(",")) {
                if (field != "" && !payloadHasField(this.payload, field)) {
                    throw Exception(
                        "Missing required API wrapper parameter '" + field +
                        "' for " + this.methodName
                    )
                }
            }
        }
        this.payload
    }
}

public func apiWrapperMinimalPayloadFor(publicMethodName: String): Payload {
    let builder = ApiWrapperPayloadBuilder(publicMethodName)
    let signature = apiWrapperSignatureTraceFor(publicMethodName)
    if (signature.requiredParameterTrace != "") {
        for (field in signature.requiredParameterTrace.split(",")) {
            if (field != "") {
                builder.setString(field, field + "_value")
            }
        }
    }
    builder.build()
}

public func apiWrapperMinimalPayloadGoldenRows(): ArrayList<String> {
    let rows = ArrayList<String>()
    for (trace in apiWrapperSignatureTraces()) {
        rows.add(trace.publicMethodName + "~" + createJsonPayload(apiWrapperMinimalPayloadFor(trace.publicMethodName)).body)
    }
    rows
}

public class ApiConfig {
    public let options: ApiClientOptions
    private let client: ApiClient

    public init(client: ApiClient, options: ApiClientOptions) {
        this.client = client
        this.options = options
    }

    public func use(transformerName: String): ApiConfig {
        this.client.use(transformerName)
        this
    }

    public func use(transformer: Transformer): ApiConfig {
        this.client.use(transformer)
        this
    }

    public func use(transformerName: String, transformer: Transformer): ApiConfig {
        this.client.use(transformerName, transformer)
        this
    }

    public func installedTransformers(): Array<String> {
        this.client.installedTransformers.toArray()
    }

    public func installedTransformerFunctions(): Array<Transformer> {
        this.client.installedTransformerFunctions.toArray()
    }

    public func buildUrl(token: String, method: String): String {
        this.options.buildUrl(token, method)
    }

    public func canUseWebhookReplyFor(method: String): Bool {
        this.options.canUseWebhookReplyFor(method)
    }

    public func baseFetchConfigSummary(): String {
        this.options.baseFetchConfigSummary()
    }

    public func copyTransformersTo(target: ApiClient): Unit {
        let _ = this.client.copyInstalledTransformersTo(target)
    }
}

public class Api {
    public let token: String
    public let options: ApiClientOptions
    public let config: ApiConfig
    public let raw: RawApiFacade
    public let installedTransformers: ArrayList<String>
    private let client: ApiClient
    private let traceCompatibilityMode: Bool

    public init(token: String) {
        this.token = token
        this.options = ApiClientOptions()
        this.client = ApiClient(this.options)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
        this.config = ApiConfig(this.client, this.options)
        this.traceCompatibilityMode = false
    }

    public init(token: String, options: ApiClientOptions) {
        this.token = token
        this.options = options
        this.client = ApiClient(options)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
        this.config = ApiConfig(this.client, this.options)
        this.traceCompatibilityMode = false
    }

    public init(token: String, config: ApiConfig) {
        this.token = token
        this.options = config.options
        this.client = ApiClient(this.options)
        config.copyTransformersTo(this.client)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
        this.config = ApiConfig(this.client, this.options)
        this.traceCompatibilityMode = false
    }

    public init(token: String, config: ApiConfig, webhookReplyEnvelope: WebhookReplyEnvelope) {
        this.token = token
        this.options = config.options
        this.client = ApiClient(this.options, webhookReplyEnvelope)
        config.copyTransformersTo(this.client)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
        this.config = ApiConfig(this.client, this.options)
        this.traceCompatibilityMode = false
    }

    public init(token: String, config: ApiConfig, fetcher: CoreFetch) {
        this.token = token
        this.options = config.options
        this.client = ApiClient(this.options, fetcher)
        config.copyTransformersTo(this.client)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
        this.config = ApiConfig(this.client, this.options)
        this.traceCompatibilityMode = false
    }

    public init(token: String, options: ApiClientOptions, fetcher: CoreFetch) {
        this.token = token
        this.options = options
        this.client = ApiClient(options, fetcher)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
        this.config = ApiConfig(this.client, this.options)
        this.traceCompatibilityMode = false
    }

    public init(token: String, options: ApiClientOptions, traceCompatibilityMode: Bool) {
        this.token = token
        this.options = options
        this.client = ApiClient(options)
        this.raw = RawApiFacade(token, this.client)
        this.installedTransformers = this.client.installedTransformers
        this.config = ApiConfig(this.client, this.options)
        this.traceCompatibilityMode = traceCompatibilityMode
    }

    public static func trace(token: String): Api {
        Api(token, ApiClientOptions(), true)
    }

    public static func trace(token: String, config: ApiClientOptions): Api {
        Api(token, config, true)
    }

    public func endpointFor(method: String): String {
        this.options.buildUrl(this.token, method)
    }

    public func use(transformerName: String): Api {
        this.client.use(transformerName)
        this
    }

    public func use(transformer: Transformer): Api {
        this.client.use(transformer)
        this
    }

    public func use(transformerName: String, transformer: Transformer): Api {
        this.client.use(transformerName, transformer)
        this
    }

    public func call(method: String, payload: Payload): Payload {
        if (this.traceCompatibilityMode) {
            return tracePayload(method, payload)
        }
        Payload(this.raw.call(method, payload))
    }

    public func call(method: String, payload: Payload, signal: CancelSignal): Payload {
        if (this.traceCompatibilityMode) {
            signal.throwIfCancelled()
            return tracePayload(method, payload)
        }
        Payload(this.raw.call(method, payload, signal))
    }

    public func callResult(method: String, payload: Payload): String {
        this.raw.call(method, payload)
    }

    public func callResult(method: String, payload: Payload, signal: CancelSignal): String {
        this.raw.call(method, payload, signal)
    }

    private func zeroArgResult(method: String, typeTrace: String): ApiResult<String> {
        if (this.traceCompatibilityMode) {
            return tracedApiResult<String>(tracePayload(method, Payload("{}")), "", typeTrace)
        }
        let body = this.raw.call(method, Payload("{}"))
        ApiResult<String>(body, apiParseRawBody(body), typeTrace)
    }

    private func zeroArgResult(method: String, typeTrace: String, signal: CancelSignal): ApiResult<String> {
        if (this.traceCompatibilityMode) {
            signal.throwIfCancelled()
            return tracedApiResult<String>(tracePayload(method, Payload("{}")), "", typeTrace)
        }
        let body = this.raw.call(method, Payload("{}"), signal)
        ApiResult<String>(body, apiParseRawBody(body), typeTrace)
    }

    public func getUpdates(): ApiResult<ArrayList<Update>> {
        if (this.traceCompatibilityMode) {
            return tracedApiResult<ArrayList<Update>>(tracePayload("getUpdates", Payload("{}")), ArrayList<Update>(), "Update[]")
        }
        let body = this.raw.call("getUpdates", Payload("{}"))
        ApiResult<ArrayList<Update>>(body, apiParseUpdates(body), "Update[]")
    }

    public func getUpdates(signal: CancelSignal): ApiResult<ArrayList<Update>> {
        if (this.traceCompatibilityMode) {
            signal.throwIfCancelled()
            return tracedApiResult<ArrayList<Update>>(tracePayload("getUpdates", Payload("{}")), ArrayList<Update>(), "Update[]")
        }
        let body = this.raw.call("getUpdates", Payload("{}"), signal)
        ApiResult<ArrayList<Update>>(body, apiParseUpdates(body), "Update[]")
    }

    public func getMe(): ApiResult<User> {
        if (this.traceCompatibilityMode) {
            return tracedApiResult<User>(tracePayload("getMe", Payload("{}")), User(), "User")
        }
        let body = this.raw.getMe()
        ApiResult<User>(body, apiParseUser(body), "User")
    }

    public func getMe(signal: CancelSignal): ApiResult<User> {
        if (this.traceCompatibilityMode) {
            signal.throwIfCancelled()
            return tracedApiResult<User>(tracePayload("getMe", Payload("{}")), User(), "User")
        }
        let body = this.raw.call("getMe", Payload("{}"), signal)
        ApiResult<User>(body, apiParseUser(body), "User")
    }

    public func getWebhookInfo(): ApiResult<String> {
        this.zeroArgResult("getWebhookInfo", "WebhookInfo")
    }

    public func getWebhookInfo(signal: CancelSignal): ApiResult<String> {
        this.zeroArgResult("getWebhookInfo", "WebhookInfo", signal)
    }

    public func logOut(): ApiResult<String> {
        this.zeroArgResult("logOut", "true")
    }

    public func logOut(signal: CancelSignal): ApiResult<String> {
        this.zeroArgResult("logOut", "true", signal)
    }

    public func close(): ApiResult<String> {
        this.zeroArgResult("close", "true")
    }

    public func close(signal: CancelSignal): ApiResult<String> {
        this.zeroArgResult("close", "true", signal)
    }

    public func getForumTopicIconStickers(): ApiResult<String> {
        this.zeroArgResult("getForumTopicIconStickers", "Sticker[]")
    }

    public func getForumTopicIconStickers(signal: CancelSignal): ApiResult<String> {
        this.zeroArgResult("getForumTopicIconStickers", "Sticker[]", signal)
    }

    public func getAvailableGifts(): ApiResult<String> {
        this.zeroArgResult("getAvailableGifts", "Gifts")
    }

    public func getAvailableGifts(signal: CancelSignal): ApiResult<String> {
        this.zeroArgResult("getAvailableGifts", "Gifts", signal)
    }

    public func getMyStarBalance(): ApiResult<String> {
        this.zeroArgResult("getMyStarBalance", "StarAmount")
    }

    public func getMyStarBalance(signal: CancelSignal): ApiResult<String> {
        this.zeroArgResult("getMyStarBalance", "StarAmount", signal)
    }

    public func removeMyProfilePhoto(): ApiResult<String> {
        this.zeroArgResult("removeMyProfilePhoto", "true")
    }

    public func removeMyProfilePhoto(signal: CancelSignal): ApiResult<String> {
        this.zeroArgResult("removeMyProfilePhoto", "true", signal)
    }

    public func sendMessage(chatId: Int64, text: String): ApiResult<Message> {
        let payload = requiredTextPayload(chatId, text)
        if (this.traceCompatibilityMode) {
            return tracedApiResult<Message>(tracePayload("sendMessage", payload), apiParseMessage(createJsonPayload(payload).body), "Message.TextMessage")
        }
        let body = this.raw.call("sendMessage", payload)
        ApiResult<Message>(body, apiParseMessage(body), "Message.TextMessage")
    }

    public func sendMessage(chatId: String, text: String): ApiResult<Message> {
        let payload = requiredTextPayload(chatId, text)
        if (this.traceCompatibilityMode) {
            return tracedApiResult<Message>(tracePayload("sendMessage", payload), apiParseMessage(createJsonPayload(payload).body), "Message.TextMessage")
        }
        let body = this.raw.call("sendMessage", payload)
        ApiResult<Message>(body, apiParseMessage(body), "Message.TextMessage")
    }

    public func sendMessage(chatId: Int64, text: String, other: Payload): ApiResult<Message> {
        let payload = mergeOtherPayload(requiredTextPayload(chatId, text), other)
        if (this.traceCompatibilityMode) {
            return tracedApiResult<Message>(tracePayload("sendMessage", payload), apiParseMessage(createJsonPayload(payload).body), "Message.TextMessage")
        }
        let body = this.raw.call("sendMessage", payload)
        ApiResult<Message>(body, apiParseMessage(body), "Message.TextMessage")
    }

    public func sendMessage(chatId: String, text: String, other: Payload): ApiResult<Message> {
        let payload = mergeOtherPayload(requiredTextPayload(chatId, text), other)
        if (this.traceCompatibilityMode) {
            return tracedApiResult<Message>(tracePayload("sendMessage", payload), apiParseMessage(createJsonPayload(payload).body), "Message.TextMessage")
        }
        let body = this.raw.call("sendMessage", payload)
        ApiResult<Message>(body, apiParseMessage(body), "Message.TextMessage")
    }

    public func sendMessage(chatId: Int64, text: String, other: Payload, signal: CancelSignal): ApiResult<Message> {
        let payload = mergeOtherPayload(requiredTextPayload(chatId, text), other)
        if (this.traceCompatibilityMode) {
            signal.throwIfCancelled()
            return tracedApiResult<Message>(tracePayload("sendMessage", payload), apiParseMessage(createJsonPayload(payload).body), "Message.TextMessage")
        }
        let body = this.raw.call("sendMessage", payload, signal)
        ApiResult<Message>(body, apiParseMessage(body), "Message.TextMessage")
    }

    public func sendMessage(chatId: String, text: String, other: Payload, signal: CancelSignal): ApiResult<Message> {
        let payload = mergeOtherPayload(requiredTextPayload(chatId, text), other)
        if (this.traceCompatibilityMode) {
            signal.throwIfCancelled()
            return tracedApiResult<Message>(tracePayload("sendMessage", payload), apiParseMessage(createJsonPayload(payload).body), "Message.TextMessage")
        }
        let body = this.raw.call("sendMessage", payload, signal)
        ApiResult<Message>(body, apiParseMessage(body), "Message.TextMessage")
    }

    public func sendMessage(chatId: Int64, text: String, signal: CancelSignal): ApiResult<Message> {
        let payload = requiredTextPayload(chatId, text)
        if (this.traceCompatibilityMode) {
            signal.throwIfCancelled()
            return tracedApiResult<Message>(tracePayload("sendMessage", payload), apiParseMessage(createJsonPayload(payload).body), "Message.TextMessage")
        }
        let body = this.raw.call("sendMessage", payload, signal)
        ApiResult<Message>(body, apiParseMessage(body), "Message.TextMessage")
    }

    public func sendMessage(chatId: String, text: String, signal: CancelSignal): ApiResult<Message> {
        let payload = requiredTextPayload(chatId, text)
        if (this.traceCompatibilityMode) {
            signal.throwIfCancelled()
            return tracedApiResult<Message>(tracePayload("sendMessage", payload), apiParseMessage(createJsonPayload(payload).body), "Message.TextMessage")
        }
        let body = this.raw.call("sendMessage", payload, signal)
        ApiResult<Message>(body, apiParseMessage(body), "Message.TextMessage")
    }

    public func sendPhoto(chatId: Int64, photo: String): Payload { this.sendPhoto(mediaPayload(chatId, "photo", photo)) }
    public func sendPhoto(chatId: String, photo: String): Payload { this.sendPhoto(mediaPayload(chatId, "photo", photo)) }
    public func sendPhoto(chatId: Int64, photo: InputFile): Payload { this.sendPhoto(mediaPayload(chatId, "photo", photo)) }
    public func sendPhoto(chatId: String, photo: InputFile): Payload { this.sendPhoto(mediaPayload(chatId, "photo", photo)) }
    public func sendPhoto(chatId: Int64, photo: String, other: Payload): Payload { this.sendPhoto(mergeOtherPayload(mediaPayload(chatId, "photo", photo), other)) }
    public func sendPhoto(chatId: String, photo: String, other: Payload): Payload { this.sendPhoto(mergeOtherPayload(mediaPayload(chatId, "photo", photo), other)) }

    public func sendAudio(chatId: Int64, audio: String): Payload { this.sendAudio(mediaPayload(chatId, "audio", audio)) }
    public func sendAudio(chatId: String, audio: String): Payload { this.sendAudio(mediaPayload(chatId, "audio", audio)) }
    public func sendAudio(chatId: Int64, audio: InputFile): Payload { this.sendAudio(mediaPayload(chatId, "audio", audio)) }
    public func sendAudio(chatId: String, audio: InputFile): Payload { this.sendAudio(mediaPayload(chatId, "audio", audio)) }

    public func sendDocument(chatId: Int64, document: String): Payload { this.sendDocument(mediaPayload(chatId, "document", document)) }
    public func sendDocument(chatId: String, document: String): Payload { this.sendDocument(mediaPayload(chatId, "document", document)) }
    public func sendDocument(chatId: Int64, document: InputFile): Payload { this.sendDocument(mediaPayload(chatId, "document", document)) }
    public func sendDocument(chatId: String, document: InputFile): Payload { this.sendDocument(mediaPayload(chatId, "document", document)) }

    public func sendVideo(chatId: Int64, video: String): Payload { this.sendVideo(mediaPayload(chatId, "video", video)) }
    public func sendVideo(chatId: String, video: String): Payload { this.sendVideo(mediaPayload(chatId, "video", video)) }
    public func sendVideo(chatId: Int64, video: InputFile): Payload { this.sendVideo(mediaPayload(chatId, "video", video)) }
    public func sendVideo(chatId: String, video: InputFile): Payload { this.sendVideo(mediaPayload(chatId, "video", video)) }

    public func sendAnimation(chatId: Int64, animation: String): Payload { this.sendAnimation(mediaPayload(chatId, "animation", animation)) }
    public func sendAnimation(chatId: String, animation: String): Payload { this.sendAnimation(mediaPayload(chatId, "animation", animation)) }
    public func sendAnimation(chatId: Int64, animation: InputFile): Payload { this.sendAnimation(mediaPayload(chatId, "animation", animation)) }
    public func sendAnimation(chatId: String, animation: InputFile): Payload { this.sendAnimation(mediaPayload(chatId, "animation", animation)) }

    public func sendVoice(chatId: Int64, voice: String): Payload { this.sendVoice(mediaPayload(chatId, "voice", voice)) }
    public func sendVoice(chatId: String, voice: String): Payload { this.sendVoice(mediaPayload(chatId, "voice", voice)) }
    public func sendVoice(chatId: Int64, voice: InputFile): Payload { this.sendVoice(mediaPayload(chatId, "voice", voice)) }
    public func sendVoice(chatId: String, voice: InputFile): Payload { this.sendVoice(mediaPayload(chatId, "voice", voice)) }

    public func sendVideoNote(chatId: Int64, videoNote: String): Payload { this.sendVideoNote(mediaPayload(chatId, "video_note", videoNote)) }
    public func sendVideoNote(chatId: String, videoNote: String): Payload { this.sendVideoNote(mediaPayload(chatId, "video_note", videoNote)) }
    public func sendVideoNote(chatId: Int64, videoNote: InputFile): Payload { this.sendVideoNote(mediaPayload(chatId, "video_note", videoNote)) }
    public func sendVideoNote(chatId: String, videoNote: InputFile): Payload { this.sendVideoNote(mediaPayload(chatId, "video_note", videoNote)) }

    public func sendSticker(chatId: Int64, sticker: String): Payload { this.sendSticker(mediaPayload(chatId, "sticker", sticker)) }
    public func sendSticker(chatId: String, sticker: String): Payload { this.sendSticker(mediaPayload(chatId, "sticker", sticker)) }
    public func sendSticker(chatId: Int64, sticker: InputFile): Payload { this.sendSticker(mediaPayload(chatId, "sticker", sticker)) }
    public func sendSticker(chatId: String, sticker: InputFile): Payload { this.sendSticker(mediaPayload(chatId, "sticker", sticker)) }

    public func sendMediaGroup(chatId: Int64, mediaJson: String): Payload {
        let payload = Payload("")
        addChatId(payload, chatId)
        payload.addRawJson("media", mediaJson)
        this.sendMediaGroup(payload)
    }

    public func sendMediaGroup(chatId: String, mediaJson: String): Payload {
        let payload = Payload("")
        addChatId(payload, chatId)
        payload.addRawJson("media", mediaJson)
        this.sendMediaGroup(payload)
    }

    public func sendPaidMedia(chatId: Int64, starCount: Int64, mediaJson: String): Payload {
        let payload = Payload("")
        addChatId(payload, chatId)
        payload.addInt("star_count", starCount).addRawJson("media", mediaJson)
        this.sendPaidMedia(payload)
    }

    public func sendPoll(chatId: Int64, question: String, options: Array<String>): Payload {
        let payload = Payload("")
        addChatId(payload, chatId)
        payload.addValue("question", question)
        addPollOptions(payload, options)
        this.sendPoll(payload)
    }

    public func sendPoll(chatId: Int64, question: String, options: Array<String>, other: Payload): Payload {
        let payload = Payload("")
        addChatId(payload, chatId)
        payload.addValue("question", question)
        addPollOptions(payload, options)
        this.sendPoll(mergeOtherPayload(payload, other))
    }

    public func editMessageText(chatId: Int64, messageId: Int64, text: String): Payload {
        this.editMessageText(Payload("").addInt("chat_id", chatId).addInt("message_id", messageId).addValue("text", text))
    }

    public func editMessageText(chatId: String, messageId: Int64, text: String): Payload {
        this.editMessageText(Payload("").addValue("chat_id", chatId).addInt("message_id", messageId).addValue("text", text))
    }

    public func editMessageTextInline(inlineMessageId: String, text: String): Payload {
        this.editMessageTextInline(Payload("").addValue("inline_message_id", inlineMessageId).addValue("text", text))
    }

    public func editMessageCaption(chatId: Int64, messageId: Int64, other: Payload): Payload {
        this.editMessageCaption(mergeOtherPayload(Payload("").addInt("chat_id", chatId).addInt("message_id", messageId), other))
    }

    public func editMessageCaptionInline(inlineMessageId: String, other: Payload): Payload {
        this.editMessageCaptionInline(mergeOtherPayload(Payload("").addValue("inline_message_id", inlineMessageId), other))
    }

    public func editMessageMedia(chatId: Int64, messageId: Int64, mediaJson: String): Payload {
        this.editMessageMedia(Payload("").addInt("chat_id", chatId).addInt("message_id", messageId).addRawJson("media", mediaJson))
    }

    public func editMessageMediaInline(inlineMessageId: String, mediaJson: String): Payload {
        this.editMessageMediaInline(Payload("").addValue("inline_message_id", inlineMessageId).addRawJson("media", mediaJson))
    }

    public func editMessageReplyMarkup(chatId: Int64, messageId: Int64, other: Payload): Payload {
        this.editMessageReplyMarkup(mergeOtherPayload(Payload("").addInt("chat_id", chatId).addInt("message_id", messageId), other))
    }

    public func editMessageReplyMarkupInline(inlineMessageId: String, other: Payload): Payload {
        this.editMessageReplyMarkupInline(mergeOtherPayload(Payload("").addValue("inline_message_id", inlineMessageId), other))
    }

    public func banChatMember(chatId: Int64, userId: Int64): Payload { this.banChatMember(Payload("").addInt("chat_id", chatId).addInt("user_id", userId)) }
    public func banChatMember(chatId: String, userId: Int64): Payload { this.banChatMember(Payload("").addValue("chat_id", chatId).addInt("user_id", userId)) }
    public func unbanChatMember(chatId: Int64, userId: Int64): Payload { this.unbanChatMember(Payload("").addInt("chat_id", chatId).addInt("user_id", userId)) }
    public func restrictChatMember(chatId: Int64, userId: Int64, permissionsJson: String): Payload { this.restrictChatMember(Payload("").addInt("chat_id", chatId).addInt("user_id", userId).addRawJson("permissions", permissionsJson)) }
    public func promoteChatMember(chatId: Int64, userId: Int64, other: Payload): Payload { this.promoteChatMember(mergeOtherPayload(Payload("").addInt("chat_id", chatId).addInt("user_id", userId), other)) }
    public func setChatAdministratorCustomTitle(chatId: Int64, userId: Int64, customTitle: String): Payload { this.setChatAdministratorCustomTitle(Payload("").addInt("chat_id", chatId).addInt("user_id", userId).addValue("custom_title", customTitle)) }

    public func createForumTopic(chatId: Int64, name: String): Payload { this.createForumTopic(Payload("").addInt("chat_id", chatId).addValue("name", name)) }
    public func editForumTopic(chatId: Int64, messageThreadId: Int64, other: Payload): Payload { this.editForumTopic(mergeOtherPayload(Payload("").addInt("chat_id", chatId).addInt("message_thread_id", messageThreadId), other)) }
    public func closeForumTopic(chatId: Int64, messageThreadId: Int64): Payload { this.closeForumTopic(Payload("").addInt("chat_id", chatId).addInt("message_thread_id", messageThreadId)) }
    public func reopenForumTopic(chatId: Int64, messageThreadId: Int64): Payload { this.reopenForumTopic(Payload("").addInt("chat_id", chatId).addInt("message_thread_id", messageThreadId)) }
    public func deleteForumTopic(chatId: Int64, messageThreadId: Int64): Payload { this.deleteForumTopic(Payload("").addInt("chat_id", chatId).addInt("message_thread_id", messageThreadId)) }

    public func setBusinessAccountName(businessConnectionId: String, firstName: String): Payload {
        this.setBusinessAccountName(Payload("").addValue("business_connection_id", businessConnectionId).addValue("first_name", firstName))
    }

    public func setBusinessAccountName(businessConnectionId: String, firstName: String, other: Payload): Payload {
        this.setBusinessAccountName(mergeOtherPayload(Payload("").addValue("business_connection_id", businessConnectionId).addValue("first_name", firstName), other))
    }

    public func setBusinessAccountUsername(businessConnectionId: String, username: String): Payload {
        this.setBusinessAccountUsername(Payload("").addValue("business_connection_id", businessConnectionId).addValue("username", username))
    }

    public func setBusinessAccountBio(businessConnectionId: String, bio: String): Payload {
        this.setBusinessAccountBio(Payload("").addValue("business_connection_id", businessConnectionId).addValue("bio", bio))
    }

    public func setBusinessAccountGiftSettings(businessConnectionId: String, showGiftButton: Bool, acceptedGiftTypesJson: String): Payload {
        this.setBusinessAccountGiftSettings(Payload("").addValue("business_connection_id", businessConnectionId).addBool("show_gift_button", showGiftButton).addRawJson("accepted_gift_types", acceptedGiftTypesJson))
    }

    public func transferBusinessAccountStars(businessConnectionId: String, starCount: Int64): Payload {
        this.transferBusinessAccountStars(Payload("").addValue("business_connection_id", businessConnectionId).addInt("star_count", starCount))
    }

    public func readBusinessMessage(businessConnectionId: String, chatId: Int64, messageId: Int64): Payload {
        this.readBusinessMessage(Payload("").addValue("business_connection_id", businessConnectionId).addInt("chat_id", chatId).addInt("message_id", messageId))
    }

    public func getUpdates(payload: Payload): Payload { this.call("getUpdates", payload) }
    public func setWebhook(payload: Payload): Payload { this.call("setWebhook", payload) }
    public func deleteWebhook(payload: Payload): Payload { this.call("deleteWebhook", payload) }
    public func getWebhookInfo(payload: Payload): Payload { this.call("getWebhookInfo", payload) }
    public func getMe(payload: Payload): Payload { this.call("getMe", payload) }
    public func logOut(payload: Payload): Payload { this.call("logOut", payload) }
    public func close(payload: Payload): Payload { this.call("close", payload) }
    public func sendMessage(payload: Payload): Payload { this.call("sendMessage", payload) }
    public func sendMessageDraft(payload: Payload): Payload { this.call("sendMessageDraft", payload) }
    public func forwardMessage(payload: Payload): Payload { this.call("forwardMessage", payload) }
    public func forwardMessages(payload: Payload): Payload { this.call("forwardMessages", payload) }
    public func copyMessage(payload: Payload): Payload { this.call("copyMessage", payload) }
    public func copyMessages(payload: Payload): Payload { this.call("copyMessages", payload) }
    public func sendPhoto(payload: Payload): Payload { this.call("sendPhoto", payload) }
    public func sendAudio(payload: Payload): Payload { this.call("sendAudio", payload) }
    public func sendDocument(payload: Payload): Payload { this.call("sendDocument", payload) }
    public func sendVideo(payload: Payload): Payload { this.call("sendVideo", payload) }
    public func sendAnimation(payload: Payload): Payload { this.call("sendAnimation", payload) }
    public func sendVoice(payload: Payload): Payload { this.call("sendVoice", payload) }
    public func sendVideoNote(payload: Payload): Payload { this.call("sendVideoNote", payload) }
    public func sendMediaGroup(payload: Payload): Payload { this.call("sendMediaGroup", payload) }
    public func sendLocation(payload: Payload): Payload { this.call("sendLocation", payload) }
    public func editMessageLiveLocation(payload: Payload): Payload { this.call("editMessageLiveLocation", payload) }
    public func editMessageLiveLocationInline(payload: Payload): Payload { this.call("editMessageLiveLocation", payload) }
    public func stopMessageLiveLocation(payload: Payload): Payload { this.call("stopMessageLiveLocation", payload) }
    public func stopMessageLiveLocationInline(payload: Payload): Payload { this.call("stopMessageLiveLocation", payload) }
    public func sendPaidMedia(payload: Payload): Payload { this.call("sendPaidMedia", payload) }
    public func sendVenue(payload: Payload): Payload { this.call("sendVenue", payload) }
    public func sendContact(payload: Payload): Payload { this.call("sendContact", payload) }
    public func sendPoll(payload: Payload): Payload { this.call("sendPoll", payload) }
    public func sendChecklist(payload: Payload): Payload { this.call("sendChecklist", payload) }
    public func editMessageChecklist(payload: Payload): Payload { this.call("editMessageChecklist", payload) }
    public func sendDice(payload: Payload): Payload { this.call("sendDice", payload) }
    public func setMessageReaction(payload: Payload): Payload { this.call("setMessageReaction", payload) }
    public func sendChatAction(payload: Payload): Payload { this.call("sendChatAction", payload) }
    public func getUserProfilePhotos(payload: Payload): Payload { this.call("getUserProfilePhotos", payload) }
    public func getUserProfileAudios(payload: Payload): Payload { this.call("getUserProfileAudios", payload) }
    public func setUserEmojiStatus(payload: Payload): Payload { this.call("setUserEmojiStatus", payload) }
    public func getUserChatBoosts(payload: Payload): Payload { this.call("getUserChatBoosts", payload) }
    public func getUserGifts(payload: Payload): Payload { this.call("getUserGifts", payload) }
    public func getChatGifts(payload: Payload): Payload { this.call("getChatGifts", payload) }
    public func getBusinessConnection(payload: Payload): Payload { this.call("getBusinessConnection", payload) }
    public func getFile(payload: Payload): Payload { this.call("getFile", payload) }
    public func kickChatMember(payload: Payload): Payload { this.call("banChatMember", payload) }
    public func banChatMember(payload: Payload): Payload { this.call("banChatMember", payload) }
    public func unbanChatMember(payload: Payload): Payload { this.call("unbanChatMember", payload) }
    public func restrictChatMember(payload: Payload): Payload { this.call("restrictChatMember", payload) }
    public func promoteChatMember(payload: Payload): Payload { this.call("promoteChatMember", payload) }
    public func setChatAdministratorCustomTitle(payload: Payload): Payload { this.call("setChatAdministratorCustomTitle", payload) }
    public func setChatMemberTag(payload: Payload): Payload { this.call("setChatMemberTag", payload) }
    public func banChatSenderChat(payload: Payload): Payload { this.call("banChatSenderChat", payload) }
    public func unbanChatSenderChat(payload: Payload): Payload { this.call("unbanChatSenderChat", payload) }
    public func setChatPermissions(payload: Payload): Payload { this.call("setChatPermissions", payload) }
    public func exportChatInviteLink(payload: Payload): Payload { this.call("exportChatInviteLink", payload) }
    public func createChatInviteLink(payload: Payload): Payload { this.call("createChatInviteLink", payload) }
    public func editChatInviteLink(payload: Payload): Payload { this.call("editChatInviteLink", payload) }
    public func createChatSubscriptionInviteLink(payload: Payload): Payload { this.call("createChatSubscriptionInviteLink", payload) }
    public func editChatSubscriptionInviteLink(payload: Payload): Payload { this.call("editChatSubscriptionInviteLink", payload) }
    public func revokeChatInviteLink(payload: Payload): Payload { this.call("revokeChatInviteLink", payload) }
    public func getManagedBotToken(payload: Payload): Payload { this.call("getManagedBotToken", payload) }
    public func replaceManagedBotToken(payload: Payload): Payload { this.call("replaceManagedBotToken", payload) }
    public func approveChatJoinRequest(payload: Payload): Payload { this.call("approveChatJoinRequest", payload) }
    public func declineChatJoinRequest(payload: Payload): Payload { this.call("declineChatJoinRequest", payload) }
    public func approveSuggestedPost(payload: Payload): Payload { this.call("approveSuggestedPost", payload) }
    public func declineSuggestedPost(payload: Payload): Payload { this.call("declineSuggestedPost", payload) }
    public func setChatPhoto(payload: Payload): Payload { this.call("setChatPhoto", payload) }
    public func deleteChatPhoto(payload: Payload): Payload { this.call("deleteChatPhoto", payload) }
    public func setChatTitle(payload: Payload): Payload { this.call("setChatTitle", payload) }
    public func setChatDescription(payload: Payload): Payload { this.call("setChatDescription", payload) }
    public func pinChatMessage(payload: Payload): Payload { this.call("pinChatMessage", payload) }
    public func unpinChatMessage(payload: Payload): Payload { this.call("unpinChatMessage", payload) }
    public func unpinAllChatMessages(payload: Payload): Payload { this.call("unpinAllChatMessages", payload) }
    public func leaveChat(payload: Payload): Payload { this.call("leaveChat", payload) }
    public func getChat(payload: Payload): Payload { this.call("getChat", payload) }
    public func getChatAdministrators(payload: Payload): Payload { this.call("getChatAdministrators", payload) }
    public func getChatMembersCount(payload: Payload): Payload { this.call("getChatMemberCount", payload) }
    public func getChatMemberCount(payload: Payload): Payload { this.call("getChatMemberCount", payload) }
    public func getChatMember(payload: Payload): Payload { this.call("getChatMember", payload) }
    public func setChatStickerSet(payload: Payload): Payload { this.call("setChatStickerSet", payload) }
    public func deleteChatStickerSet(payload: Payload): Payload { this.call("deleteChatStickerSet", payload) }
    public func getForumTopicIconStickers(payload: Payload): Payload { this.call("getForumTopicIconStickers", payload) }
    public func createForumTopic(payload: Payload): Payload { this.call("createForumTopic", payload) }
    public func editForumTopic(payload: Payload): Payload { this.call("editForumTopic", payload) }
    public func closeForumTopic(payload: Payload): Payload { this.call("closeForumTopic", payload) }
    public func reopenForumTopic(payload: Payload): Payload { this.call("reopenForumTopic", payload) }
    public func deleteForumTopic(payload: Payload): Payload { this.call("deleteForumTopic", payload) }
    public func unpinAllForumTopicMessages(payload: Payload): Payload { this.call("unpinAllForumTopicMessages", payload) }
    public func editGeneralForumTopic(payload: Payload): Payload { this.call("editGeneralForumTopic", payload) }
    public func closeGeneralForumTopic(payload: Payload): Payload { this.call("closeGeneralForumTopic", payload) }
    public func reopenGeneralForumTopic(payload: Payload): Payload { this.call("reopenGeneralForumTopic", payload) }
    public func hideGeneralForumTopic(payload: Payload): Payload { this.call("hideGeneralForumTopic", payload) }
    public func unhideGeneralForumTopic(payload: Payload): Payload { this.call("unhideGeneralForumTopic", payload) }
    public func unpinAllGeneralForumTopicMessages(payload: Payload): Payload { this.call("unpinAllGeneralForumTopicMessages", payload) }
    public func answerCallbackQuery(payload: Payload): Payload { this.call("answerCallbackQuery", payload) }
    public func setMyName(payload: Payload): Payload { this.call("setMyName", payload) }
    public func getMyName(payload: Payload): Payload { this.call("getMyName", payload) }
    public func setMyCommands(payload: Payload): Payload { this.call("setMyCommands", payload) }
    public func deleteMyCommands(payload: Payload): Payload { this.call("deleteMyCommands", payload) }
    public func getMyCommands(payload: Payload): Payload { this.call("getMyCommands", payload) }
    public func setMyDescription(payload: Payload): Payload { this.call("setMyDescription", payload) }
    public func getMyDescription(payload: Payload): Payload { this.call("getMyDescription", payload) }
    public func setMyShortDescription(payload: Payload): Payload { this.call("setMyShortDescription", payload) }
    public func getMyShortDescription(payload: Payload): Payload { this.call("getMyShortDescription", payload) }
    public func setMyProfilePhoto(payload: Payload): Payload { this.call("setMyProfilePhoto", payload) }
    public func removeMyProfilePhoto(payload: Payload): Payload { this.call("removeMyProfilePhoto", payload) }
    public func setChatMenuButton(payload: Payload): Payload { this.call("setChatMenuButton", payload) }
    public func getChatMenuButton(payload: Payload): Payload { this.call("getChatMenuButton", payload) }
    public func setMyDefaultAdministratorRights(payload: Payload): Payload { this.call("setMyDefaultAdministratorRights", payload) }
    public func getMyDefaultAdministratorRights(payload: Payload): Payload { this.call("getMyDefaultAdministratorRights", payload) }
    public func getMyStarBalance(payload: Payload): Payload { this.call("getMyStarBalance", payload) }
    public func editMessageText(payload: Payload): Payload { this.call("editMessageText", payload) }
    public func editMessageTextInline(payload: Payload): Payload { this.call("editMessageText", payload) }
    public func editMessageCaption(payload: Payload): Payload { this.call("editMessageCaption", payload) }
    public func editMessageCaptionInline(payload: Payload): Payload { this.call("editMessageCaption", payload) }
    public func editMessageMedia(payload: Payload): Payload { this.call("editMessageMedia", payload) }
    public func editMessageMediaInline(payload: Payload): Payload { this.call("editMessageMedia", payload) }
    public func editMessageReplyMarkup(payload: Payload): Payload { this.call("editMessageReplyMarkup", payload) }
    public func editMessageReplyMarkupInline(payload: Payload): Payload { this.call("editMessageReplyMarkup", payload) }
    public func stopPoll(payload: Payload): Payload { this.call("stopPoll", payload) }
    public func deleteMessage(payload: Payload): Payload { this.call("deleteMessage", payload) }
    public func deleteMessages(payload: Payload): Payload { this.call("deleteMessages", payload) }
    public func deleteBusinessMessages(payload: Payload): Payload { this.call("deleteBusinessMessages", payload) }
    public func setBusinessAccountName(payload: Payload): Payload { this.call("setBusinessAccountName", payload) }
    public func setBusinessAccountUsername(payload: Payload): Payload { this.call("setBusinessAccountUsername", payload) }
    public func setBusinessAccountBio(payload: Payload): Payload { this.call("setBusinessAccountBio", payload) }
    public func setBusinessAccountProfilePhoto(payload: Payload): Payload { this.call("setBusinessAccountProfilePhoto", payload) }
    public func removeBusinessAccountProfilePhoto(payload: Payload): Payload { this.call("removeBusinessAccountProfilePhoto", payload) }
    public func setBusinessAccountGiftSettings(payload: Payload): Payload { this.call("setBusinessAccountGiftSettings", payload) }
    public func getBusinessAccountStarBalance(payload: Payload): Payload { this.call("getBusinessAccountStarBalance", payload) }
    public func transferBusinessAccountStars(payload: Payload): Payload { this.call("transferBusinessAccountStars", payload) }
    public func getBusinessAccountGifts(payload: Payload): Payload { this.call("getBusinessAccountGifts", payload) }
    public func convertGiftToStars(payload: Payload): Payload { this.call("convertGiftToStars", payload) }
    public func upgradeGift(payload: Payload): Payload { this.call("upgradeGift", payload) }
    public func transferGift(payload: Payload): Payload { this.call("transferGift", payload) }
    public func postStory(payload: Payload): Payload { this.call("postStory", payload) }
    public func repostStory(payload: Payload): Payload { this.call("repostStory", payload) }
    public func editStory(payload: Payload): Payload { this.call("editStory", payload) }
    public func deleteStory(payload: Payload): Payload { this.call("deleteStory", payload) }
    public func sendSticker(payload: Payload): Payload { this.call("sendSticker", payload) }
    public func getStickerSet(payload: Payload): Payload { this.call("getStickerSet", payload) }
    public func getCustomEmojiStickers(payload: Payload): Payload { this.call("getCustomEmojiStickers", payload) }
    public func uploadStickerFile(payload: Payload): Payload { this.call("uploadStickerFile", payload) }
    public func createNewStickerSet(payload: Payload): Payload { this.call("createNewStickerSet", payload) }
    public func addStickerToSet(payload: Payload): Payload { this.call("addStickerToSet", payload) }
    public func setStickerPositionInSet(payload: Payload): Payload { this.call("setStickerPositionInSet", payload) }
    public func deleteStickerFromSet(payload: Payload): Payload { this.call("deleteStickerFromSet", payload) }
    public func replaceStickerInSet(payload: Payload): Payload { this.call("replaceStickerInSet", payload) }
    public func setStickerEmojiList(payload: Payload): Payload { this.call("setStickerEmojiList", payload) }
    public func setStickerKeywords(payload: Payload): Payload { this.call("setStickerKeywords", payload) }
    public func setStickerMaskPosition(payload: Payload): Payload { this.call("setStickerMaskPosition", payload) }
    public func setStickerSetTitle(payload: Payload): Payload { this.call("setStickerSetTitle", payload) }
    public func deleteStickerSet(payload: Payload): Payload { this.call("deleteStickerSet", payload) }
    public func setStickerSetThumbnail(payload: Payload): Payload { this.call("setStickerSetThumbnail", payload) }
    public func setCustomEmojiStickerSetThumbnail(payload: Payload): Payload { this.call("setCustomEmojiStickerSetThumbnail", payload) }
    public func getAvailableGifts(payload: Payload): Payload { this.call("getAvailableGifts", payload) }
    public func sendGift(payload: Payload): Payload { this.call("sendGift", payload) }
    public func giftPremiumSubscription(payload: Payload): Payload { this.call("giftPremiumSubscription", payload) }
    public func sendGiftToChannel(payload: Payload): Payload { this.call("sendGift", payload) }
    public func answerInlineQuery(payload: Payload): Payload { this.call("answerInlineQuery", payload) }
    public func answerWebAppQuery(payload: Payload): Payload { this.call("answerWebAppQuery", payload) }
    public func savePreparedInlineMessage(payload: Payload): Payload { this.call("savePreparedInlineMessage", payload) }
    public func savePreparedKeyboardButton(payload: Payload): Payload { this.call("savePreparedKeyboardButton", payload) }
    public func sendInvoice(payload: Payload): Payload { this.call("sendInvoice", payload) }
    public func createInvoiceLink(payload: Payload): Payload { this.call("createInvoiceLink", payload) }
    public func answerShippingQuery(payload: Payload): Payload { this.call("answerShippingQuery", payload) }
    public func answerPreCheckoutQuery(payload: Payload): Payload { this.call("answerPreCheckoutQuery", payload) }
    public func getStarTransactions(payload: Payload): Payload { this.call("getStarTransactions", payload) }
    public func refundStarPayment(payload: Payload): Payload { this.call("refundStarPayment", payload) }
    public func editUserStarSubscription(payload: Payload): Payload { this.call("editUserStarSubscription", payload) }
    public func verifyUser(payload: Payload): Payload { this.call("verifyUser", payload) }
    public func verifyChat(payload: Payload): Payload { this.call("verifyChat", payload) }
    public func removeUserVerification(payload: Payload): Payload { this.call("removeUserVerification", payload) }
    public func removeChatVerification(payload: Payload): Payload { this.call("removeChatVerification", payload) }
    public func readBusinessMessage(payload: Payload): Payload { this.call("readBusinessMessage", payload) }
    public func setPassportDataErrors(payload: Payload): Payload { this.call("setPassportDataErrors", payload) }
    public func sendGame(payload: Payload): Payload { this.call("sendGame", payload) }
    public func setGameScore(payload: Payload): Payload { this.call("setGameScore", payload) }
    public func setGameScoreInline(payload: Payload): Payload { this.call("setGameScore", payload) }
    public func getGameHighScores(payload: Payload): Payload { this.call("getGameHighScores", payload) }
    public func getGameHighScoresInline(payload: Payload): Payload { this.call("getGameHighScores", payload) }
}

public func apiWrapperGenerationSkeletonCount(): Int64 {
    apiWrapperCount()
}
