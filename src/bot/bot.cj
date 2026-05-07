package grammy4cj.bot

import grammy4cj.core.Api

public class BotConfigError <: Exception {
    public init(message: String) {
        super(message)
    }
}

public class Bot {
    public let token: String
    public let api: Api
    private var initialized: Bool = false

    public init(token: String) {
        if (token.isEmpty()) {
            throw BotConfigError("Empty token!")
        }
        this.token = token
        this.api = Api(token)
    }

    public func isInited(): Bool {
        this.initialized
    }

    public func markInitialized(): Unit {
        this.initialized = true
    }
}
