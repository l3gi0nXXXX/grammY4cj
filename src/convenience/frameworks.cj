package grammy4cj.convenience

import std.collection.ArrayList

import grammy4cj.types.Update

public let SECRET_HEADER: String = "X-Telegram-Bot-Api-Secret-Token"
public let SECRET_HEADER_LOWERCASE: String = "x-telegram-bot-api-secret-token"
public let WRONG_TOKEN_ERROR: String = "secret token is wrong"

public type WebhookUpdateResolver = () -> Update
public type WebhookRespondAction = (String) -> Unit
public type WebhookUnitAction = () -> Unit
public type FrameworkAdapter = (WebhookRequest) -> ReqResHandler

public class WebhookHeader {
    public let key: String
    public let value: String
    public let values: ArrayList<String>

    public init(key: String, value: String) {
        this.key = key
        this.value = value
        this.values = ArrayList<String>()
        this.values.add(value)
    }

    public init(key: String, values: Array<String>) {
        this.key = key
        this.values = ArrayList<String>()
        for (value in values) {
            this.values.add(value)
        }
        this.value = if (this.values.size > 0) { this.values[0] } else { "" }
    }
}

public class WebhookHeaders {
    public var entries: ArrayList<WebhookHeader> = ArrayList<WebhookHeader>()

    public init() {}

    public func set(key: String, value: String): WebhookHeaders {
        this.entries.add(WebhookHeader(key, value))
        this
    }

    public func setValues(key: String, values: Array<String>): WebhookHeaders {
        this.entries.add(WebhookHeader(key, values))
        this
    }

    public func get(key: String): String {
        for (entry in this.entries) {
            if (headerNamesEqual(entry.key, key)) {
                return entry.value
            }
        }
        ""
    }

    public func getExact(key: String): String {
        for (entry in this.entries) {
            if (entry.key == key) {
                return entry.value
            }
        }
        ""
    }

    public func has(key: String): Bool {
        for (entry in this.entries) {
            if (headerNamesEqual(entry.key, key)) {
                return true
            }
        }
        false
    }

    public func hasExact(key: String): Bool {
        for (entry in this.entries) {
            if (entry.key == key) {
                return true
            }
        }
        false
    }
}

public func headerNamesEqual(left: String, right: String): Bool {
    if (left == right) {
        return true
    }
    isSecretHeaderName(left) && isSecretHeaderName(right)
}

public func isSecretHeaderName(name: String): Bool {
    name == SECRET_HEADER ||
        name == SECRET_HEADER_LOWERCASE ||
        name == "X-TELEGRAM-BOT-API-SECRET-TOKEN" ||
        name == "x-Telegram-Bot-Api-Secret-Token"
}

public class WebhookRequest {
    public let update: Update
    public let rawBody: String
    public let headers: WebhookHeaders
    public let adapterName: String
    public let bodyPresent: Bool
    public let updateDelayMilliseconds: Int64
    public let updateFailureMessage: String
    public var bodyObjectReads: Int64 = 0
    public var jsonReads: Int64 = 0
    public var rawStreamReads: Int64 = 0
    public var headerReads: Int64 = 0

    public init(update: Update) {
        this.update = update
        this.rawBody = ""
        this.headers = WebhookHeaders()
        this.adapterName = "callback"
        this.bodyPresent = true
        this.updateDelayMilliseconds = 0
        this.updateFailureMessage = ""
    }

    public init(update: Update, headers: WebhookHeaders) {
        this.update = update
        this.rawBody = ""
        this.headers = headers
        this.adapterName = "callback"
        this.bodyPresent = true
        this.updateDelayMilliseconds = 0
        this.updateFailureMessage = ""
    }

    public init(update: Update, headers: WebhookHeaders, adapterName: String) {
        this.update = update
        this.rawBody = ""
        this.headers = headers
        this.adapterName = adapterName
        this.bodyPresent = true
        this.updateDelayMilliseconds = 0
        this.updateFailureMessage = ""
    }

    public init(update: Update, rawBody: String, headers: WebhookHeaders, adapterName: String) {
        this.update = update
        this.rawBody = rawBody
        this.headers = headers
        this.adapterName = adapterName
        this.bodyPresent = true
        this.updateDelayMilliseconds = 0
        this.updateFailureMessage = ""
    }

    public init(update: Update, rawBody: String, headers: WebhookHeaders, adapterName: String, bodyPresent: Bool) {
        this.update = update
        this.rawBody = rawBody
        this.headers = headers
        this.adapterName = adapterName
        this.bodyPresent = bodyPresent
        this.updateDelayMilliseconds = 0
        this.updateFailureMessage = ""
    }

    public init(
        update: Update,
        rawBody: String,
        headers: WebhookHeaders,
        adapterName: String,
        bodyPresent: Bool,
        updateDelayMilliseconds: Int64,
        updateFailureMessage: String
    ) {
        this.update = update
        this.rawBody = rawBody
        this.headers = headers
        this.adapterName = adapterName
        this.bodyPresent = bodyPresent
        this.updateDelayMilliseconds = updateDelayMilliseconds
        this.updateFailureMessage = updateFailureMessage
    }

