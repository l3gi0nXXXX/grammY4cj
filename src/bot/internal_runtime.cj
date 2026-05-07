package grammy4cj.bot

import std.collection.ArrayList

import grammy4cj.composer.BotError
import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.core.ApiClient
import grammy4cj.core.ApiClientOptions
import grammy4cj.core.CancelSignal
import grammy4cj.core.CoreFetch
import grammy4cj.core.Payload
import grammy4cj.core.WebhookReplyEnvelope
import grammy4cj.types.Update
import grammy4cj.types.UserFromGetMe

public type BotStartHook = (UserFromGetMe) -> Unit
public type BotContextFactory = (Update, Api, UserFromGetMe) -> Context

public func defaultContextFactory(update: Update, api: Api, me: UserFromGetMe): Context {
    Context(update, api, me)
}

public func defaultUpdateTypes(): Array<String> {
    [
        "message",
        "edited_message",
        "channel_post",
        "edited_channel_post",
        "business_connection",
        "business_message",
        "edited_business_message",
        "deleted_business_messages",
        "inline_query",
        "chosen_inline_result",
        "callback_query",
        "shipping_query",
        "pre_checkout_query",
        "purchased_paid_media",
        "poll",
        "poll_answer",
        "my_chat_member",
        "managed_bot",
        "chat_join_request",
        "chat_boost",
        "removed_chat_boost"
    ]
}

public func defaultBotInfo(): UserFromGetMe {
    UserFromGetMe(0, true, "grammY4cj", "grammy4cj_bot")
}

public class BotRetryConfig {
    public let initialDelayMillis: Int64
    public let maxDelayMillis: Int64

    public init() {
        this.initialDelayMillis = 50
        this.maxDelayMillis = 20 * 60 * 1000
    }

    public init(initialDelayMillis: Int64, maxDelayMillis: Int64) {
        this.initialDelayMillis = if (initialDelayMillis > 0) { initialDelayMillis } else { 50 }
        this.maxDelayMillis = if (maxDelayMillis > 0) { maxDelayMillis } else { 20 * 60 * 1000 }
    }
}

public class BotApiTransformerBoundary {
    private let names: ArrayList<String> = ArrayList<String>()

    public init() {}

    public init(names: Array<String>) {
        this.names.add(all: names)
    }

    public func use(transformerName: String): BotApiTransformerBoundary {
        this.names.add(transformerName)
        this
    }

    public func installedTransformers(): Array<String> {
        this.names.toArray()
    }

    public func copy(): BotApiTransformerBoundary {
        BotApiTransformerBoundary(this.installedTransformers())
    }
}

public class BotApiBoundary {
    public let token: String
    public let client: ApiClientOptions
    public let webhookReplyEnvelope: Option<WebhookReplyEnvelope>
    private let transformers: BotApiTransformerBoundary

    public init(token: String, client: ApiClientOptions) {
        this.token = token
        this.client = client
        this.webhookReplyEnvelope = None<WebhookReplyEnvelope>
        this.transformers = BotApiTransformerBoundary()
    }

    public init(token: String, client: ApiClientOptions, transformers: BotApiTransformerBoundary) {
        this.token = token
        this.client = client
        this.webhookReplyEnvelope = None<WebhookReplyEnvelope>
        this.transformers = transformers
    }

    public init(
        token: String,
        client: ApiClientOptions,
        transformers: BotApiTransformerBoundary,
        webhookReplyEnvelope: Option<WebhookReplyEnvelope>
    ) {
        this.token = token
        this.client = client
        this.webhookReplyEnvelope = webhookReplyEnvelope
        this.transformers = transformers
    }

    public func use(transformerName: String): BotApiBoundary {
        this.transformers.use(transformerName)
        this
    }

    public func installedTransformers(): Array<String> {
        this.transformers.installedTransformers()
    }

    public func copyForUpdate(): BotApiBoundary {
        BotApiBoundary(this.token, this.client, this.transformers.copy(), this.webhookReplyEnvelope)
    }
}

public class BotUpdateContextBoundary {
    public let update: Update
    public let api: BotApiBoundary
    public let me: UserFromGetMe

