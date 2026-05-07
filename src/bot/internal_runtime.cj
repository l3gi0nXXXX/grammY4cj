package grammy4cj.bot

import std.collection.ArrayList

import grammy4cj.core.ApiClientOptions
import grammy4cj.core.WebhookReplyEnvelope
import grammy4cj.types.Update
import grammy4cj.types.UserFromGetMe

public type BotStartHook = (UserFromGetMe) -> Unit

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

public interface BotRuntime {
    func getMe(): UserFromGetMe
    func deleteWebhook(dropPendingUpdates: Bool): Unit
    func getUpdates(request: PollingFetchRequest): Array<Update>
}

public class OfflineBotRuntime <: BotRuntime {
    public init() {}

    override public func getMe(): UserFromGetMe {
        defaultBotInfo()
    }

    override public func deleteWebhook(dropPendingUpdates: Bool): Unit {
        ()
    }

    override public func getUpdates(request: PollingFetchRequest): Array<Update> {
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

    override public func getMe(): UserFromGetMe {
        this.getMeCalls += 1
        if (this.getMeErrorCursor < this.getMeErrors.size) {
            let err = this.getMeErrors[this.getMeErrorCursor]
            this.getMeErrorCursor += 1
            throw err
        }
        this.getMeResult
    }

    override public func deleteWebhook(dropPendingUpdates: Bool): Unit {
        this.deleteWebhookCalls += 1
        this.lastDropPendingUpdates = dropPendingUpdates
        if (this.deleteWebhookErrorCursor < this.deleteWebhookErrors.size) {
            let err = this.deleteWebhookErrors[this.deleteWebhookErrorCursor]
            this.deleteWebhookErrorCursor += 1
            throw err
        }
    }

    override public func getUpdates(request: PollingFetchRequest): Array<Update> {
        this.getUpdatesCalls += 1
        this.pollingRequests.add(request)
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