    public static func raw(rawBody: String, headers: WebhookHeaders, adapterName: String): WebhookRequest {
        WebhookRequest(Update(0), rawBody, headers, adapterName)
    }

    public static func missingBody(headers: WebhookHeaders, adapterName: String): WebhookRequest {
        WebhookRequest(Update(0), "", headers, adapterName, false)
    }

    public static func delayed(update: Update, rawBody: String, headers: WebhookHeaders, adapterName: String, delay: Int64): WebhookRequest {
        WebhookRequest(update, rawBody, headers, adapterName, true, delay, "")
    }

    public static func failing(update: Update, rawBody: String, headers: WebhookHeaders, adapterName: String, message: String): WebhookRequest {
        WebhookRequest(update, rawBody, headers, adapterName, true, 0, message)
    }

    public func secretHeader(): String {
        this.headers.get(SECRET_HEADER)
    }

    public func secretHeaderPresent(): Bool {
        this.headers.has(SECRET_HEADER)
    }

    public func readBodyObject(adapterName: String): Update {
        this.bodyObjectReads += 1
        this.failUpdateIfConfigured()
        if (!this.bodyPresent) {
            throw MissingWebhookBodyError(adapterName)
        }
        this.update
    }

    public func readJson(adapterName: String): Update {
        this.jsonReads += 1
        this.failUpdateIfConfigured()
        if (!this.bodyPresent) {
            throw MissingWebhookBodyError(adapterName)
        }
        parseRawUpdateOrFallback(adapterName, this.rawBody, this.update)
    }

    public func readRawStream(adapterName: String): Update {
        this.rawStreamReads += 1
        this.failUpdateIfConfigured()
        if (!this.bodyPresent) {
            throw MissingWebhookBodyError(adapterName)
        }
        if (this.rawBody.isEmpty()) {
            return this.update
        }
        parseRawUpdate(adapterName, this.rawBody)
    }

    public func readOptionalEventBody(adapterName: String): Update {
        this.jsonReads += 1
        this.failUpdateIfConfigured()
        if (!this.bodyPresent) {
            return Update(0)
        }
        parseRawUpdateOrFallback(adapterName, this.rawBody, this.update)
    }

    public func headerCanonical(): String {
        this.headerReads += 1
        this.headers.get(SECRET_HEADER)
    }

    public func headerCanonicalPresent(): Bool {
        this.headers.has(SECRET_HEADER)
    }

    public func headerLowercaseExact(): String {
        this.headerReads += 1
        this.headers.getExact(SECRET_HEADER_LOWERCASE)
    }

    public func headerLowercaseExactPresent(): Bool {
        this.headers.hasExact(SECRET_HEADER_LOWERCASE)
    }

    public func headerAws(): String {
        this.headerReads += 1
        if (this.headers.hasExact(SECRET_HEADER)) {
            return this.headers.getExact(SECRET_HEADER)
        }
        this.headers.getExact(SECRET_HEADER_LOWERCASE)
    }

    public func headerAwsPresent(): Bool {
        this.headers.hasExact(SECRET_HEADER) || this.headers.hasExact(SECRET_HEADER_LOWERCASE)
    }

    private func failUpdateIfConfigured(): Unit {
        if (!this.updateFailureMessage.isEmpty()) {
            throw WebhookUpdateSourceError(this.updateFailureMessage)
        }
    }
}

public class WebhookResponse {
    public var statusCode: Int64 = 0
    public var statusText: String = ""
    public var body: String = ""
    public var contentType: String = ""
    public var ended: Bool = false
    public var responded: Bool = false
    public var unauthorizedCalled: Bool = false
    public var handlerReturnAvailable: Bool = false
    public var handlerReturnResolved: Bool = false
    public var handlerReturnKind: String = "none"
    public var adapterName: String = ""
    public var lastAction: String = ""
    public var lateWebhookReplySent: Bool = false
    public var lateWebhookReplyPayload: String = ""
    public var updateSource: String = ""
    public var headerSource: String = ""
    public var endProtocol: String = ""
    public var respondProtocol: String = ""
    public var unauthorizedProtocol: String = ""
    public var responseDelivery: String = ""
    public var respondWithRegistered: Bool = false
    public var callbackCalled: Bool = false
    public let calls: ArrayList<String> = ArrayList<String>()

    public init() {}

    public init(adapterName: String) {
        this.adapterName = adapterName
        this.handlerReturnAvailable = adapterHasHandlerReturn(adapterName)
        this.handlerReturnKind = adapterHandlerReturnKind(adapterName)
        this.updateSource = adapterUpdateSource(adapterName)
        this.headerSource = adapterHeaderSource(adapterName)
        this.endProtocol = adapterEndProtocol(adapterName)
        this.respondProtocol = adapterRespondProtocol(adapterName)
        this.unauthorizedProtocol = adapterUnauthorizedProtocol(adapterName)
        this.responseDelivery = adapterResponseDelivery(adapterName)
    }

    public func end(): Unit {
        this.endForAdapter(this.adapterName)
    }

    public func respondJson(json: String): Unit {
        this.respondJsonForAdapter(this.adapterName, json)
    }

