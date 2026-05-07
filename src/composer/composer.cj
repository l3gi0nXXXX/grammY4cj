package grammy4cj.composer

import grammy4cj.context.Context
import grammy4cj.filter.matchFilter
import grammy4cj.types.ReactionType
import std.collection.HashMap

public type NextFunction = () -> Unit
public type MiddlewareFn = (Context, NextFunction) -> Unit
public type Predicate = (Context) -> Bool
public type MiddlewareFactory = (Context) -> MiddlewareFn
public type MiddlewareArrayFactory = (Context) -> Array<MiddlewareFn>
public type ComposerFactory = (Context) -> Composer
public type Router = (Context) -> Option<String>
public type ErrorHandler = (BotError, NextFunction) -> Unit

public class ComposerMaybePromiseDecision {
    public let callbackContract: String
    public let futureBoundary: String
    public let forkJoinContract: String
    public let routeFallbackContract: String

    public init(callbackContract: String, futureBoundary: String, forkJoinContract: String, routeFallbackContract: String) {
        this.callbackContract = callbackContract
        this.futureBoundary = futureBoundary
        this.forkJoinContract = forkJoinContract
        this.routeFallbackContract = routeFallbackContract
    }
}

public func composerMaybePromiseDecision(): ComposerMaybePromiseDecision {
    ComposerMaybePromiseDecision(
        "sync-callback",
        "Future work must be joined before the callback returns",
        "fork spawns downstream and forked middleware, then joins downstream before fork",
        "None<String> route values select fallback",
    )
}

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

private func hasPredicate(predicate: (Context) -> Bool): Predicate {
    { ctx: Context => predicate(ctx) }
}

private func queryPredicate(query: String): Predicate {
    { ctx: Context => matchFilter(query, ctx) }
}

private func queryArrayPredicate(queries: Array<String>): Predicate {
    { ctx: Context => matchFilter(queries, ctx) }
}

private func routeMiddleware(router: Router, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): MiddlewareFactory {
    { ctx: Context =>
        match (router(ctx)) {
            case Some(route) =>
                match (routeHandlers.get(route)) {
                    case Some(mw) => mw
                    case None => fallback
                }
            case None => fallback
        }
    }
}

public class Composer {
    private var handler: MiddlewareFn = pass

    public init() {}

    public init(composer: Composer) {
        this.handler = composer.middleware()
    }

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

