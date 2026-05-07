package grammy4cj.composer

import grammy4cj.context.Context
import grammy4cj.filter.matchFilter
import grammy4cj.types.ReactionType
import std.collection.{ArrayList, HashMap}
import std.sync.{Condition, Mutex}

public type NextFunction = () -> Unit
public type AsyncNextFunction = () -> Future<Unit>
public type MiddlewareFn = (Context, NextFunction) -> Unit
public type AsyncMiddlewareFn = (Context, AsyncNextFunction) -> Future<Unit>
public type SyncPredicate = (Context) -> Bool
public type Predicate = (Context) -> Future<Bool>
public type MiddlewareFactory = (Context) -> MiddlewareFn
public type AsyncMiddlewareFactory = (Context) -> Future<MiddlewareFn>
public type MiddlewareArrayFactory = (Context) -> Array<MiddlewareFn>
public type AsyncMiddlewareArrayFactory = (Context) -> Future<Array<MiddlewareFn>>
public type ComposerFactory = (Context) -> Composer
public type AsyncComposerFactory = (Context) -> Future<Composer>
public type SyncRouter = (Context) -> Option<String>
public type Router = (Context) -> Future<Option<String>>
public type ErrorHandler = (BotError, NextFunction) -> Unit
public type AsyncErrorHandler = (BotError, AsyncNextFunction) -> Future<Unit>

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
        "MaybePromise via sync and Future middleware adapters",
        "AsyncNextFunction returns Future<Unit>; async middleware, predicate, factory, router, and error handler are joined at control boundaries",
        "fork starts downstream and forked middleware together and resolves on first failure or both successes",
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

private func resolvedUnitFuture(): Future<Unit> {
    spawn { => () }
}

private func resolvedBoolFuture(value: Bool): Future<Bool> {
    spawn { => value }
}

private func resolvedRouteFuture(value: Option<String>): Future<Option<String>> {
    spawn { => value }
}

private func blockingNext(next: AsyncNextFunction): NextFunction {
    { =>
        next().get()
    }
}

private func liftSyncMiddleware(middleware: MiddlewareFn): AsyncMiddlewareFn {
    { ctx: Context, next: AsyncNextFunction =>
        spawn { =>
            middleware(ctx, blockingNext(next))
        }
    }
}

private func liftSyncMiddlewareArray(middleware: Array<MiddlewareFn>): Array<AsyncMiddlewareFn> {
    let lifted = ArrayList<AsyncMiddlewareFn>()
    for (mw in middleware) {
        lifted.add(liftSyncMiddleware(mw))
    }
    lifted.toArray()
}

private func liftSyncPredicate(predicate: SyncPredicate): Predicate {
    { ctx: Context => resolvedBoolFuture(predicate(ctx)) }
}

private func liftSyncRouter(router: SyncRouter): Router {
    { ctx: Context => resolvedRouteFuture(router(ctx)) }
}

private func asyncPass(_ctx: Context, next: AsyncNextFunction): Future<Unit> {
    next()
}

public func pass(_ctx: Context, next: NextFunction): Unit {
    next()
}

private func concatAsync(first: AsyncMiddlewareFn, andThen: AsyncMiddlewareFn): AsyncMiddlewareFn {
    { ctx: Context, next: AsyncNextFunction =>
        spawn { =>
            let nextCalled = NextCallState()
            first(ctx, { =>
                if (nextCalled.called) {
                    throw Exception("`next` already called before!")
                }
                nextCalled.called = true
                andThen(ctx, next)
            }).get()
        }
    }
}

public func concat(first: MiddlewareFn, andThen: MiddlewareFn): MiddlewareFn {
    { ctx: Context, next: NextFunction =>
        concatAsync(liftSyncMiddleware(first), liftSyncMiddleware(andThen))(
            ctx,
            { => spawn { => next() } },
        ).get()
    }
}

private func compose(middleware: Array<AsyncMiddlewareFn>): AsyncMiddlewareFn {
    var handler: AsyncMiddlewareFn = asyncPass
    for (mw in middleware) {
        handler = concatAsync(handler, mw)
    }
    handler
}

public func run(middleware: MiddlewareFn, ctx: Context): Unit {
    liftSyncMiddleware(middleware)(ctx, { => resolvedUnitFuture() }).get()
}