    public func unauthorized(): Unit {
        this.unauthorizedForAdapter(this.adapterName)
    }

    public func endForAdapter(adapterName: String): Unit {
        this.recordAdapterEnd(adapterName)
    }

    public func respondJsonForAdapter(adapterName: String, json: String): Unit {
        this.recordAdapterRespond(adapterName, json)
    }

    public func unauthorizedForAdapter(adapterName: String): Unit {
        this.recordAdapterUnauthorized(adapterName)
    }

    public func recordCallback(statusCode: Int64, body: String, contentType: String): Unit {
        this.callbackCalled = true
        this.statusCode = statusCode
        this.statusText = ""
        this.contentType = contentType
        this.body = body
        if (statusCode == 401) {
            this.unauthorizedCalled = true
            this.lastAction = "unauthorized"
        } else if (body.isEmpty() && contentType.isEmpty()) {
            this.ended = true
            this.lastAction = "end"
        } else {
            this.responded = true
            this.lastAction = "respond"
        }
        this.calls.add("callback")
    }

    public func recordHandlerReturn(statusCode: Int64, body: String, contentType: String, statusText: String): Unit {
        this.statusCode = statusCode
        this.statusText = statusText
        this.contentType = contentType
        this.body = body
        if (statusCode == 401) {
            this.unauthorizedCalled = true
            this.lastAction = "unauthorized"
        } else if (contentType == "application/json") {
            this.responded = true
            this.lastAction = "respond"
        } else {
            this.ended = true
            this.lastAction = "end"
        }
        this.resolveHandlerReturn()
        this.calls.add("resolve")
    }

    public func recordEventRespondWith(statusCode: Int64, body: String, contentType: String, statusText: String): Unit {
        this.respondWithRegistered = true
        this.statusCode = statusCode
        this.statusText = statusText
        this.contentType = contentType
        this.body = body
        if (statusCode == 401) {
            this.unauthorizedCalled = true
            this.lastAction = "unauthorized"
        } else if (contentType == "application/json") {
            this.responded = true
            this.lastAction = "respond"
        } else {
            this.ended = true
            this.lastAction = "end"
        }
        this.calls.add("respondWith")
    }

    public func recordAdapterEnd(adapterName: String): Unit {
        if (adapterName == "aws-lambda") {
            this.recordCallback(200, "", "")
        } else if (adapterName == "aws-lambda-async") {
            this.recordHandlerReturn(200, "", "", "")
        } else if (adapterName == "azure") {
            this.recordMutable("context.res", 200, "", "", "end")
        } else if (adapterName == "azure-v4") {
            this.recordHandlerReturn(204, "", "", "")
        } else if (adapterName == "cloudflare" || adapterName == "serveHttp") {
            this.recordEventRespondWith(200, "", "", "")
        } else if (adapterHasHandlerReturn(adapterName)) {
            this.recordHandlerReturn(200, "", "", "")
        } else if (adapterName == "fastify") {
            this.recordMutable("reply.send", 200, "", "", "end")
        } else if (adapterName == "nhttp") {
            this.recordMutable("sendStatus", 200, "", "", "end")
        } else if (adapterName == "oak") {
            this.recordMutable("ctx.response.status", 200, "", "", "end")
        } else if (adapterName == "worktop") {
            this.recordMutable("res.end", 200, "", "", "end")
        } else {
            this.recordMutable("response.end", 200, "", "", "end")
        }
    }

    public func recordAdapterRespond(adapterName: String, json: String): Unit {
        if (adapterName == "aws-lambda") {
            this.recordCallback(200, json, "application/json")
        } else if (adapterName == "aws-lambda-async") {
            this.recordHandlerReturn(200, json, "application/json", "")
        } else if (adapterName == "azure") {
            this.recordMutable("context.res.send", 200, json, "application/json", "respond")
        } else if (adapterName == "azure-v4") {
            this.recordHandlerReturn(200, json, "application/json", "")
        } else if (adapterName == "cloudflare" || adapterName == "serveHttp") {
            this.recordEventRespondWith(200, json, "application/json", "")
        } else if (adapterHasHandlerReturn(adapterName)) {
            this.recordHandlerReturn(200, json, "application/json", "")
        } else if (adapterName == "http" || adapterName == "https") {
            this.recordMutable("writeHead.end", 200, json, "application/json", "respond")
        } else {
            this.recordMutable("response.send", 200, json, "application/json", "respond")
        }
    }

    public func recordAdapterUnauthorized(adapterName: String): Unit {
        let body = adapterUnauthorizedBody(adapterName)
        let statusText = adapterUnauthorizedStatusText(adapterName)
        if (adapterName == "aws-lambda") {
            this.recordCallback(401, "", "")
        } else if (adapterName == "aws-lambda-async") {
            this.recordHandlerReturn(401, "", "", "")
        } else if (adapterName == "cloudflare" || adapterName == "serveHttp") {
            this.recordEventRespondWith(401, body, "", statusText)
        } else if (adapterHasHandlerReturn(adapterName)) {
            this.recordHandlerReturn(401, body, "", statusText)
        } else {
            this.recordMutable("unauthorized", 401, body, "", "unauthorized")
        }
    }