    public func use(composer: Composer): Composer {
        this.handler = concat(this.handler, composer.middleware())
        composer
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

    public func on(query: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(queryPredicate(query), middleware)
    }

    public func on(queries: Array<String>): Composer {
        this.filter(queryArrayPredicate(queries))
    }

    public func on(queries: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(queryArrayPredicate(queries), middleware)
    }

    public func on(queries: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(queryArrayPredicate(queries), middleware)
    }

    public func hears(trigger: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(trigger).matches(ctx) }))
    }

    public func hears(trigger: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(trigger).matches(ctx) }), middleware)
    }

    public func hears(trigger: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(trigger).matches(ctx) }), middleware)
    }

    public func hears(triggers: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(triggers).matches(ctx) }))
    }

    public func hears(triggers: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(triggers).matches(ctx) }), middleware)
    }

    public func hears(triggers: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(triggers).matches(ctx) }), middleware)
    }

    public func command(command: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.command(command).matches(ctx) }))
    }

    public func command(command: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.command(command).matches(ctx) }), middleware)
    }

    public func command(command: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.command(command).matches(ctx) }), middleware)
    }

    public func command(commands: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.command(commands).matches(ctx) }))
    }

    public func command(commands: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.command(commands).matches(ctx) }), middleware)
    }

    public func command(commands: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.command(commands).matches(ctx) }), middleware)
    }

    public func reaction(reaction: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reaction).matches(ctx) }))
    }

    public func reaction(reaction: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reaction).matches(ctx) }), middleware)
    }

    public func reaction(reaction: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reaction).matches(ctx) }), middleware)
    }

    public func reaction(reactions: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reactions).matches(ctx) }))
    }

    public func reaction(reactions: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reactions).matches(ctx) }), middleware)
    }

    public func reaction(reactions: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reactions).matches(ctx) }), middleware)
    }

    public func reaction(reaction: ReactionType): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reaction).matches(ctx) }))
    }

    public func reaction(reaction: ReactionType, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reaction).matches(ctx) }), middleware)
    }

    public func reaction(reaction: ReactionType, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reaction).matches(ctx) }), middleware)
    }

    public func reaction(reactions: Array<ReactionType>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reactions).matches(ctx) }))
    }

    public func reaction(reactions: Array<ReactionType>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reactions).matches(ctx) }), middleware)
    }

    public func reaction(reactions: Array<ReactionType>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.reaction(reactions).matches(ctx) }), middleware)
    }

    public func chatType(chatType: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chatType(chatType).matches(ctx) }))
    }

    public func chatType(chatType: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chatType(chatType).matches(ctx) }), middleware)
    }

    public func chatType(chatType: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chatType(chatType).matches(ctx) }), middleware)
    }

    public func chatType(chatTypes: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chatType(chatTypes).matches(ctx) }))
    }

    public func chatType(chatTypes: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chatType(chatTypes).matches(ctx) }), middleware)
    }

    public func chatType(chatTypes: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chatType(chatTypes).matches(ctx) }), middleware)
    }

    public func callbackQuery(trigger: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(trigger).matches(ctx) }))
    }

    public func callbackQuery(trigger: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(trigger).matches(ctx) }), middleware)
    }

    public func callbackQuery(trigger: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(trigger).matches(ctx) }), middleware)
    }

    public func callbackQuery(triggers: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(triggers).matches(ctx) }))
    }

    public func callbackQuery(triggers: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(triggers).matches(ctx) }), middleware)
    }

    public func callbackQuery(triggers: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(triggers).matches(ctx) }), middleware)
    }

    public func gameQuery(trigger: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(trigger).matches(ctx) }))
    }

    public func gameQuery(trigger: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(trigger).matches(ctx) }), middleware)
    }

    public func gameQuery(trigger: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(trigger).matches(ctx) }), middleware)
    }

    public func gameQuery(triggers: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(triggers).matches(ctx) }))
    }

    public func gameQuery(triggers: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(triggers).matches(ctx) }), middleware)
    }

    public func gameQuery(triggers: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(triggers).matches(ctx) }), middleware)
    }

    public func inlineQuery(trigger: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(trigger).matches(ctx) }))
    }

    public func inlineQuery(trigger: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(trigger).matches(ctx) }), middleware)
    }

    public func inlineQuery(trigger: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(trigger).matches(ctx) }), middleware)
    }

    public func inlineQuery(triggers: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(triggers).matches(ctx) }))
    }

    public func inlineQuery(triggers: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(triggers).matches(ctx) }), middleware)
    }

    public func inlineQuery(triggers: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(triggers).matches(ctx) }), middleware)
    }

    public func chosenInlineResult(trigger: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(trigger).matches(ctx) }))
    }

    public func chosenInlineResult(trigger: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(trigger).matches(ctx) }), middleware)
    }

    public func chosenInlineResult(trigger: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(trigger).matches(ctx) }), middleware)
    }

    public func chosenInlineResult(triggers: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(triggers).matches(ctx) }))
    }

    public func chosenInlineResult(triggers: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(triggers).matches(ctx) }), middleware)
    }

    public func chosenInlineResult(triggers: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(triggers).matches(ctx) }), middleware)
    }

    public func preCheckoutQuery(trigger: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(trigger).matches(ctx) }))
    }

    public func preCheckoutQuery(trigger: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(trigger).matches(ctx) }), middleware)
    }

    public func preCheckoutQuery(trigger: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(trigger).matches(ctx) }), middleware)
    }

    public func preCheckoutQuery(triggers: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(triggers).matches(ctx) }))
    }

    public func preCheckoutQuery(triggers: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(triggers).matches(ctx) }), middleware)
    }

    public func preCheckoutQuery(triggers: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(triggers).matches(ctx) }), middleware)
    }

    public func shippingQuery(trigger: String): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(trigger).matches(ctx) }))
    }

    public func shippingQuery(trigger: String, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(trigger).matches(ctx) }), middleware)
    }

    public func shippingQuery(trigger: String, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(trigger).matches(ctx) }), middleware)
    }

    public func shippingQuery(triggers: Array<String>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(triggers).matches(ctx) }))
    }

    public func shippingQuery(triggers: Array<String>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(triggers).matches(ctx) }), middleware)
    }

    public func shippingQuery(triggers: Array<String>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(triggers).matches(ctx) }), middleware)
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

    public func filter(predicate: Predicate, middleware: Array<MiddlewareFn>): Composer {
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

    public func drop(predicate: Predicate, middleware: Array<MiddlewareFn>): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func fork(): Composer {
        this.fork([])
    }

    public func fork(middleware: MiddlewareFn): Composer {
        this.fork([middleware])
    }

    public func fork(middleware: Array<MiddlewareFn>): Composer {
        let composer = Composer(middleware)
        let forked = composer.middleware()
        this.use({ ctx: Context, next: NextFunction =>
            let downstream = spawn { => next() }
            let forkFuture = spawn { => run(forked, ctx) }
            var failure = None<Exception>
            try {
                downstream.get()
            } catch (err: Exception) {
                failure = Some(err)
            }
            try {
                forkFuture.get()
            } catch (err: Exception) {
                match (failure) {
                    case Some(_) => ()
                    case None => failure = Some(err)
                }
            }
            match (failure) {
                case Some(err) => throw err
                case None => ()
            }
        })
        composer
    }

    public func lazy(factory: MiddlewareFactory): Composer {
        this.use({ ctx: Context, next: NextFunction =>
            let middleware = factory(ctx)
            middleware(ctx, next)
        })
    }

    public func lazy(factory: MiddlewareArrayFactory): Composer {
        this.use({ ctx: Context, next: NextFunction =>
            let middleware = factory(ctx)
            Composer(middleware).middleware()(ctx, next)
        })
    }

    public func lazy(factory: ComposerFactory): Composer {
        this.use({ ctx: Context, next: NextFunction =>
            factory(ctx).middleware()(ctx, next)
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

    public func branch(predicate: Predicate, trueMiddleware: Array<MiddlewareFn>, falseMiddleware: Array<MiddlewareFn>): Composer {
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
        this.errorBoundary(errorHandler, [middleware])
    }

    public func errorBoundary(errorHandler: ErrorHandler, middleware: Array<MiddlewareFn>): Composer {
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

public func composerControlMethodNames(): Array<String> {
    [
        "middleware",
        "use",
        "on",
        "hears",
        "command",
        "reaction",
        "chatType",
        "callbackQuery",
        "gameQuery",
        "inlineQuery",
        "chosenInlineResult",
        "preCheckoutQuery",
        "shippingQuery",
        "filter",
        "drop",
        "fork",
        "lazy",
        "route",
        "branch",
        "errorBoundary"
    ]
}

public func composerControlMethodCount(): Int64 {
    composerControlMethodNames().size
}
