package grammy4cj.convenience

import std.sync.{Condition, Mutex}
import std.time.DateTime

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
    public var simulatedDelayProbeCount: Int64 = 0
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
        sleepMilliseconds(this.delayMilliseconds)
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
        this.simulatedDelayProbeCount += 1
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

private class WebhookTaskResult {
    public let usedWebhookReply: Bool
    public let updateId: Int64

    public init(usedWebhookReply: Bool, updateId: Int64) {
        this.usedWebhookReply = usedWebhookReply
        this.updateId = updateId
    }
}

private class WebhookRaceState {
    public var settled: Bool = false
    public var timedOut: Bool = false
    public var winner: String = ""
    public var outcome: Option<WebhookTaskResult> = None<WebhookTaskResult>
    public var failure: Option<Exception> = None<Exception>

    public init() {}
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

        reqRes.response.timeoutRaceStarted = true
        let task = spawn { => this.runWebhookTask(reqRes) }
        let race = this.timeoutIfNecessary(task, reqRes)
        if (race.timedOut) {
            return this.handleTimeout(reqRes)
        }
        match (race.failure) {
            case Some(err) => throw err
            case None => ()
        }
        let outcome = match (race.outcome) {
            case Some(value) => value
            case None => WebhookTaskResult(false, 0)
        }
        if (!outcome.usedWebhookReply) {
            reqRes.end()
        }
        WebhookCallbackResult(reqRes.handlerReturn, false, false, outcome.usedWebhookReply, outcome.updateId)
    }

    private func rejectLongPollingConflict(): Unit {
        if (this.handler.hasLongPollingConflict()) {
            throw WebhookLongPollingConflictError(
                "Bot is already running via long polling, the webhook setup won't receive any updates!"
            )
        }
    }

    private func timeoutEnabled(): Bool {
        this.options.timeoutMilliseconds >= 0
    }

    private func runWebhookTask(reqRes: ReqResHandler): WebhookTaskResult {
        sleepMilliseconds(reqRes.updateDelayMilliseconds)
        let update = reqRes.update
        let webhookReplyEnvelope = WebhookReplyEnvelope()
        this.handler.handleUpdate(update, webhookReplyEnvelope)
        if (webhookReplyEnvelope.sent) {
            if (reqRes.response.timeoutRaceWinner == "timeout") {
                reqRes.response.recordLateWebhookReply(webhookReplyEnvelope.payload)
            } else {
                reqRes.respond(webhookReplyEnvelope.payload)
            }
        }
        WebhookTaskResult(webhookReplyEnvelope.sent, update.updateId)
    }

    private func timeoutIfNecessary(task: Future<WebhookTaskResult>, reqRes: ReqResHandler): WebhookRaceState {
        if (!this.timeoutEnabled()) {
            let state = WebhookRaceState()
            try {
                state.outcome = Some(task.get())
            } catch (err: Exception) {
                state.failure = Some(err)
            }
            state.settled = true
            state.winner = "task"
            reqRes.response.timeoutRaceWinner = "task"
            return state
        }

        let state = WebhookRaceState()
        let mutex = Mutex()
        let condition: Condition = synchronized(mutex) { mutex.condition() }
        spawn { =>
            try {
                let outcome = task.get()
                synchronized(mutex) {
                    if (!state.settled) {
                        state.outcome = Some(outcome)
                        state.settled = true
                        state.winner = "task"
                        reqRes.response.timeoutRaceWinner = "task"
                        condition.notifyAll()
                    } else if (state.timedOut) {
                        reqRes.response.recordLateCompletion()
                    }
                }
            } catch (err: Exception) {
                synchronized(mutex) {
                    if (!state.settled) {
                        state.failure = Some(err)
                        state.settled = true
                        state.winner = "task"
                        reqRes.response.timeoutRaceWinner = "task"
                        condition.notifyAll()
                    } else if (state.timedOut) {
                        reqRes.response.recordLateError(err.message)
                    }
                }
            }
        }
        spawn { =>
            if (waitForTimeout(this.options.timeoutMilliseconds, state, mutex)) {
                synchronized(mutex) {
                    if (!state.settled) {
                        state.timedOut = true
                        state.settled = true
                        state.winner = "timeout"
                        reqRes.response.timeoutRaceWinner = "timeout"
                        condition.notifyAll()
                    }
                }
            }
        }
        synchronized(mutex) {
            condition.waitUntil({ => state.settled })
        }
        state
    }

    private func handleTimeout(reqRes: ReqResHandler): WebhookCallbackResult {
        if (this.options.onTimeout == WEBHOOK_TIMEOUT_THROW) {
            throw WebhookTimeoutError(this.options.timeoutMilliseconds)
        }
        this.runTimeoutCallback()
        reqRes.end()
        WebhookCallbackResult(reqRes.handlerReturn, false, true, false, 0)
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

private func waitForTimeout(milliseconds: Int64, state: WebhookRaceState, mutex: Mutex): Bool {
    if (milliseconds <= 0) {
        return true
    }
    let deadline = nowMilliseconds() + milliseconds
    while (nowMilliseconds() < deadline) {
        var alreadySettled = false
        synchronized(mutex) {
            alreadySettled = state.settled
        }
        if (alreadySettled) {
            return false
        }
    }
    true
}

private func sleepMilliseconds(milliseconds: Int64): Unit {
    if (milliseconds <= 0) {
        return
    }
    let deadline = nowMilliseconds() + milliseconds
    while (nowMilliseconds() < deadline) {
        ()
    }
}

private func nowMilliseconds(): Int64 {
    DateTime.now().toUnixTimeStamp().toMilliseconds()
}