    private func recordMutable(call: String, statusCode: Int64, body: String, contentType: String, action: String): Unit {
        this.statusCode = statusCode
        this.statusText = ""
        this.contentType = contentType
        this.body = body
        this.ended = action == "end"
        this.responded = action == "respond"
        this.unauthorizedCalled = action == "unauthorized"
        this.lastAction = action
        this.calls.add(call)
    }

    private func resolveHandlerReturn(): Unit {
        if (this.handlerReturnAvailable) {
            this.handlerReturnResolved = true
        }
    }
}

public class ReqResHandler {
    private let readUpdate: WebhookUpdateResolver
    private let respondAction: WebhookRespondAction
    private let unauthorizedAction: WebhookUnitAction
    private let endAction: WebhookUnitAction
    private var cachedUpdate: Option<Update> = None<Update>
    public let header: String
    public let headerPresent: Bool
    public let response: WebhookResponse
    public let handlerReturn: WebhookResponse
    public let adapterName: String
    public let endAvailable: Bool
    public let updateDelayMilliseconds: Int64

    public init(
        adapterName: String,
        header: String,
        headerPresent: Bool,
        response: WebhookResponse,
        updateDelayMilliseconds: Int64,
        endAvailable: Bool,
        readUpdate: WebhookUpdateResolver,
        respondAction: WebhookRespondAction,
        unauthorizedAction: WebhookUnitAction,
        endAction: WebhookUnitAction
    ) {
        this.adapterName = adapterName
        this.header = header
        this.headerPresent = headerPresent
        this.response = response
        this.handlerReturn = response
        this.updateDelayMilliseconds = updateDelayMilliseconds
        this.endAvailable = endAvailable
        this.readUpdate = readUpdate
        this.respondAction = respondAction
        this.unauthorizedAction = unauthorizedAction
        this.endAction = endAction
    }

    public prop update: Update {
        get() {
            match (this.cachedUpdate) {
                case Some(update) => update
                case None =>
                    let parsed = this.readUpdate()
                    this.cachedUpdate = Some(parsed)
                    parsed
            }
        }
    }

    public func respond(json: String): Unit {
        this.respondAction(json)
    }

    public func unauthorized(): Unit {
        this.unauthorizedAction()
    }

    public func end(): Unit {
        if (this.endAvailable) {
            this.endAction()
        }
    }
}

public class AdapterStatusEntry {
    public let name: String
    public let supported: Bool
    public let state: String
    public let reason: String

    public init(name: String, supported: Bool, state: String, reason: String) {
        this.name = name
        this.supported = supported
        this.state = state
        this.reason = reason
    }
}

public class FrameworkAdapterContract {
    public let name: String
    public let updateSource: String
    public let headerSource: String
    public let endProtocol: String
    public let respondProtocol: String
    public let unauthorizedProtocol: String
    public let responseDelivery: String
    public let handlerReturnAvailable: Bool
    public let handlerReturnKind: String
    public let endStatusCode: Int64
    public let endBody: String
    public let unauthorizedStatusText: String
    public let unauthorizedBody: String

    public init(name: String) {
        this.name = name
        this.updateSource = adapterUpdateSource(name)
        this.headerSource = adapterHeaderSource(name)
        this.endProtocol = adapterEndProtocol(name)
        this.respondProtocol = adapterRespondProtocol(name)
        this.unauthorizedProtocol = adapterUnauthorizedProtocol(name)
        this.responseDelivery = adapterResponseDelivery(name)
        this.handlerReturnAvailable = adapterHasHandlerReturn(name)
        this.handlerReturnKind = adapterHandlerReturnKind(name)
        this.endStatusCode = adapterEndStatusCode(name)
        this.endBody = adapterEndBody(name)
        this.unauthorizedStatusText = adapterUnauthorizedStatusText(name)
        this.unauthorizedBody = adapterUnauthorizedBody(name)
    }
}

public class UnsupportedAdapterError <: Exception {
    public let adapterName: String

    public init(adapterName: String) {
        super("Unsupported webhook adapter: ${adapterName}")
        this.adapterName = adapterName
    }
}

public class MalformedWebhookBodyError <: Exception {
    public let adapterName: String
    public let rawBody: String

    public init(adapterName: String, rawBody: String) {
        super("Malformed JSON body for webhook adapter: ${adapterName}")
        this.adapterName = adapterName
        this.rawBody = rawBody
    }
}

public class MissingWebhookBodyError <: Exception {
    public let adapterName: String

    public init(adapterName: String) {
        super("Missing webhook body for webhook adapter: ${adapterName}")
        this.adapterName = adapterName
    }
}

public class WebhookUpdateSourceError <: Exception {
    public init(message: String) {
        super(message)
    }
}

public func upstreamFrameworkAdapterNames(): Array<String> {
    [
        "aws-lambda",
        "aws-lambda-async",
        "azure",
        "azure-v4",
        "bun",
        "cloudflare",
        "cloudflare-mod",
        "elysia",
        "express",
        "fastify",
        "hono",
        "http",
        "https",
        "koa",
        "next-js",
        "nhttp",
        "oak",
        "serveHttp",
        "std/http",
        "sveltekit",
        "worktop"
    ]
}

