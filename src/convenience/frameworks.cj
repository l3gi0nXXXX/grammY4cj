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
}

public class WebhookResponse {
    public var statusCode: Int64 = 0
    public var body: String = ""
    public var contentType: String = ""
    public var ended: Bool = false
    public var responded: Bool = false
    public var unauthorizedCalled: Bool = false

    public init() {}

    public func end(): Unit {
        this.statusCode = 200
        this.body = ""
        this.ended = true
    }

    public func respondJson(json: String): Unit {
        this.statusCode = 200
        this.contentType = "application/json"
        this.body = json
        this.responded = true
    }

    public func unauthorized(): Unit {
        this.statusCode = 401
        this.body = WRONG_TOKEN_ERROR
        this.unauthorizedCalled = true
    }
}

public class ReqResHandler {
    public let update: Update
    public let header: String
    public let response: WebhookResponse
    public let handlerReturn: WebhookResponse
    public let adapterName: String

    public init(update: Update, header: String, response: WebhookResponse, adapterName: String) {
        this.update = update
        this.header = header
        this.response = response
        this.handlerReturn = response
        this.adapterName = adapterName
    }

    public func respond(json: String): Unit {
        this.response.respondJson(json)
    }

    public func unauthorized(): Unit {
        this.response.unauthorized()
    }

    public func end(): Unit {
        this.response.end()
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
    if (name == "callback") {
        return AdapterStatusEntry(name, true, "supported", "Cangjie callback adapter for tests and host integrations.")
    }
    if (name == "http" || name == "https") {
        return AdapterStatusEntry(name, true, "supported", "Node http contract mirrored by WebhookRequest/WebhookResponse fakes.")
    }
    if (name == "express") {
        return AdapterStatusEntry(name, true, "supported", "Express-style req/res contract mirrored by WebhookRequest/WebhookResponse fakes.")
    }
    if (hasAdapterStatus(name)) {
        return AdapterStatusEntry(name, false, "not-applicable", "Registered for upstream compatibility; the JavaScript framework runtime is not directly available in Cangjie.")
    }
    AdapterStatusEntry(name, false, "unknown", "No upstream grammY adapter with this name is registered.")
}

public func adapterIsSupported(name: String): Bool {
    adapterStatus(name).supported
}

public func createReqResHandler(adapterName: String, request: WebhookRequest): ReqResHandler {
    if (!adapterIsSupported(adapterName)) {
        throw UnsupportedAdapterError(adapterName)
    }
    ReqResHandler(request.update, request.secretHeader(), WebhookResponse(), adapterName)
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
