package grammy4cj.convenience

import std.collection.ArrayList

import grammy4cj.bot.Bot
import grammy4cj.core.WebhookReplyEnvelope
import grammy4cj.types.Update

public let WEBHOOK_TIMEOUT_THROW: String = "throw"
public let WEBHOOK_TIMEOUT_RETURN: String = "return"
public let WEBHOOK_TIMEOUT_FUNCTION: String = "function"

public type WebhookTimeoutCallback = () -> Unit

public class WebhookOptions {
    public let onTimeout: String
    public let timeoutMilliseconds: Int64
    public let secretToken: String
    public let secretTokenConfigured: Bool
    public let timeoutCallback: Option<WebhookTimeoutCallback>

    public init() {
        this.onTimeout = WEBHOOK_TIMEOUT_THROW
        this.timeoutMilliseconds = 10000
        this.secretToken = ""
        this.secretTokenConfigured = false
        this.timeoutCallback = None<WebhookTimeoutCallback>
    }

    public init(secretToken: String) {
        this.onTimeout = WEBHOOK_TIMEOUT_THROW
        this.timeoutMilliseconds = 10000
        this.secretToken = secretToken
        this.secretTokenConfigured = true
        this.timeoutCallback = None<WebhookTimeoutCallback>
    }

    public init(onTimeout: String, timeoutMilliseconds: Int64, secretToken: String) {
        this.onTimeout = onTimeout
        this.timeoutMilliseconds = timeoutMilliseconds
        this.secretToken = secretToken
        this.secretTokenConfigured = !secretToken.isEmpty()
        this.timeoutCallback = None<WebhookTimeoutCallback>
    }

    public init(onTimeout: String, timeoutMilliseconds: Int64, secretToken: String, secretTokenConfigured: Bool) {
        this.onTimeout = onTimeout
        this.timeoutMilliseconds = timeoutMilliseconds
        this.secretToken = secretToken
        this.secretTokenConfigured = secretTokenConfigured
        this.timeoutCallback = None<WebhookTimeoutCallback>
    }

    public init(onTimeout: WebhookTimeoutCallback, timeoutMilliseconds: Int64, secretToken: String) {
        this.onTimeout = WEBHOOK_TIMEOUT_FUNCTION
        this.timeoutMilliseconds = timeoutMilliseconds
        this.secretToken = secretToken
        this.secretTokenConfigured = !secretToken.isEmpty()
        this.timeoutCallback = Some(onTimeout)
    }
}

public class WebhookTimeoutError <: Exception {
    public let timeoutMilliseconds: Int64

    public init(timeoutMilliseconds: Int64) {
        super("Request timed out after ${timeoutMilliseconds} ms")
        this.timeoutMilliseconds = timeoutMilliseconds
    }
}

public class WebhookLongPollingConflictError <: Exception {
    public init(message: String) {
        super(message)
    }
}

public class WebhookUpdateFailureError <: Exception {
    public init(message: String) {
        super(message)
    }
}

public interface WebhookUpdateHandler {
    func ensureInitialized(): Unit
    func handleUpdate(update: Update, webhookReplyEnvelope: WebhookReplyEnvelope): Unit
    func onTimeout(): Unit
    func simulatedDelayMilliseconds(): Int64
    func hasLongPollingConflict(): Bool
}

public class FakeWebhookUpdateHandler <: WebhookUpdateHandler {
    public var initialized: Bool = false
    public var initCount: Int64 = 0
    public var handleUpdateCount: Int64 = 0
    public var lastUpdateId: Int64 = 0
    public let handledUpdateIds: ArrayList<Int64> = ArrayList<Int64>()
    public var delayMilliseconds: Int64 = 0
    public var webhookReplyJson: String = ""
    public var timeoutCallbackCount: Int64 = 0
    public var failureMessage: String = ""
    public var failOnUpdateId: Int64 = -1

    public init() {}

    override public func ensureInitialized(): Unit {
        if (!this.initialized) {
            this.initialized = true
            this.initCount += 1
        }
    }

    override public func handleUpdate(update: Update, webhookReplyEnvelope: WebhookReplyEnvelope): Unit {
        this.handleUpdateCount += 1
        this.lastUpdateId = update.updateId
        this.handledUpdateIds.add(update.updateId)
        if (!this.failureMessage.isEmpty() && (this.failOnUpdateId < 0 || this.failOnUpdateId == update.updateId)) {
            throw WebhookUpdateFailureError(this.failureMessage)
        }
        if (!this.webhookReplyJson.isEmpty()) {
            webhookReplyEnvelope.send(this.webhookReplyJson)
        }
    }

    override public func onTimeout(): Unit {
        this.timeoutCallbackCount += 1
    }

    override public func simulatedDelayMilliseconds(): Int64 {
        this.delayMilliseconds
    }

    override public func hasLongPollingConflict(): Bool {
        false
    }
}