public func registeredFrameworkAdapterNames(): Array<String> {
    upstreamFrameworkAdapterNames()
}

public func registeredFrameworkAdapterCount(): Int64 {
    registeredFrameworkAdapterNames().size
}

public func upstreamFrameworkAdapterCount(): Int64 {
    upstreamFrameworkAdapterNames().size
}

public func hasAdapterStatus(name: String): Bool {
    for (adapterName in registeredFrameworkAdapterNames()) {
        if (adapterName == name) {
            return true
        }
    }
    false
}

public func adapterStatus(name: String): AdapterStatusEntry {
    if (hasAdapterStatus(name)) {
        return AdapterStatusEntry(name, true, "supported", adapterReason(name))
    }
    AdapterStatusEntry(name, false, "unknown", "No upstream grammY adapter with this name is registered.")
}

public func adapterIsSupported(name: String): Bool {
    adapterStatus(name).supported
}

public func adapterHasHandlerReturn(name: String): Bool {
    name == "aws-lambda-async" ||
        name == "azure-v4" ||
        name == "bun" ||
        name == "cloudflare-mod" ||
        name == "elysia" ||
        name == "hono" ||
        name == "std/http" ||
        name == "sveltekit"
}

public func adapterHandlerReturnKind(name: String): String {
    if (!adapterHasHandlerReturn(name)) {
        return "none"
    }
    if (name == "aws-lambda-async") {
        return "promise-lambda-result"
    }
    if (name == "azure-v4") {
        return "promise-azure-response"
    }
    if (name == "elysia") {
        return "promise-string"
    }
    if (name == "hono") {
        return "promise-response"
    }
    "promise-response"
}

public func adapterResponseDelivery(name: String): String {
    if (adapterHasHandlerReturn(name)) {
        return "handler-return"
    }
    if (name == "aws-lambda") {
        return "lambda-callback"
    }
    if (name == "cloudflare" || name == "serveHttp") {
        return "event-respond-with"
    }
    if (name == "azure" ||
        name == "express" ||
        name == "fastify" ||
        name == "http" ||
        name == "https" ||
        name == "koa" ||
        name == "next-js" ||
        name == "nhttp" ||
        name == "oak" ||
        name == "worktop") {
        return "mutable-response"
    }
    "unknown"
}

public func adapterUpdateSource(name: String): String {
    if (name == "aws-lambda" || name == "aws-lambda-async") {
        return "event.body-json"
    }
    if (name == "azure") {
        return "request.body"
    }
    if (name == "azure-v4" ||
        name == "bun" ||
        name == "cloudflare" ||
        name == "cloudflare-mod" ||
        name == "hono" ||
        name == "oak" ||
        name == "serveHttp" ||
        name == "std/http" ||
        name == "sveltekit" ||
        name == "worktop") {
        return "request.json"
    }
    if (name == "elysia" ||
        name == "express" ||
        name == "fastify" ||
        name == "koa" ||
        name == "next-js" ||
        name == "nhttp") {
        return "body-object"
    }
    if (name == "http" || name == "https") {
        return "node-raw-json-stream"
    }
    "unknown"
}

public func adapterHeaderSource(name: String): String {
    if (name == "aws-lambda" || name == "aws-lambda-async") {
        return "headers-canonical-or-lowercase"
    }
    if (name == "azure" ||
        name == "elysia" ||
        name == "fastify" ||
        name == "http" ||
        name == "https" ||
        name == "next-js") {
        return "headers-lowercase"
    }
    return "headers-get-canonical"
}

public func adapterEndProtocol(name: String): String {
    if (name == "aws-lambda") {
        return "callback-status-200"
    }
    if (name == "aws-lambda-async") {
        return "resolve-status-200"
    }
    if (name == "azure") {
        return "context-res-status-200-empty-body"
    }
    if (name == "azure-v4") {
        return "resolve-status-204"
    }
    if (name == "bun" ||
        name == "cloudflare" ||
        name == "cloudflare-mod" ||
        name == "serveHttp" ||
        name == "std/http" ||
        name == "sveltekit") {
        return "response-200-empty-body"
    }
    if (name == "elysia" || name == "hono") {
        return "resolve-empty-body"
    }
    if (name == "express" || name == "http" || name == "https" || name == "next-js") {
        return "response-end"
    }
    if (name == "fastify") {
        return "reply-send-empty"
    }
    if (name == "koa") {
        return "ctx-body-empty"
    }
    if (name == "nhttp") {
        return "send-status-200"
    }
    if (name == "oak") {
        return "response-status-200"
    }
    if (name == "worktop") {
        return "res-end-null"
    }
    "unknown"
}

