package grammy4cj.composer

import grammy4cj.context.Context

public type NextFunction = () -> Unit
public type MiddlewareFn = (Context, NextFunction) -> Unit

public class BotError <: Exception {
    public let ctx: Context

    public init(message: String, ctx: Context) {
        super(message)
        this.ctx = ctx
    }
}

public class Composer {
    public init() {}

    public func layerName(): String {
        "Composer"
    }

    public func middlewareName(): String {
        "grammy4cj.composer.Composer"
    }
}