public func run(middleware: AsyncMiddlewareFn, ctx: Context): Unit {
    middleware(ctx, { => resolvedUnitFuture() }).get()
}

public func run(composer: Composer, ctx: Context): Unit {
    composer.run(ctx)
}

private func notPredicate(predicate: Predicate): Predicate {
    { ctx: Context =>
        spawn { =>
            !predicate(ctx).get()
        }
    }
}

private func hasPredicate(predicate: SyncPredicate): Predicate {
    liftSyncPredicate(predicate)
}

private func queryPredicate(query: String): Predicate {
    { ctx: Context => resolvedBoolFuture(matchFilter(query, ctx)) }
}

private func queryArrayPredicate(queries: Array<String>): Predicate {
    { ctx: Context => resolvedBoolFuture(matchFilter(queries, ctx)) }
}

private func routeMiddleware(router: Router, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): AsyncMiddlewareFactory {
    { ctx: Context =>
        spawn { =>
            match (router(ctx).get()) {
                case Some(route) =>
                    match (routeHandlers.get(route)) {
                        case Some(mw) => mw
                        case None => fallback
                    }
                case None => fallback
            }
        }
    }
}

private class PromiseAllState {
    public var completed: Int64 = 0
    public var failure: Option<Exception> = None<Exception>

    public init() {}

    public func hasFailure(): Bool {
        match (this.failure) {
            case Some(_) => true
            case None => false
        }
    }
}

private func promiseAll(first: () -> Unit, second: () -> Unit): Future<Unit> {
    spawn { =>
        let state = PromiseAllState()
        let mutex = Mutex()
        let condition: Condition = synchronized(mutex) { mutex.condition() }
        let record: (Option<Exception>) -> Unit = { err: Option<Exception> =>
            synchronized(mutex) {
                state.completed += 1
                match (err) {
                    case Some(failure) =>
                        match (state.failure) {
                            case Some(_) => ()
                            case None => state.failure = Some(failure)
                        }
                    case None => ()
                }
                condition.notifyAll()
            }
        }
        let firstFuture = spawn { => first() }
        let secondFuture = spawn { => second() }
        spawn { =>
            try {
                firstFuture.get()
                record(None<Exception>)
            } catch (err: Exception) {
                record(Some(err))
            }
        }
        spawn { =>
            try {
                secondFuture.get()
                record(None<Exception>)
            } catch (err: Exception) {
                record(Some(err))
            }
        }
        synchronized(mutex) {
            condition.waitUntil({ => state.hasFailure() || state.completed == 2 })
        }
        match (state.failure) {
            case Some(err) => throw err
            case None => ()
        }
    }
}

public class Composer {
    private var handler: AsyncMiddlewareFn = asyncPass

    public init() {}

    public init(composer: Composer) {
        this.handler = composer.asyncMiddleware()
    }

    public init(middleware: MiddlewareFn) {
        this.handler = liftSyncMiddleware(middleware)
    }

    public init(middleware: AsyncMiddlewareFn) {
        this.handler = middleware
    }

    public init(middleware: Array<MiddlewareFn>) {
        this.handler = compose(liftSyncMiddlewareArray(middleware))
    }

    public init(middleware: Array<AsyncMiddlewareFn>) {
        this.handler = compose(middleware)
    }