public func adapterRespondProtocol(name: String): String {
    if (name == "aws-lambda" || name == "aws-lambda-async") {
        return "status-200-json-body"
    }
    if (name == "azure") {
        return "context-res-send-json"
    }
    if (name == "azure-v4") {
        return "resolve-json-body"
    }
    if (name == "bun" ||
        name == "cloudflare" ||
        name == "cloudflare-mod" ||
        name == "serveHttp" ||
        name == "std/http" ||
        name == "sveltekit") {
        return "response-200-application-json"
    }
    if (name == "elysia") {
        return "set-content-type-resolve-json"
    }
    if (name == "express") {
        return "res-set-content-type-send"
    }
    if (name == "fastify") {
        return "reply-headers-send"
    }
    if (name == "hono") {
        return "c-json"
    }
    if (name == "http" || name == "https") {
        return "write-head-json-end"
    }
    if (name == "koa") {
        return "ctx-set-response-body"
    }
    if (name == "next-js") {
        return "status-200-json"
    }
    if (name == "nhttp") {
        return "status-200-send"
    }
    if (name == "oak") {
        return "response-type-json-body"
    }
    if (name == "worktop") {
        return "res-send-200"
    }
    "unknown"
}

public func adapterUnauthorizedProtocol(name: String): String {
    if (name == "aws-lambda" || name == "aws-lambda-async") {
        return "status-401-no-body"
    }
    if (name == "azure") {
        return "context-res-send-401"
    }
    if (name == "azure-v4") {
        return "resolve-status-401-body"
    }
    if (name == "bun" ||
        name == "cloudflare" ||
        name == "cloudflare-mod" ||
        name == "serveHttp" ||
        name == "std/http" ||
        name == "sveltekit") {
        return "response-401-unauthorized-json"
    }
    if (name == "elysia") {
        return "set-status-401-empty"
    }
    if (name == "express") {
        return "status-401-send"
    }
    if (name == "fastify") {
        return "code-401-send"
    }
    if (name == "hono") {
        return "status-401-empty-body"
    }
    if (name == "http" || name == "https") {
        return "write-head-401-end"
    }
    if (name == "koa") {
        return "ctx-status-401"
    }
    if (name == "next-js") {
        return "status-401-send"
    }
    if (name == "nhttp") {
        return "status-401-send"
    }
    if (name == "oak") {
        return "response-status-401"
    }
    if (name == "worktop") {
        return "res-send-401"
    }
    "unknown"
}

public func adapterEndStatusCode(name: String): Int64 {
    if (name == "azure-v4") {
        return 204
    }
    200
}

public func adapterEndBody(_name: String): String {
    ""
}

public func adapterUnauthorizedStatusText(name: String): String {
    if (name == "bun" ||
        name == "cloudflare" ||
        name == "cloudflare-mod" ||
        name == "serveHttp" ||
        name == "std/http" ||
        name == "sveltekit") {
        return WRONG_TOKEN_ERROR
    }
    ""
}

public func adapterUnauthorizedBody(name: String): String {
    if (name == "aws-lambda" ||
        name == "aws-lambda-async" ||
        name == "elysia" ||
        name == "hono" ||
        name == "koa" ||
        name == "oak") {
        return ""
    }
    if (name == "bun" ||
        name == "cloudflare" ||
        name == "cloudflare-mod" ||
        name == "serveHttp" ||
        name == "std/http" ||
        name == "sveltekit") {
        return "\"unauthorized\""
    }
    WRONG_TOKEN_ERROR
}

public func frameworkAdapterContract(name: String): FrameworkAdapterContract {
    if (!adapterIsSupported(name)) {
        throw UnsupportedAdapterError(name)
    }
    FrameworkAdapterContract(name)
}

public func frameworkAdapterContracts(): Array<FrameworkAdapterContract> {
    [
        FrameworkAdapterContract("aws-lambda"),
        FrameworkAdapterContract("aws-lambda-async"),
        FrameworkAdapterContract("azure"),
        FrameworkAdapterContract("azure-v4"),
        FrameworkAdapterContract("bun"),
        FrameworkAdapterContract("cloudflare"),
        FrameworkAdapterContract("cloudflare-mod"),
        FrameworkAdapterContract("elysia"),
        FrameworkAdapterContract("express"),
        FrameworkAdapterContract("fastify"),
        FrameworkAdapterContract("hono"),
        FrameworkAdapterContract("http"),
        FrameworkAdapterContract("https"),
        FrameworkAdapterContract("koa"),
        FrameworkAdapterContract("next-js"),
        FrameworkAdapterContract("nhttp"),
        FrameworkAdapterContract("oak"),
        FrameworkAdapterContract("serveHttp"),
        FrameworkAdapterContract("std/http"),
        FrameworkAdapterContract("sveltekit"),
        FrameworkAdapterContract("worktop")
    ]
}

public func createReqResHandler(adapterName: String, request: WebhookRequest): ReqResHandler {
    if (!adapterIsSupported(adapterName)) {
        throw UnsupportedAdapterError(adapterName)
    }
    createNativeAdapterReqResHandler(adapterName, request)
}