    public init(update: Update, api: BotApiBoundary, me: UserFromGetMe) {
        this.update = update
        this.api = api
        this.me = me
    }
}

public interface BotUpdateHandler {
    func handle(ctx: BotUpdateContextBoundary): Unit
}

public interface BotErrorHandler {
    func handle(error: BotError): Unit
}

public class NoopBotUpdateHandler <: BotUpdateHandler {
    public init() {}

    override public func handle(ctx: BotUpdateContextBoundary): Unit {
        ()
    }
}

public interface BotClock {
    func sleep(millis: Int64): Unit
}

public class NoopBotClock <: BotClock {
    public init() {}

    override public func sleep(millis: Int64): Unit {
        ()
    }
}

public class FakeBotClock <: BotClock {
    public var totalSleptMillis: Int64 = 0
    public let sleeps: ArrayList<Int64> = ArrayList<Int64>()

    public init() {}

    override public func sleep(millis: Int64): Unit {
        this.totalSleptMillis += millis
        this.sleeps.add(millis)
    }
}

public class PollingOptions {
    public let limit: Int64
    public let timeoutSeconds: Int64
    public let allowedUpdates: Array<String>
    public let allowedUpdatesSpecified: Bool
    public let dropPendingUpdates: Bool
    public let maxFetchCycles: Int64
    public let onStart: Option<BotStartHook>

    public init(
        limit!: Int64 = 100,
        timeoutSeconds!: Int64 = 30,
        allowedUpdates!: Array<String> = [],
        allowedUpdatesSpecified!: Bool = false,
        dropPendingUpdates!: Bool = false,
        maxFetchCycles!: Int64 = 1,
        onStart!: Option<BotStartHook> = None<BotStartHook>
    ) {
        this.limit = if (limit > 0) { limit } else { 100 }
        this.timeoutSeconds = if (timeoutSeconds > 0) { timeoutSeconds } else { 30 }
        this.allowedUpdates = allowedUpdates
        this.allowedUpdatesSpecified = allowedUpdatesSpecified
        this.dropPendingUpdates = dropPendingUpdates
        this.maxFetchCycles = if (maxFetchCycles > 0) { maxFetchCycles } else { 1 }
        this.onStart = onStart
    }
}

public class PollingFetchRequest {
    public let offset: Int64
    public let limit: Int64
    public let timeoutSeconds: Int64
    public let allowedUpdates: Array<String>
    public let includesAllowedUpdates: Bool

    public init(
        offset: Int64,
        limit: Int64,
        timeoutSeconds: Int64,
        allowedUpdates: Array<String>,
        includesAllowedUpdates: Bool
    ) {
        this.offset = offset
        this.limit = limit
        this.timeoutSeconds = timeoutSeconds
        this.allowedUpdates = allowedUpdates
        this.includesAllowedUpdates = includesAllowedUpdates
    }
}

private func pollingPayload(request: PollingFetchRequest): Payload {
    let payload = Payload("")
        .addInt("offset", request.offset)
        .addInt("limit", request.limit)
    if (request.timeoutSeconds > 0) {
        payload.addInt("timeout", request.timeoutSeconds)
    }
    if (request.includesAllowedUpdates) {
        payload.addRawJson("allowed_updates", stringArrayJson(request.allowedUpdates))
    }
    payload
}

private func parseUserFromGetMe(json: String): UserFromGetMe {
    UserFromGetMe(
        parseJsonIntOrDefault(jsonFieldValue(json, "id"), 0),
        parseJsonBoolOrDefault(jsonFieldValue(json, "is_bot"), true),
        parseJsonString(jsonFieldValue(json, "first_name")),
        parseJsonString(jsonFieldValue(json, "username"))
    )
}

private func parseUpdates(json: String): Array<Update> {
    let out = ArrayList<Update>()
    for (item in topLevelObjects(json)) {
        out.add(Update(parseJsonIntOrDefault(jsonFieldValue(item, "update_id"), 0), detectUpdateKind(item)))
    }
    out.toArray()
}

private func detectUpdateKind(json: String): String {
    for (kind in defaultUpdateTypes()) {
        if (jsonFieldValue(json, kind) != "") {
            return kind
        }
    }
    if (jsonFieldValue(json, "chat_member") != "") {
        return "chat_member"
    }
    if (jsonFieldValue(json, "message_reaction") != "") {
        return "message_reaction"
    }
    if (jsonFieldValue(json, "message_reaction_count") != "") {
        return "message_reaction_count"
    }
    ""
}

