package grammy4cj.bot

import std.collection.ArrayList

import grammy4cj.composer.BotError
import grammy4cj.composer.Composer
import grammy4cj.composer.MiddlewareFn
import grammy4cj.composer.run
import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.core.ApiClientOptions
import grammy4cj.core.GrammyError
import grammy4cj.core.HttpError
import grammy4cj.filter.expandedFilterQueries
import grammy4cj.types.Update
import grammy4cj.types.UserFromGetMe

public class BotConfigError <: Exception {
    public init(message: String) {
        super(message)
    }
}

public class BotUpdateError <: Exception {
    public let updateId: Int64

    public init(updateId: Int64, message: String) {
        super(message)
        this.updateId = updateId
    }
}

public class BotConfig {
    public let client: ApiClientOptions
    public let botInfo: Option<UserFromGetMe>
    public let runtime: BotRuntime
    public let clock: BotClock
    public let retry: BotRetryConfig
    public let updateHandler: BotUpdateHandler

    public init(botInfo: UserFromGetMe) {
        this.client = ApiClientOptions()
        this.botInfo = Some(botInfo)
        this.runtime = OfflineBotRuntime()
        this.clock = NoopBotClock()
        this.retry = BotRetryConfig()
        this.updateHandler = NoopBotUpdateHandler()
    }

    public init(runtime: BotRuntime) {
        this.client = ApiClientOptions()
        this.botInfo = None<UserFromGetMe>
        this.runtime = runtime
        this.clock = NoopBotClock()
        this.retry = BotRetryConfig()
        this.updateHandler = NoopBotUpdateHandler()
    }

    public init(
        client!: ApiClientOptions = ApiClientOptions(),
        botInfo!: Option<UserFromGetMe> = None<UserFromGetMe>,
        runtime!: BotRuntime = OfflineBotRuntime(),
        clock!: BotClock = NoopBotClock(),
        retry!: BotRetryConfig = BotRetryConfig(),
        updateHandler!: BotUpdateHandler = NoopBotUpdateHandler()
    ) {
        this.client = client
        this.botInfo = botInfo
        this.runtime = runtime
        this.clock = clock
        this.retry = retry
        this.updateHandler = updateHandler
    }
}

public class Bot {
    public let token: String
    public let api: Api
    public let apiBoundary: BotApiBoundary
    private let composer: Composer = Composer()
    private let runtime: BotRuntime
    private let clock: BotClock
    private let retry: BotRetryConfig
    private var updateHandler: BotUpdateHandler
    private var errorHandler: Option<BotErrorHandler> = None<BotErrorHandler>
    private var me: Option<UserFromGetMe>
    private var initInFlight: Bool = false
    private var pollingRunning: Bool = false
    private var middlewareLocked: Bool = false
    private var lastTriedUpdate: Int64 = 0
    private let observedTypes = ArrayList<String>()
    private let warnings = ArrayList<String>()
    public var initRetryCount: Int64 = 0
    public var pollingErrorCount: Int64 = 0
    public var lastPollingError: String = ""

    public init(token: String) {
        if (token.isEmpty()) {
            throw BotConfigError("Empty token!")
        }
        let config = BotConfig()
        this.token = token
        this.api = Api(token, config.client)
        this.apiBoundary = BotApiBoundary(token, config.client)
        this.runtime = config.runtime
        this.clock = config.clock
        this.retry = config.retry
        this.updateHandler = config.updateHandler
        this.me = config.botInfo
    }

    public init(token: String, config: BotConfig) {
        if (token.isEmpty()) {
            throw BotConfigError("Empty token!")
        }
        this.token = token
        this.api = Api(token, config.client)
        this.apiBoundary = BotApiBoundary(token, config.client)
        this.runtime = config.runtime
        this.clock = config.clock
        this.retry = config.retry
        this.updateHandler = config.updateHandler
        this.me = config.botInfo
    }

    public mut prop botInfo: UserFromGetMe {
        get() {
            match (this.me) {
                case Some(info) => info
                case None => throw BotConfigError("Bot information unavailable! Call bot.init() or pass botInfo to BotConfig.")
            }
        }
        set(value) {
            this.me = Some(value)
        }
    }

    public func isInited(): Bool {
        match (this.me) {
            case Some(_) => true
            case None => false
        }
    }

    public func markInitialized(): Unit {
        this.me = Some(defaultBotInfo())
    }

    public func `init`(): Unit {
        if (this.isInited() || this.initInFlight) {
            return
        }
        this.initInFlight = true
        try {
            let info = this.getMeWithRetries()
            if (!this.isInited()) {
                this.me = Some(info)
            }
        } finally {
            this.initInFlight = false
        }
    }

    public func useApiTransformer(transformerName: String): Bot {
        this.apiBoundary.use(transformerName)
        this
    }

    public func installedApiTransformers(): Array<String> {
        this.apiBoundary.installedTransformers()
    }

    public func setUpdateHandler(handler: BotUpdateHandler): Unit {
        this.updateHandler = handler
    }

