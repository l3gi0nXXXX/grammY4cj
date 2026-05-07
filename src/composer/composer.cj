package grammy4cj.composer

import grammy4cj.context.Context
import grammy4cj.filter.matchFilter
import std.collection.HashMap

public type NextFunction = () -> Unit
public type MiddlewareFn = (Context, NextFunction) -> Unit
public type Predicate = (Context) -> Bool
public type MiddlewareFactory = (Context) -> MiddlewareFn
public type Router = (Context) -> String
public type ErrorHandler = (BotError, NextFunction) -> Unit

public class BotError <: Exception {
    public let error: Exception
    public let ctx: Context

    public init(message: String, ctx: Context) {
        super(message)
        this.error = Exception(message)
        this.ctx = ctx
    }

    public init(error: Exception, ctx: Context) {
        super("Exception in middleware: " + error.message)
        this.error = error
        this.ctx = ctx
    }
}

private class NextCallState {
    public var called: Bool = false

    public init() {}
}

public func pass(_ctx: Context, next: NextFunction): Unit {
    next()
}

public func concat(first: MiddlewareFn, andThen: MiddlewareFn): MiddlewareFn {
    { ctx: Context, next: NextFunction =>
        let nextCalled = NextCallState()
        first(ctx, { =>
            if (nextCalled.called) {
                throw Exception("`next` already called before!")
            }
            nextCalled.called = true
            andThen(ctx, next)
        })
    }
}

private func compose(middleware: Array<MiddlewareFn>): MiddlewareFn {
    var handler: MiddlewareFn = pass
    for (mw in middleware) {
        handler = concat(handler, mw)
    }
    handler
}

public func run(middleware: MiddlewareFn, ctx: Context): Unit {
    middleware(ctx, { => () })
}

public func run(composer: Composer, ctx: Context): Unit {
    run(composer.middleware(), ctx)
}

private func notPredicate(predicate: Predicate): Predicate {
    { ctx: Context => !predicate(ctx) }
}

private func queryPredicate(query: String): Predicate {
    { ctx: Context => matchFilter(query, ctx.update.kind) }
}

private func queryArrayPredicate(queries: Array<String>): Predicate {
    { ctx: Context => matchFilter(queries, ctx.update.kind) }
}

private func routeMiddleware(router: Router, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): MiddlewareFactory {
    { ctx: Context =>
        let route = router(ctx)
        if (route.isEmpty()) {
            return fallback
        }
        match (routeHandlers.get(route)) {
            case Some(mw) => mw
            case None => fallback
        }
    }
}

public class Composer {
    private var handler: MiddlewareFn = pass

    public init() {}

    public init(middleware: MiddlewareFn) {
        this.handler = middleware
    }

    public init(middleware: Array<MiddlewareFn>) {
        this.handler = compose(middleware)
    }

    public func middleware(): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handler(ctx, next)
        }
    }

    public func use(middleware: MiddlewareFn): Composer {
        this.use([middleware])
    }

    public func use(middleware: Array<MiddlewareFn>): Composer {
        let composer = Composer(middleware)
        this.handler = concat(this.handler, composer.middleware())
        composer
    }

    public func on(query: String): Composer {
        this.filter(queryPredicate(query))
    }

    public func on(query: String, middleware: MiddlewareFn): Composer {
        this.filter(queryPredicate(query), middleware)
    }

    public func on(queries: Array<String>): Composer {
        this.filter(queryArrayPredicate(queries))
    }

    public func on(queries: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(queryArrayPredicate(queries), middleware)
    }

    public func filter(predicate: Predicate): Composer {
        let composer = Composer()
        this.branch(predicate, composer.middleware(), pass)
        composer
    }

    public func filter(predicate: Predicate, middleware: MiddlewareFn): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func drop(predicate: Predicate): Composer {
        this.filter(notPredicate(predicate))
    }

    public func drop(predicate: Predicate, middleware: MiddlewareFn): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func lazy(factory: MiddlewareFactory): Composer {
        this.use({ ctx: Context, next: NextFunction =>
            let middleware = factory(ctx)
            middleware(ctx, next)
        })
    }

    public func route(router: Router, routeHandlers: HashMap<String, MiddlewareFn>): Composer {
        this.route(router, routeHandlers, pass)
    }

    public func route(router: Router, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): Composer {
        this.lazy(routeMiddleware(router, routeHandlers, fallback))
    }

    public func branch(predicate: Predicate, trueMiddleware: MiddlewareFn, falseMiddleware: MiddlewareFn): Composer {
        this.lazy({ ctx: Context =>
            if (predicate(ctx)) {
                trueMiddleware
            } else {
                falseMiddleware
            }
        })
    }

    public func errorBoundary(errorHandler: ErrorHandler): Composer {
        this.errorBoundary(errorHandler, pass)
    }

    public func errorBoundary(errorHandler: ErrorHandler, middleware: MiddlewareFn): Composer {
        let composer = Composer(middleware)
        let bound = composer.middleware()
        this.use({ ctx: Context, next: NextFunction =>
            let nextCalled = NextCallState()
            let cont: NextFunction = { =>
                nextCalled.called = true
            }
            try {
                bound(ctx, cont)
            } catch (err: Exception) {
                nextCalled.called = false
                errorHandler(BotError(err, ctx), cont)
            }
            if (nextCalled.called) {
                next()
            }
        })
        composer
    }

    public func layerName(): String {
        "Composer"
    }

    public func middlewareName(): String {
        "grammy4cj.composer.Composer"
    }
}
