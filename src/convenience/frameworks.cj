package grammy4cj.convenience

import std.collection.ArrayList

import grammy4cj.types.Update

public let SECRET_HEADER: String = "X-Telegram-Bot-Api-Secret-Token"
public let SECRET_HEADER_LOWERCASE: String = "x-telegram-bot-api-secret-token"
public let WRONG_TOKEN_ERROR: String = "secret token is wrong"

public class WebhookHeader {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        this.key = key
        this.value = value
    }
}

public class WebhookHeaders {
    public var entries: ArrayList<WebhookHeader> = ArrayList<WebhookHeader>()

    public init() {}

    public func set(key: String, value: String): WebhookHeaders {
        this.entries.add(WebhookHeader(key, value))
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

    public func has(key: String): Bool {
        for (entry in this.entries) {
            if (headerNamesEqual(entry.key, key)) {
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

    public init(update: Update) {
        this.update = update
        this.rawBody = ""
        this.headers = WebhookHeaders()
        this.adapterName = "callback"
    }

    public init(update: Update, headers: WebhookHeaders) {
        this.update = update
        this.rawBody = ""
        this.headers = headers
        this.adapterName = "callback"
    }

    public init(update: Update, headers: WebhookHeaders, adapterName: String) {
        this.update = update
        this.rawBody = ""
        this.headers = headers
        this.adapterName = adapterName
    }

    public init(update: Update, rawBody: String, headers: WebhookHeaders, adapterName: String) {
        this.update = update
        this.rawBody = rawBody
        this.headers = headers
        this.adapterName = adapterName
    }

    public func secretHeader(): String {
        this.headers.get(SECRET_HEADER)
    }

    public func secretHeaderPresent(): Bool {
        this.headers.has(SECRET_HEADER)
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

    public init() {}

    public init(adapterName: String) {
        this.adapterName = adapterName
        this.handlerReturnAvailable = adapterHasHandlerReturn(adapterName)
        this.handlerReturnKind = adapterHandlerReturnKind(adapterName)
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
        this.statusCode = adapterEndStatusCode(adapterName)
        this.body = adapterEndBody(adapterName)
        this.contentType = ""
        this.statusText = ""
        this.ended = true
        this.lastAction = "end"
        this.resolveHandlerReturn()
    }

    public func respondJsonForAdapter(adapterName: String, json: String): Unit {
        this.statusCode = 200
        this.statusText = ""
        this.contentType = "application/json"
        this.body = json
        this.responded = true
        this.lastAction = "respond"
        this.resolveHandlerReturn()
    }

    public func unauthorizedForAdapter(adapterName: String): Unit {
        this.statusCode = 401
        this.statusText = adapterUnauthorizedStatusText(adapterName)
        this.contentType = ""
        this.body = adapterUnauthorizedBody(adapterName)
        this.unauthorizedCalled = true
        this.lastAction = "unauthorized"
        this.resolveHandlerReturn()
    }

    private func resolveHandlerReturn(): Unit {
        if (this.handlerReturnAvailable) {
            this.handlerReturnResolved = true
        }
    }
}

public class ReqResHandler {
    public let update: Update
    public let header: String
    public let headerPresent: Bool
    public let response: WebhookResponse
    public let handlerReturn: WebhookResponse
    public let adapterName: String

    public init(update: Update, header: String, headerPresent: Bool, response: WebhookResponse, adapterName: String) {
        this.update = update
        this.header = header
        this.headerPresent = headerPresent
        this.response = response
        this.handlerReturn = response
        this.adapterName = adapterName
    }

    public func respond(json: String): Unit {
        this.response.respondJsonForAdapter(this.adapterName, json)
    }

    public func unauthorized(): Unit {
        this.response.unauthorizedForAdapter(this.adapterName)
    }

    public func end(): Unit {
        this.response.endForAdapter(this.adapterName)
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
    [
        "callback",
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
    if (name == "elysia" || name == "hono") {
        return "promise-string-or-response"
    }
    "promise-response"
}

public func adapterEndStatusCode(name: String): Int64 {
    if (name == "azure-v4") {
        return 204
    }
    200
}

public func adapterEndBody(name: String): String {
    if (name == "azure" || name == "fastify" || name == "hono" || name == "koa" || name == "worktop") {
        return ""
    }
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
    if (name == "callback" ||
        name == "bun" ||
        name == "cloudflare" ||
        name == "cloudflare-mod" ||
        name == "serveHttp" ||
        name == "std/http" ||
        name == "sveltekit") {
        return "\"unauthorized\""
    }
    WRONG_TOKEN_ERROR
}

public func createReqResHandler(adapterName: String, request: WebhookRequest): ReqResHandler {
    if (!adapterIsSupported(adapterName)) {
        throw UnsupportedAdapterError(adapterName)
    }
    validateRequestBody(adapterName, request)
    let response = WebhookResponse(adapterName)
    ReqResHandler(request.update, request.secretHeader(), request.secretHeaderPresent(), response, adapterName)
}

public func callbackAdapter(update: Update, header: String): ReqResHandler {
    let headers = WebhookHeaders().set(SECRET_HEADER, header)
    createReqResHandler("callback", WebhookRequest(update, headers, "callback"))
}

public func nodeHttpAdapter(request: WebhookRequest): ReqResHandler {
    createReqResHandler("http", request)
}

public func expressAdapter(request: WebhookRequest): ReqResHandler {
    createReqResHandler("express", request)
}

private func adapterReason(name: String): String {
    if (name == "callback") {
        return "Cangjie callback adapter mirrors grammY's test adapter."
    }
    if (name == "http" || name == "https") {
        return "Node http/https contract mirrored by WebhookRequest/WebhookResponse fakes."
    }
    "Upstream grammY adapter contract mirrored by WebhookRequest/WebhookResponse fakes."
}

private func validateRequestBody(adapterName: String, request: WebhookRequest): Unit {
    if ((adapterName == "http" || adapterName == "https") && httpRawBodyMalformed(request.rawBody)) {
        throw MalformedWebhookBodyError(adapterName, request.rawBody)
    }
}

private func httpRawBodyMalformed(rawBody: String): Bool {
    if (rawBody.isEmpty()) {
        return false
    }
    if (!rawBody.startsWith("{")) {
        return true
    }
    if (!rawBody.endsWith("}")) {
        return true
    }
    !rawBody.contains("update_id") && !rawBody.contains("updateId")
}
