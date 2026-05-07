package grammy4cj.convenience

import grammy4cj.core.WebhookReplyEnvelope
import grammy4cj.types.Update

public let WEBHOOK_TIMEOUT_THROW: String = "throw"
public let WEBHOOK_TIMEOUT_RETURN: String = "return"
public let WEBHOOK_TIMEOUT_FUNCTION: String = "function"

public class WebhookOptions {
    public let onTimeout: String
    public let timeoutMilliseconds: Int64
    public let secretToken: String

    public init() {
        this.onTimeout = WEBHOOK_TIMEOUT_THROW
        this.timeoutMilliseconds = 10000
        this.secretToken = ""
    }

    public init(secretToken: String) {
        this.onTimeout = WEBHOOK_TIMEOUT_THROW
        this.timeoutMilliseconds = 10000
        this.secretToken = secretToken
    }

    public init(onTimeout: String, timeoutMilliseconds: Int64, secretToken: String) {
        this.onTimeout = onTimeout
        this.timeoutMilliseconds = timeoutMilliseconds
        this.secretToken = secretToken
    }
}

public class WebhookTimeoutError <: Exception {
    public let timeoutMilliseconds: Int64

    public init(timeoutMilliseconds: Int64) {
        super("Request timed out after ${timeoutMilliseconds} ms")
        this.timeoutMilliseconds = timeoutMilliseconds
    }
}

public class FakeWebhookUpdateHandler {
    public var initialized: Bool = false
    public var initCount: Int64 = 0
    public var handleUpdateCount: Int64 = 0
    public var lastUpdateId: Int64 = 0
    public var delayMilliseconds: Int64 = 0
    public var webhookReplyJson: String = ""
    public var timeoutCallbackCount: Int64 = 0

    public init() {}

    public func ensureInitialized(): Unit {
        if (!this.initialized) {
            this.initialized = true
            this.initCount += 1
        }
    }

    public func handleUpdate(update: Update, webhookReplyEnvelope: WebhookReplyEnvelope): Unit {
        this.handleUpdateCount += 1
        this.lastUpdateId = update.updateId
        if (!this.webhookReplyJson.isEmpty()) {
            webhookReplyEnvelope.send(this.webhookReplyJson)
        }
    }

    public func onTimeout(): Unit {
        this.timeoutCallbackCount += 1
    }
}

public class WebhookCallbackResult {
    public let response: WebhookResponse
    public let unauthorized: Bool
    public let timedOut: Bool
    public let usedWebhookReply: Bool
    public let updateId: Int64

    public init(response: WebhookResponse, unauthorized: Bool, timedOut: Bool, usedWebhookReply: Bool, updateId: Int64) {
        this.response = response
        this.unauthorized = unauthorized
        this.timedOut = timedOut
        this.usedWebhookReply = usedWebhookReply
        this.updateId = updateId
    }
}

public class WebhookCallback {
    public let handler: FakeWebhookUpdateHandler
    public let adapterName: String
    public let options: WebhookOptions

    public init(handler: FakeWebhookUpdateHandler, adapterName: String, options: WebhookOptions) {
        this.handler = handler
        this.adapterName = adapterName
        this.options = options
    }

    public func handle(request: WebhookRequest): WebhookCallbackResult {
        let reqRes = createReqResHandler(this.adapterName, request)
        this.handler.ensureInitialized()

        if (!secretTokenMatches(reqRes.header, this.options.secretToken)) {
            reqRes.unauthorized()
            return WebhookCallbackResult(reqRes.handlerReturn, true, false, false, reqRes.update.updateId)
        }

        if (this.shouldTimeout()) {
            if (this.options.onTimeout == WEBHOOK_TIMEOUT_THROW) {
                throw WebhookTimeoutError(this.options.timeoutMilliseconds)
            }
            if (this.options.onTimeout == WEBHOOK_TIMEOUT_FUNCTION) {
                this.handler.onTimeout()
            }
            reqRes.end()
            return WebhookCallbackResult(reqRes.handlerReturn, false, true, false, reqRes.update.updateId)
        }

        let webhookReplyEnvelope = WebhookReplyEnvelope()
        this.handler.handleUpdate(reqRes.update, webhookReplyEnvelope)
        if (webhookReplyEnvelope.sent) {
            reqRes.respond(webhookReplyEnvelope.payload)
        } else {
            reqRes.end()
        }
        WebhookCallbackResult(reqRes.handlerReturn, false, false, webhookReplyEnvelope.sent, reqRes.update.updateId)
    }

    private func shouldTimeout(): Bool {
        this.options.timeoutMilliseconds >= 0 &&
            this.handler.delayMilliseconds > this.options.timeoutMilliseconds
    }
}

public func webhookCallback(handler: FakeWebhookUpdateHandler, adapterName: String): WebhookCallback {
    WebhookCallback(handler, adapterName, WebhookOptions())
}

public func webhookCallback(handler: FakeWebhookUpdateHandler, adapterName: String, options: WebhookOptions): WebhookCallback {
    WebhookCallback(handler, adapterName, options)
}

public func secretTokenMatches(header: String, token: String): Bool {
    if (token.isEmpty()) {
        return true
    }
    if (header.isEmpty()) {
        return false
    }
    header == token
}