    public func `catch`(handler: BotErrorHandler): Unit {
        this.errorHandler = Some(handler)
    }

    public func middleware(): MiddlewareFn {
        this.composer.middleware()
    }

    public func use(middleware: MiddlewareFn): Composer {
        this.assertMiddlewareRegistrationAllowed()
        this.composer.use(middleware)
    }

    public func use(middleware: Array<MiddlewareFn>): Composer {
        this.assertMiddlewareRegistrationAllowed()
        this.composer.use(middleware)
    }

    public func on(query: String): Composer {
        this.assertMiddlewareRegistrationAllowed()
        this.observeFilterQuery(query)
        this.composer.on(query)
    }

    public func on(query: String, middleware: MiddlewareFn): Composer {
        this.assertMiddlewareRegistrationAllowed()
        this.observeFilterQuery(query)
        this.composer.on(query, middleware)
    }

    public func on(queries: Array<String>): Composer {
        this.assertMiddlewareRegistrationAllowed()
        this.observeFilterQueries(queries)
        this.composer.on(queries)
    }

    public func on(queries: Array<String>, middleware: MiddlewareFn): Composer {
        this.assertMiddlewareRegistrationAllowed()
        this.observeFilterQueries(queries)
        this.composer.on(queries, middleware)
    }

    public func reaction(reaction: String, middleware: MiddlewareFn): Composer {
        this.assertMiddlewareRegistrationAllowed()
        this.observeUpdateType("message_reaction")
        this.composer.filter(
            { ctx: Context => ctx.hasReaction(reaction) },
            middleware
        )
    }

    public func observeUpdateType(updateType: String): Unit {
        if (!arrayContains(this.observedTypes.toArray(), updateType)) {
            this.observedTypes.add(updateType)
        }
    }

    public func observedUpdateTypes(): Array<String> {
        this.observedTypes.toArray()
    }

    public func warningMessages(): Array<String> {
        this.warnings.toArray()
    }

    public func handleUpdate(update: Update): Unit {
        if (!this.isInited()) {
            throw BotConfigError("Bot not initialized! Call bot.init() or pass botInfo to BotConfig.")
        }
        let ctx = Context(update, Api(this.token, this.api.config), this.botInfo)
        try {
            run(this.composer, ctx)
            let apiForUpdate = this.apiBoundary.copyForUpdate()
            let boundary = BotUpdateContextBoundary(update, apiForUpdate, this.botInfo)
            this.updateHandler.handle(boundary)
        } catch (e: BotError) {
            throw e
        } catch (e: Exception) {
            throw BotError(e, ctx)
        }
    }

    public func start(): Unit {
        this.start(PollingOptions())
    }

    public func start(options: PollingOptions): Unit {
        if (this.pollingRunning) {
            if (!this.isInited()) {
                this.`init`()
            }
            return
        }

        this.pollingRunning = true
        try {
            if (!this.isInited()) {
                this.`init`()
            }
            this.deleteWebhookWithRetries(options.dropPendingUpdates)
            match (options.onStart) {
                case Some(hook) => hook(this.botInfo)
                case None => ()
            }
            this.validateAllowedUpdates(if (options.allowedUpdatesSpecified) { options.allowedUpdates } else { defaultUpdateTypes() })
        } catch (e: Exception) {
            this.pollingRunning = false
            throw e
        }

        if (!this.pollingRunning) {
            return
        }
        this.loop(options)
    }

    public func stop(): Unit {
        if (!this.pollingRunning) {
            return
        }
        this.pollingRunning = false
        let offset = this.lastTriedUpdate + 1
        let request = PollingFetchRequest(offset, 1, 0, [], false)
        let _ = this.runtime.getUpdates(request)
    }

    public func isRunning(): Bool {
        this.pollingRunning
    }

    public func lastTriedUpdateId(): Int64 {
        this.lastTriedUpdate
    }

    private func loop(options: PollingOptions): Unit {
        var includeAllowedUpdates = true
        var cycles: Int64 = 0
        this.middlewareLocked = true
        try {
            while (this.pollingRunning && cycles < options.maxFetchCycles) {
                let allowed = if (includeAllowedUpdates) {
                    if (options.allowedUpdatesSpecified) { options.allowedUpdates } else { Array<String>() }
                } else {
                    Array<String>()
                }
                let updates = this.fetchUpdates(
                    options.limit,
                    options.timeoutSeconds,
                    allowed,
                    includeAllowedUpdates
                )
                if (!this.pollingRunning) {
                    return
                }
                this.handleUpdates(updates)
                includeAllowedUpdates = false
                cycles += 1
            }
        } finally {
            if (this.pollingRunning) {
                this.pollingRunning = false
            }
        }
    }

    private func handleUpdates(updates: Array<Update>): Unit {
        for (update in updates) {
            this.lastTriedUpdate = update.updateId
            try {
                this.handleUpdate(update)
            } catch (e: BotError) {
                this.handleMiddlewareError(e)
            }
        }
    }