private func topLevelObjects(json: String): Array<String> {
    let objects = ArrayList<String>()
    var i: Int64 = 0
    while (i < json.size) {
        if (json[i..i + 1] == "{") {
            let object = readJsonCompositeValue(json, i)
            objects.add(object)
            i += object.size
        } else {
            i += 1
        }
    }
    objects.toArray()
}

private func stringArrayJson(values: Array<String>): String {
    var out = "["
    var first = true
    for (value in values) {
        if (!first) {
            out += ","
        }
        out += "\"" + escapeJsonString(value) + "\""
        first = false
    }
    out + "]"
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
            out += trimmed[i + 1..i + 2]
            i += 2
        } else {
            out += ch
            i += 1
        }
    }
    out
}

private func parseJsonBoolOrDefault(value: String, fallback: Bool): Bool {
    let trimmed = trimJson(value)
    if (trimmed == "true") {
        return true
    }
    if (trimmed == "false") {
        return false
    }
    fallback
}

private func parseJsonIntOrDefault(value: String, fallback: Int64): Int64 {
    if (value.isEmpty()) {
        return fallback
    }
    parseJsonInt(value)
}

private func parseJsonInt(value: String): Int64 {
    let trimmed = trimJson(value)
    var sign: Int64 = 1
    var i: Int64 = 0
    if (trimmed.size > 0 && trimmed[0..1] == "-") {
        sign = -1
        i = 1
    }
    var out: Int64 = 0
    while (i < trimmed.size) {
        let digit = digitValue(trimmed[i..i + 1])
        if (digit < 0) {
            break
        }
        out = out * 10 + digit
        i += 1
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

private func escapeJsonString(value: String): String {
    value.replace("\\", "\\\\").replace("\"", "\\\"")
}

public interface BotRuntime {
    func getMe(signal: CancelSignal): UserFromGetMe
    func deleteWebhook(dropPendingUpdates: Bool, signal: CancelSignal): Unit
    func getUpdates(request: PollingFetchRequest, signal: CancelSignal): Array<Update>
}

public class DefaultBotRuntime <: BotRuntime {
    public init() {}

    override public func getMe(signal: CancelSignal): UserFromGetMe {
        throw Exception("DefaultBotRuntime is a constructor placeholder and must be resolved before use.")
    }

    override public func deleteWebhook(dropPendingUpdates: Bool, signal: CancelSignal): Unit {
        throw Exception("DefaultBotRuntime is a constructor placeholder and must be resolved before use.")
    }

    override public func getUpdates(request: PollingFetchRequest, signal: CancelSignal): Array<Update> {
        throw Exception("DefaultBotRuntime is a constructor placeholder and must be resolved before use.")
    }
}

public class ApiBackedBotRuntime <: BotRuntime {
    private let token: String
    private let client: ApiClient

    public init(token: String, config: ApiClientOptions) {
        this.token = token
        this.client = ApiClient(config)
    }

    public init(token: String, config: ApiClientOptions, fetcher: CoreFetch) {
        this.token = token
        this.client = ApiClient(config, fetcher)
    }

    override public func getMe(signal: CancelSignal): UserFromGetMe {
        parseUserFromGetMe(this.client.callApi(this.token, "getMe", Payload("{}"), signal))
    }

    override public func deleteWebhook(dropPendingUpdates: Bool, signal: CancelSignal): Unit {
        let payload = Payload("").addBool("drop_pending_updates", dropPendingUpdates)
        let _ = this.client.callApi(this.token, "deleteWebhook", payload, signal)
    }

    override public func getUpdates(request: PollingFetchRequest, signal: CancelSignal): Array<Update> {
        let result = this.client.callApi(this.token, "getUpdates", pollingPayload(request), signal)
        parseUpdates(result)
    }
}

public class OfflineBotRuntime <: BotRuntime {
    public init() {}

    override public func getMe(signal: CancelSignal): UserFromGetMe {
        signal.throwIfCancelled()
        defaultBotInfo()
    }

    override public func deleteWebhook(dropPendingUpdates: Bool, signal: CancelSignal): Unit {
        signal.throwIfCancelled()
    }

    override public func getUpdates(request: PollingFetchRequest, signal: CancelSignal): Array<Update> {
        signal.throwIfCancelled()
        []
    }
}

public class FakePollingStep {
    public let updates: Array<Update>
    public let error: Option<Exception>

    public init(updates: Array<Update>, error: Option<Exception>) {
        this.updates = updates
        this.error = error
    }

    public static func batch(updates: Array<Update>): FakePollingStep {
        FakePollingStep(updates, None<Exception>)
    }

    public static func failure(error: Exception): FakePollingStep {
        FakePollingStep([], Some(error))
    }
}

public class FakeBotRuntime <: BotRuntime {
    public var getMeCalls: Int64 = 0
    public var deleteWebhookCalls: Int64 = 0
    public var getUpdatesCalls: Int64 = 0
    public var lastDropPendingUpdates: Bool = false
    public var getMeResult: UserFromGetMe = defaultBotInfo()
    public let getMeErrors: ArrayList<Exception> = ArrayList<Exception>()
    public let pollingSteps: ArrayList<FakePollingStep> = ArrayList<FakePollingStep>()
    public let pollingRequests: ArrayList<PollingFetchRequest> = ArrayList<PollingFetchRequest>()
    public let pollingSignals: ArrayList<CancelSignal> = ArrayList<CancelSignal>()
    public let deleteWebhookErrors: ArrayList<Exception> = ArrayList<Exception>()
    private var getMeErrorCursor: Int64 = 0
    private var pollingCursor: Int64 = 0
    private var deleteWebhookErrorCursor: Int64 = 0

    public init() {}

    public func failGetMeOnce(error: Exception): FakeBotRuntime {
        this.getMeErrors.add(error)
        this
    }

    public func failDeleteWebhookOnce(error: Exception): FakeBotRuntime {
        this.deleteWebhookErrors.add(error)
        this
    }

    public func enqueueUpdates(updates: Array<Update>): FakeBotRuntime {
        this.pollingSteps.add(FakePollingStep.batch(updates))
        this
    }

    public func enqueuePollingError(error: Exception): FakeBotRuntime {
        this.pollingSteps.add(FakePollingStep.failure(error))
        this
    }

    override public func getMe(signal: CancelSignal): UserFromGetMe {
        signal.throwIfCancelled()
        this.getMeCalls += 1
        if (this.getMeErrorCursor < this.getMeErrors.size) {
            let err = this.getMeErrors[this.getMeErrorCursor]
            this.getMeErrorCursor += 1
            throw err
        }
        this.getMeResult
    }

    override public func deleteWebhook(dropPendingUpdates: Bool, signal: CancelSignal): Unit {
        signal.throwIfCancelled()
        this.deleteWebhookCalls += 1
        this.lastDropPendingUpdates = dropPendingUpdates
        if (this.deleteWebhookErrorCursor < this.deleteWebhookErrors.size) {
            let err = this.deleteWebhookErrors[this.deleteWebhookErrorCursor]
            this.deleteWebhookErrorCursor += 1
            throw err
        }
    }

    override public func getUpdates(request: PollingFetchRequest, signal: CancelSignal): Array<Update> {
        signal.throwIfCancelled()
        this.getUpdatesCalls += 1
        this.pollingRequests.add(request)
        this.pollingSignals.add(signal)
        if (this.pollingCursor >= this.pollingSteps.size) {
            return []
        }
        let step = this.pollingSteps[this.pollingCursor]
        this.pollingCursor += 1
        match (step.error) {
            case Some(err) => throw err
            case None => step.updates
        }
    }
}

public class RecordingBotUpdateHandler <: BotUpdateHandler {
    public let contexts: ArrayList<BotUpdateContextBoundary> = ArrayList<BotUpdateContextBoundary>()
    public var failNext: Bool = false

    public init() {}

    override public func handle(ctx: BotUpdateContextBoundary): Unit {
        this.contexts.add(ctx)
        if (this.failNext) {
            this.failNext = false
            throw Exception("update handler failed")
        }
    }
}