    public func middleware(): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handler(ctx, { => spawn { => next() } }).get()
        }
    }

    public func asyncMiddleware(): AsyncMiddlewareFn {
        { ctx: Context, next: AsyncNextFunction =>
            this.handler(ctx, next)
        }
    }

    public func run(ctx: Context): Unit {
        this.handler(ctx, { => resolvedUnitFuture() }).get()
    }

    public func use(middleware: MiddlewareFn): Composer {
        this.use([middleware])
    }

    public func use(middleware: AsyncMiddlewareFn): Composer {
        this.use([middleware])
    }

    public func use(composer: Composer): Composer {
        this.handler = concatAsync(this.handler, composer.asyncMiddleware())
        composer
    }

    public func use(middleware: Array<MiddlewareFn>): Composer {
        let composer = Composer(middleware)
        this.handler = concatAsync(this.handler, composer.asyncMiddleware())
        composer
    }

    public func use(middleware: Array<AsyncMiddlewareFn>): Composer {
        let composer = Composer(middleware)
        this.handler = concatAsync(this.handler, composer.asyncMiddleware())
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
        this.branch(predicate, composer.asyncMiddleware(), asyncPass)
        composer
    }

    public func filter(predicate: SyncPredicate): Composer {
        this.filter(liftSyncPredicate(predicate))
    }

    public func filter(predicate: Predicate, middleware: MiddlewareFn): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func filter(predicate: SyncPredicate, middleware: MiddlewareFn): Composer {
        this.filter(liftSyncPredicate(predicate), middleware)
    }

    public func filter(predicate: Predicate, middleware: AsyncMiddlewareFn): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func filter(predicate: Predicate, middleware: Array<MiddlewareFn>): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func filter(predicate: SyncPredicate, middleware: Array<MiddlewareFn>): Composer {
        this.filter(liftSyncPredicate(predicate), middleware)
    }

    public func filter(predicate: Predicate, middleware: Array<AsyncMiddlewareFn>): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func drop(predicate: Predicate): Composer {
        this.filter(notPredicate(predicate))
    }

    public func drop(predicate: SyncPredicate): Composer {
        this.drop(liftSyncPredicate(predicate))
    }

    public func drop(predicate: Predicate, middleware: MiddlewareFn): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func drop(predicate: SyncPredicate, middleware: MiddlewareFn): Composer {
        this.drop(liftSyncPredicate(predicate), middleware)
    }

    public func drop(predicate: Predicate, middleware: AsyncMiddlewareFn): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func drop(predicate: Predicate, middleware: Array<MiddlewareFn>): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func drop(predicate: SyncPredicate, middleware: Array<MiddlewareFn>): Composer {
        this.drop(liftSyncPredicate(predicate), middleware)
    }

    public func drop(predicate: Predicate, middleware: Array<AsyncMiddlewareFn>): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func fork(): Composer {
        this.fork(Array<AsyncMiddlewareFn>())
    }

    public func fork(middleware: MiddlewareFn): Composer {
        this.fork([middleware])
    }

    public func fork(middleware: AsyncMiddlewareFn): Composer {
        this.fork([middleware])
    }

    public func fork(middleware: Array<MiddlewareFn>): Composer {
        this.fork(liftSyncMiddlewareArray(middleware))
    }

    public func fork(middleware: Array<AsyncMiddlewareFn>): Composer {
        let composer = Composer(middleware)
        let forked = composer.asyncMiddleware()
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            promiseAll(
                { => next().get() },
                { => run(forked, ctx) },
            )
        }
        this.use(runner)
        composer
    }

    public func lazy(factory: MiddlewareFactory): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                let middleware = factory(ctx)
                liftSyncMiddleware(middleware)(ctx, next).get()
            }
        }
        this.use(runner)
    }

    public func lazy(factory: AsyncMiddlewareFactory): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                let middleware = factory(ctx).get()
                liftSyncMiddleware(middleware)(ctx, next).get()
            }
        }
        this.use(runner)
    }

    public func lazyAsync(factory: (Context) -> Future<AsyncMiddlewareFn>): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                let middleware = factory(ctx).get()
                middleware(ctx, next).get()
            }
        }
        this.use(runner)
    }

    public func lazy(factory: MiddlewareArrayFactory): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                let middleware = factory(ctx)
                Composer(middleware).asyncMiddleware()(ctx, next).get()
            }
        }
        this.use(runner)
    }

    public func lazy(factory: AsyncMiddlewareArrayFactory): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                let middleware = factory(ctx).get()
                Composer(middleware).asyncMiddleware()(ctx, next).get()
            }
        }
        this.use(runner)
    }

    public func lazy(factory: ComposerFactory): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                factory(ctx).asyncMiddleware()(ctx, next).get()
            }
        }
        this.use(runner)
    }

    public func lazy(factory: AsyncComposerFactory): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                factory(ctx).get().asyncMiddleware()(ctx, next).get()
            }
        }
        this.use(runner)
    }

    public func route(router: SyncRouter, routeHandlers: HashMap<String, MiddlewareFn>): Composer {
        this.route(liftSyncRouter(router), routeHandlers, pass)
    }

    public func route(router: Router, routeHandlers: HashMap<String, MiddlewareFn>): Composer {
        this.route(router, routeHandlers, pass)
    }

    public func route(router: SyncRouter, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): Composer {
        this.route(liftSyncRouter(router), routeHandlers, fallback)
    }

    public func route(router: Router, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): Composer {
        this.lazy(routeMiddleware(router, routeHandlers, fallback))
    }

    public func branch(predicate: SyncPredicate, trueMiddleware: MiddlewareFn, falseMiddleware: MiddlewareFn): Composer {
        this.branch(liftSyncPredicate(predicate), trueMiddleware, falseMiddleware)
    }

    public func branch(predicate: Predicate, trueMiddleware: MiddlewareFn, falseMiddleware: MiddlewareFn): Composer {
        this.branch(predicate, liftSyncMiddleware(trueMiddleware), liftSyncMiddleware(falseMiddleware))
    }

    public func branch(predicate: Predicate, trueMiddleware: AsyncMiddlewareFn, falseMiddleware: AsyncMiddlewareFn): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                if (predicate(ctx).get()) {
                    trueMiddleware(ctx, next).get()
                } else {
                    falseMiddleware(ctx, next).get()
                }
            }
        }
        this.use(runner)
    }

    public func branch(predicate: SyncPredicate, trueMiddleware: Array<MiddlewareFn>, falseMiddleware: Array<MiddlewareFn>): Composer {
        this.branch(liftSyncPredicate(predicate), trueMiddleware, falseMiddleware)
    }

    public func branch(predicate: Predicate, trueMiddleware: Array<MiddlewareFn>, falseMiddleware: Array<MiddlewareFn>): Composer {
        this.branch(predicate, liftSyncMiddlewareArray(trueMiddleware), liftSyncMiddlewareArray(falseMiddleware))
    }

    public func branch(predicate: Predicate, trueMiddleware: Array<AsyncMiddlewareFn>, falseMiddleware: Array<AsyncMiddlewareFn>): Composer {
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                if (predicate(ctx).get()) {
                    Composer(trueMiddleware).asyncMiddleware()(ctx, next).get()
                } else {
                    Composer(falseMiddleware).asyncMiddleware()(ctx, next).get()
                }
            }
        }
        this.use(runner)
    }

    public func errorBoundary(errorHandler: ErrorHandler): Composer {
        this.errorBoundary(errorHandler, pass)
    }

    public func errorBoundary(errorHandler: AsyncErrorHandler): Composer {
        this.errorBoundary(errorHandler, asyncPass)
    }

    public func errorBoundary(errorHandler: ErrorHandler, middleware: MiddlewareFn): Composer {
        this.errorBoundary(errorHandler, [middleware])
    }

    public func errorBoundary(errorHandler: AsyncErrorHandler, middleware: AsyncMiddlewareFn): Composer {
        this.errorBoundary(errorHandler, [middleware])
    }

    public func errorBoundary(errorHandler: ErrorHandler, middleware: Array<MiddlewareFn>): Composer {
        let asyncHandler: AsyncErrorHandler = { err: BotError, next: AsyncNextFunction =>
            spawn { =>
                errorHandler(err, blockingNext(next))
            }
        }
        this.errorBoundary(asyncHandler, liftSyncMiddlewareArray(middleware))
    }

    public func errorBoundary(errorHandler: AsyncErrorHandler, middleware: Array<AsyncMiddlewareFn>): Composer {
        let composer = Composer(middleware)
        let bound = composer.asyncMiddleware()
        let runner: AsyncMiddlewareFn = { ctx: Context, next: AsyncNextFunction =>
            spawn { =>
                let nextCalled = NextCallState()
                let cont: AsyncNextFunction = { =>
                    nextCalled.called = true
                    resolvedUnitFuture()
                }
                try {
                    bound(ctx, cont).get()
                } catch (err: Exception) {
                    nextCalled.called = false
                    errorHandler(BotError(err, ctx), cont).get()
                }
                if (nextCalled.called) {
                    next().get()
                }
            }
        }
        this.use(runner)
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