public class BotWebhookUpdateHandler <: WebhookUpdateHandler {
    public let bot: Bot
    public var initCount: Int64 = 0
    public var handleUpdateCount: Int64 = 0
    public var lastUpdateId: Int64 = 0
    public var timeoutCallbackCount: Int64 = 0

    public init(bot: Bot) {
        this.bot = bot
    }

    override public func ensureInitialized(): Unit {
        if (!this.bot.isInited()) {
            this.initCount += 1
        }
        this.bot.`init`()
    }

    override public func handleUpdate(update: Update, webhookReplyEnvelope: WebhookReplyEnvelope): Unit {
        this.handleUpdateCount += 1
        this.lastUpdateId = update.updateId
        this.bot.handleUpdate(update, webhookReplyEnvelope)
    }

    override public func onTimeout(): Unit {
        this.timeoutCallbackCount += 1
    }

    override public func simulatedDelayMilliseconds(): Int64 {
        0
    }

    override public func hasLongPollingConflict(): Bool {
        this.bot.isRunning()
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
    public let handler: WebhookUpdateHandler
    public let adapterName: String
    public let adapter: FrameworkAdapter
    public let options: WebhookOptions
    private var initialized: Bool = false

    public init(handler: WebhookUpdateHandler, adapterName: String, options: WebhookOptions) {
        this.handler = handler
        this.adapterName = adapterName
        this.adapter = adapterForWebhook(adapterName)
        this.options = options
    }

    public init(handler: WebhookUpdateHandler, adapterName: String, adapter: FrameworkAdapter, options: WebhookOptions) {
        this.handler = handler
        this.adapterName = adapterName
        this.adapter = adapter
        this.options = options
    }

    public func handle(request: WebhookRequest): WebhookCallbackResult {
        this.rejectLongPollingConflict()
        let reqRes = this.adapter(request)
        if (!this.initialized) {
            this.handler.ensureInitialized()
            this.initialized = true
        }

        if (!secretTokenMatches(reqRes.header, this.options.secretToken, this.options.secretTokenConfigured, reqRes.headerPresent)) {
            reqRes.unauthorized()
            return WebhookCallbackResult(reqRes.handlerReturn, true, false, false, 0)
        }

        let updateDelay = reqRes.updateDelayMilliseconds
        let handlerDelay = this.handler.simulatedDelayMilliseconds()
        if (this.updateSourceTimesOut(updateDelay)) {
            return this.timeoutBeforeUpdateResolves(reqRes)
        }

        let update = reqRes.update
        if (this.updateHandlerTimesOut(updateDelay, handlerDelay)) {
            return this.timeoutAfterUpdateResolves(reqRes, update)
        }

        let webhookReplyEnvelope = WebhookReplyEnvelope()
        this.handler.handleUpdate(update, webhookReplyEnvelope)
        if (webhookReplyEnvelope.sent) {
            reqRes.respond(webhookReplyEnvelope.payload)
        } else {
            reqRes.end()
        }
        WebhookCallbackResult(reqRes.handlerReturn, false, false, webhookReplyEnvelope.sent, update.updateId)
    }

    private func rejectLongPollingConflict(): Unit {
        if (this.handler.hasLongPollingConflict()) {
            throw WebhookLongPollingConflictError(
                "Bot is already running via long polling, the webhook setup won't receive any updates!"
            )
        }
    }

    private func updateSourceTimesOut(updateDelayMilliseconds: Int64): Bool {
        this.timeoutEnabled() && updateDelayMilliseconds > this.options.timeoutMilliseconds
    }

    private func updateHandlerTimesOut(updateDelayMilliseconds: Int64, handlerDelayMilliseconds: Int64): Bool {
        this.timeoutEnabled() &&
            updateDelayMilliseconds + handlerDelayMilliseconds > this.options.timeoutMilliseconds
    }

    private func timeoutEnabled(): Bool {
        this.options.timeoutMilliseconds >= 0
    }

    private func timeoutBeforeUpdateResolves(reqRes: ReqResHandler): WebhookCallbackResult {
        if (this.options.onTimeout == WEBHOOK_TIMEOUT_THROW) {
            this.recordBackgroundUpdate(reqRes)
            throw WebhookTimeoutError(this.options.timeoutMilliseconds)
        }
        this.runTimeoutCallback()
        reqRes.end()
        this.recordBackgroundUpdate(reqRes)
        WebhookCallbackResult(reqRes.handlerReturn, false, true, false, 0)
    }

    private func timeoutAfterUpdateResolves(reqRes: ReqResHandler, update: Update): WebhookCallbackResult {
        if (this.options.onTimeout == WEBHOOK_TIMEOUT_THROW) {
            this.recordBackgroundUpdate(reqRes, update)
            throw WebhookTimeoutError(this.options.timeoutMilliseconds)
        }
        this.runTimeoutCallback()
        reqRes.end()
        this.recordBackgroundUpdate(reqRes, update)
        WebhookCallbackResult(reqRes.handlerReturn, false, true, false, update.updateId)
    }

    private func runTimeoutCallback(): Unit {
        if (this.options.onTimeout != WEBHOOK_TIMEOUT_FUNCTION) {
            return
        }
        match (this.options.timeoutCallback) {
            case Some(callback) => callback()
            case None => this.handler.onTimeout()
        }
    }

    private func recordBackgroundUpdate(reqRes: ReqResHandler): Unit {
        try {
            this.recordBackgroundUpdate(reqRes, reqRes.update)
        } catch (_e: Exception) {
            ()
        }
    }

    private func recordBackgroundUpdate(reqRes: ReqResHandler, update: Update): Unit {
        let envelope = WebhookReplyEnvelope()
        try {
            this.handler.handleUpdate(update, envelope)
            if (envelope.sent) {
                reqRes.response.lateWebhookReplySent = true
                reqRes.response.lateWebhookReplyPayload = envelope.payload
            }
        } catch (_e: Exception) {
            ()
        }
    }
}

public func webhookCallback(handler: FakeWebhookUpdateHandler, adapterName: String): WebhookCallback {
    WebhookCallback(handler, adapterName, WebhookOptions())
}

public func webhookCallback(handler: FakeWebhookUpdateHandler, adapterName: String, options: WebhookOptions): WebhookCallback {
    WebhookCallback(handler, adapterName, options)
}

public func webhookCallback(handler: FakeWebhookUpdateHandler, adapterName: String, onTimeout: String, timeoutMilliseconds: Int64, secretToken: String): WebhookCallback {
    WebhookCallback(handler, adapterName, WebhookOptions(onTimeout, timeoutMilliseconds, secretToken, true))
}

public func webhookCallback(handler: FakeWebhookUpdateHandler, adapter: FrameworkAdapter): WebhookCallback {
    WebhookCallback(handler, "custom", adapter, WebhookOptions())
}

public func webhookCallback(handler: FakeWebhookUpdateHandler, adapter: FrameworkAdapter, options: WebhookOptions): WebhookCallback {
    WebhookCallback(handler, "custom", adapter, options)
}

public func webhookCallback(bot: Bot, adapterName: String): WebhookCallback {
    webhookCallback(bot, adapterName, WebhookOptions())
}

public func webhookCallback(bot: Bot, adapterName: String, options: WebhookOptions): WebhookCallback {
    if (bot.isRunning()) {
        throw WebhookLongPollingConflictError(
            "Bot is already running via long polling, the webhook setup won't receive any updates!"
        )
    }
    bot.forbidPollingStart(
        "You already started the bot via webhooks, calling bot.start() starts the bot with long polling and this will prevent your webhook setup from receiving any updates!"
    )
    WebhookCallback(BotWebhookUpdateHandler(bot), adapterName, options)
}

public func webhookCallback(bot: Bot, adapterName: String, onTimeout: String, timeoutMilliseconds: Int64, secretToken: String): WebhookCallback {
    webhookCallback(bot, adapterName, WebhookOptions(onTimeout, timeoutMilliseconds, secretToken, true))
}

public func webhookCallback(bot: Bot, adapter: FrameworkAdapter): WebhookCallback {
    webhookCallback(bot, adapter, WebhookOptions())
}

public func webhookCallback(bot: Bot, adapter: FrameworkAdapter, options: WebhookOptions): WebhookCallback {
    if (bot.isRunning()) {
        throw WebhookLongPollingConflictError(
            "Bot is already running via long polling, the webhook setup won't receive any updates!"
        )
    }
    bot.forbidPollingStart(
        "You already started the bot via webhooks, calling bot.start() starts the bot with long polling and this will prevent your webhook setup from receiving any updates!"
    )
    WebhookCallback(BotWebhookUpdateHandler(bot), "custom", adapter, options)
}

private func adapterForWebhook(adapterName: String): FrameworkAdapter {
    if (adapterName == "callback") {
        return callbackRequestAdapter
    }
    frameworkAdapter(adapterName)
}

public func secretTokenMatches(header: String, token: String): Bool {
    secretTokenMatches(header, token, !token.isEmpty(), !header.isEmpty())
}

public func secretTokenMatches(header: String, token: String, tokenConfigured: Bool, headerPresent: Bool): Bool {
    if (!tokenConfigured) {
        return true
    }
    if (!headerPresent) {
        return false
    }
    constantTimeStringEquals(header, token)
}

public func constantTimeStringEquals(left: String, right: String): Bool {
    let maxSize = if (left.size > right.size) { left.size } else { right.size }
    var hasDifference = left.size != right.size
    var i: Int64 = 0
    while (i < maxSize) {
        let leftChar = if (i < left.size) { left[i..i + 1] } else { "" }
        let rightChar = if (i < right.size) { right[i..i + 1] } else { "" }
        if (leftChar != rightChar) {
            hasDifference = true
        }
        i += 1
    }
    !hasDifference
}