    private func fetchUpdates(
        limit: Int64,
        timeoutSeconds: Int64,
        allowedUpdates: Array<String>,
        includesAllowedUpdates: Bool
    ): Array<Update> {
        while (this.pollingRunning) {
            let request = PollingFetchRequest(
                this.lastTriedUpdate + 1,
                limit,
                timeoutSeconds,
                allowedUpdates,
                includesAllowedUpdates
            )
            try {
                return this.runtime.getUpdates(request)
            } catch (e: GrammyError) {
                this.handlePollingGrammyError(e)
            } catch (e: HttpError) {
                this.handlePollingError(e.message, 3000)
            } catch (e: Exception) {
                this.handlePollingError(e.message, 3000)
            }
        }
        []
    }

    private func getMeWithRetries(): UserFromGetMe {
        var nextDelay = this.retry.initialDelayMillis
        while (true) {
            try {
                return this.runtime.getMe()
            } catch (e: HttpError) {
                nextDelay = this.retryAfterInitFailure(nextDelay)
            } catch (e: GrammyError) {
                if (e.errorCode >= 500) {
                    nextDelay = this.retryAfterInitFailure(nextDelay)
                } else if (e.errorCode == 429) {
                    let retryAfterMillis = e.parameters.retryAfter * 1000
                    if (retryAfterMillis > 0) {
                        this.clock.sleep(retryAfterMillis)
                        nextDelay = this.retry.initialDelayMillis
                    } else {
                        nextDelay = this.retryAfterInitFailure(nextDelay)
                    }
                } else {
                    throw e
                }
            } catch (e: Exception) {
                throw e
            }
        }
        defaultBotInfo()
    }

    private func deleteWebhookWithRetries(dropPendingUpdates: Bool): Unit {
        var nextDelay = this.retry.initialDelayMillis
        while (true) {
            try {
                this.runtime.deleteWebhook(dropPendingUpdates)
                return
            } catch (e: HttpError) {
                nextDelay = this.retryAfterInitFailure(nextDelay)
            } catch (e: GrammyError) {
                if (e.errorCode >= 500) {
                    nextDelay = this.retryAfterInitFailure(nextDelay)
                } else if (e.errorCode == 429) {
                    let retryAfterMillis = e.parameters.retryAfter * 1000
                    if (retryAfterMillis > 0) {
                        this.clock.sleep(retryAfterMillis)
                        nextDelay = this.retry.initialDelayMillis
                    } else {
                        nextDelay = this.retryAfterInitFailure(nextDelay)
                    }
                } else {
                    throw e
                }
            } catch (e: Exception) {
                throw e
            }
        }
    }

    private func retryAfterInitFailure(nextDelay: Int64): Int64 {
        this.initRetryCount += 1
        if (nextDelay != this.retry.initialDelayMillis) {
            this.clock.sleep(nextDelay)
        }
        let doubled = nextDelay * 2
        if (doubled > this.retry.maxDelayMillis) {
            this.retry.maxDelayMillis
        } else {
            doubled
        }
    }

    private func handlePollingGrammyError(error: GrammyError): Unit {
        if (error.errorCode == 401 || error.errorCode == 409) {
            throw error
        }
        let retryMillis = if (error.errorCode == 429 && error.parameters.retryAfter > 0) {
            error.parameters.retryAfter * 1000
        } else {
            3000
        }
        this.handlePollingError(error.message, retryMillis)
    }

    private func handlePollingError(message: String, retryMillis: Int64): Unit {
        if (!this.pollingRunning) {
            return
        }
        this.pollingErrorCount += 1
        this.lastPollingError = message
        this.clock.sleep(retryMillis)
    }

    private func validateAllowedUpdates(allowedUpdates: Array<String>): Unit {
        for (updateType in this.observedTypes) {
            if (!arrayContains(allowedUpdates, updateType)) {
                this.warnings.add("Observed update type '${updateType}' is not present in allowed_updates.")
            }
        }
    }

    private func handleMiddlewareError(error: BotError): Unit {
        match (this.errorHandler) {
            case Some(handler) => handler.handle(error)
            case None =>
                if (this.pollingRunning) {
                    this.stop()
                }
                throw error
        }
    }

    private func assertMiddlewareRegistrationAllowed(): Unit {
        if (this.middlewareLocked) {
            throw BotConfigError("Cannot register middleware after the bot has started polling.")
        }
    }

    private func observeFilterQuery(query: String): Unit {
        for (path in expandedFilterQueries(query)) {
            this.observeUpdateType(firstFilterSegment(path))
        }
    }

    private func observeFilterQueries(queries: Array<String>): Unit {
        for (path in expandedFilterQueries(queries)) {
            this.observeUpdateType(firstFilterSegment(path))
        }
    }
}

private func arrayContains(values: Array<String>, needle: String): Bool {
    for (value in values) {
        if (value == needle) {
            return true
        }
    }
    false
}

private func firstFilterSegment(path: String): String {
    match (path.indexOf(":")) {
        case Some(index) => path[0..index]
        case None => path
    }
}