public func frameworkAdapter(name: String): FrameworkAdapter {
    if (name == "aws-lambda") { return awsLambdaAdapter }
    if (name == "aws-lambda-async") { return awsLambdaAsyncAdapter }
    if (name == "azure") { return azureAdapter }
    if (name == "azure-v4") { return azureV4Adapter }
    if (name == "bun") { return bunAdapter }
    if (name == "cloudflare") { return cloudflareAdapter }
    if (name == "cloudflare-mod") { return cloudflareModuleAdapter }
    if (name == "elysia") { return elysiaAdapter }
    if (name == "express") { return expressAdapter }
    if (name == "fastify") { return fastifyAdapter }
    if (name == "hono") { return honoAdapter }
    if (name == "http") { return nodeHttpAdapter }
    if (name == "https") { return httpsAdapter }
    if (name == "koa") { return koaAdapter }
    if (name == "next-js") { return nextJsAdapter }
    if (name == "nhttp") { return nhttpAdapter }
    if (name == "oak") { return oakAdapter }
    if (name == "serveHttp") { return serveHttpAdapter }
    if (name == "std/http") { return stdHttpAdapter }
    if (name == "sveltekit") { return sveltekitAdapter }
    if (name == "worktop") { return worktopAdapter }
    throw UnsupportedAdapterError(name)
}

public func callbackAdapter(update: Update, header: String): ReqResHandler {
    callbackAdapter(update, header, { _json: String => () })
}

public func callbackAdapter(update: Update, header: String, callback: WebhookRespondAction): ReqResHandler {
    let headers = WebhookHeaders().set(SECRET_HEADER, header)
    let request = WebhookRequest(update, headers, "callback")
    let response = WebhookResponse("callback")
    ReqResHandler(
        "callback",
        header,
        !header.isEmpty(),
        response,
        request.updateDelayMilliseconds,
        false,
        { => request.readBodyObject("callback") },
        { json: String =>
            callback(json)
            response.recordCallback(200, json, "application/json")
        },
        { =>
            callback("\"unauthorized\"")
            response.recordCallback(401, "\"unauthorized\"", "")
        },
        { => () }
    )
}

public func callbackRequestAdapter(request: WebhookRequest): ReqResHandler {
    let response = WebhookResponse("callback")
    ReqResHandler(
        "callback",
        request.secretHeader(),
        request.secretHeaderPresent(),
        response,
        request.updateDelayMilliseconds,
        false,
        { => request.readBodyObject("callback") },
        { json: String => response.recordCallback(200, json, "application/json") },
        { => response.recordCallback(401, "\"unauthorized\"", "") },
        { => () }
    )
}

public func nodeHttpAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("http", request)
}

public func expressAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("express", request)
}

public func awsLambdaAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("aws-lambda", request)
}

public func awsLambdaAsyncAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("aws-lambda-async", request)
}

public func azureAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("azure", request)
}

public func azureV4Adapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("azure-v4", request)
}

public func bunAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("bun", request)
}

public func cloudflareAdapter(request: WebhookRequest): ReqResHandler {
    let handler = createNativeAdapterReqResHandler("cloudflare", request)
    handler.response.respondWithRegistered = true
    handler
}

public func cloudflareModuleAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("cloudflare-mod", request)
}

public func elysiaAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("elysia", request)
}

public func fastifyAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("fastify", request)
}

public func honoAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("hono", request)
}

public func httpsAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("https", request)
}

public func koaAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("koa", request)
}

public func nextJsAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("next-js", request)
}

public func nhttpAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("nhttp", request)
}

public func oakAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("oak", request)
}

public func serveHttpAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("serveHttp", request)
}

public func stdHttpAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("std/http", request)
}

public func sveltekitAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("sveltekit", request)
}

public func worktopAdapter(request: WebhookRequest): ReqResHandler {
    createNativeAdapterReqResHandler("worktop", request)
}

private func createNativeAdapterReqResHandler(adapterName: String, request: WebhookRequest): ReqResHandler {
    let response = WebhookResponse(adapterName)
    ReqResHandler(
        adapterName,
        headerValueForAdapter(adapterName, request),
        headerPresentForAdapter(adapterName, request),
        response,
        request.updateDelayMilliseconds,
        true,
        updateResolverForAdapter(adapterName, request),
        { json: String => response.recordAdapterRespond(adapterName, json) },
        { => response.recordAdapterUnauthorized(adapterName) },
        { => response.recordAdapterEnd(adapterName) }
    )
}

private func updateResolverForAdapter(adapterName: String, request: WebhookRequest): WebhookUpdateResolver {
    let source = adapterUpdateSource(adapterName)
    if (source == "body-object") {
        return { => request.readBodyObject(adapterName) }
    }
    if (source == "event.body-json") {
        return { => request.readOptionalEventBody(adapterName) }
    }
    if (source == "node-raw-json-stream") {
        return { => request.readRawStream(adapterName) }
    }
    { => request.readJson(adapterName) }
}

private func adapterReason(name: String): String {
    if (name == "http" || name == "https") {
        return "Node http/https adapter reads raw JSON stream and writes with writeHead/end."
    }
    "Upstream grammY adapter request, header, response, and handlerReturn semantics are mirrored by injectable fake framework objects."
}

private func headerValueForAdapter(adapterName: String, request: WebhookRequest): String {
    if (adapterName == "aws-lambda" || adapterName == "aws-lambda-async") {
        return request.headerAws()
    }
    if (adapterName == "azure" ||
        adapterName == "elysia" ||
        adapterName == "fastify" ||
        adapterName == "http" ||
        adapterName == "https" ||
        adapterName == "next-js") {
        return request.headerLowercaseExact()
    }
    request.headerCanonical()
}

private func headerPresentForAdapter(adapterName: String, request: WebhookRequest): Bool {
    if (adapterName == "aws-lambda" || adapterName == "aws-lambda-async") {
        request.headerAwsPresent()
    } else if (adapterName == "azure" ||
        adapterName == "elysia" ||
        adapterName == "fastify" ||
        adapterName == "http" ||
        adapterName == "https" ||
        adapterName == "next-js") {
        request.headerLowercaseExactPresent()
    } else {
        request.headerCanonicalPresent()
    }
}

private func parseRawUpdateOrFallback(adapterName: String, rawBody: String, fallback: Update): Update {
    if (rawBody.isEmpty()) {
        return fallback
    }
    parseRawUpdate(adapterName, rawBody)
}

private func parseRawUpdate(adapterName: String, rawBody: String): Update {
    if (rawJsonObjectMalformed(rawBody)) {
        throw MalformedWebhookBodyError(adapterName, rawBody)
    }
    if (!rawBody.contains("\"update_id\"") && !rawBody.contains("\"updateId\"")) {
        if (rawJsonObjectEmpty(rawBody)) {
            return Update(0)
        }
        throw MalformedWebhookBodyError(adapterName, rawBody)
    }
    let updateId = parseUpdateId(adapterName, rawBody)
    Update(updateId)
}

private func rawJsonObjectMalformed(rawBody: String): Bool {
    let first = firstNonWhitespaceIndex(rawBody)
    if (first < 0) {
        return true
    }
    let last = lastNonWhitespaceIndex(rawBody)
    rawBody[first..first + 1] != "{" || rawBody[last..last + 1] != "}"
}

private func rawJsonObjectEmpty(rawBody: String): Bool {
    let first = firstNonWhitespaceIndex(rawBody)
    let last = lastNonWhitespaceIndex(rawBody)
    var i = first + 1
    while (i < last) {
        if (!isJsonWhitespace(rawBody[i..i + 1])) {
            return false
        }
        i += 1
    }
    true
}

private func firstNonWhitespaceIndex(value: String): Int64 {
    var i: Int64 = 0
    while (i < value.size) {
        if (!isJsonWhitespace(value[i..i + 1])) {
            return i
        }
        i += 1
    }
    -1
}

private func lastNonWhitespaceIndex(value: String): Int64 {
    var i = value.size - 1
    while (i >= 0) {
        if (!isJsonWhitespace(value[i..i + 1])) {
            return i
        }
        i -= 1
    }
    -1
}

private func isJsonWhitespace(value: String): Bool {
    value == " " || value == "\n" || value == "\r" || value == "\t"
}

private func parseUpdateId(adapterName: String, rawBody: String): Int64 {
    let keyIndex = updateIdKeyIndex(rawBody)
    if (keyIndex < 0) {
        return 0
    }
    let keyLength = if (rawBody[keyIndex..keyIndex + 11] == "\"update_id\"") { 11 } else { 10 }
    let afterKey = keyIndex + keyLength
    let rest = rawBody[afterKey..rawBody.size]
    match (rest.indexOf(":")) {
        case Some(offset) => parseIntegerAfter(adapterName, rawBody, afterKey + offset + 1)
        case None => throw MalformedWebhookBodyError(adapterName, rawBody)
    }
}

private func updateIdKeyIndex(rawBody: String): Int64 {
    match (rawBody.indexOf("\"update_id\"")) {
        case Some(index) => return index
        case None => ()
    }
    match (rawBody.indexOf("\"updateId\"")) {
        case Some(index) => index
        case None => -1
    }
}

private func parseIntegerAfter(adapterName: String, rawBody: String, start: Int64): Int64 {
    var i = start
    while (i < rawBody.size && isJsonWhitespace(rawBody[i..i + 1])) {
        i += 1
    }
    var value: Int64 = 0
    var found = false
    while (i < rawBody.size) {
        let ch = rawBody[i..i + 1]
        if (!isDigit(ch)) {
            if (found) {
                return value
            }
            throw MalformedWebhookBodyError(adapterName, rawBody)
        }
        found = true
        value = value * 10 + digitValue(ch)
        i += 1
    }
    if (found) {
        return value
    }
    throw MalformedWebhookBodyError(adapterName, rawBody)
}

private func isDigit(value: String): Bool {
    value == "0" || value == "1" || value == "2" || value == "3" || value == "4" ||
        value == "5" || value == "6" || value == "7" || value == "8" || value == "9"
}

private func digitValue(value: String): Int64 {
    if (value == "1") { return 1 }
    if (value == "2") { return 2 }
    if (value == "3") { return 3 }
    if (value == "4") { return 4 }
    if (value == "5") { return 5 }
    if (value == "6") { return 6 }
    if (value == "7") { return 7 }
    if (value == "8") { return 8 }
    if (value == "9") { return 9 }
    0
}
