package grammy4cj.composer

import grammy4cj.context.Context
import grammy4cj.filter.matchFilter
import grammy4cj.types.ReactionType
import std.collection.{ArrayList, HashMap}
import std.regex.Regex
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

public class MaybeTask<T> {
    private let wait: () -> T

    public init(value: T) {
        this.wait = { => value }
    }

    public init(future: Future<T>) {
        this.wait = { => future.get() }
    }

    public init(wait: () -> T) {
        this.wait = wait
    }

    public func get(): T {
        this.wait()
    }

    public func future(): Future<T> {
        spawn { => this.get() }
    }
}

public type MaybeNextFunction = () -> MaybeTask<Unit>
public type MaybeMiddlewareFn = (Context, MaybeNextFunction) -> MaybeTask<Unit>
public type MaybePredicate = (Context) -> MaybeTask<Bool>
public type MaybeRouter = (Context) -> MaybeTask<Option<String>>
public type MaybeMiddlewareFactory = (Context) -> MaybeTask<MaybeMiddlewareFn>
public type MaybeMiddlewareArrayFactory = (Context) -> MaybeTask<Array<MaybeMiddlewareFn>>
public type MaybeComposerFactory = (Context) -> MaybeTask<Composer>
public type MaybeErrorHandler = (BotError, MaybeNextFunction) -> MaybeTask<Unit>

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
        "MaybeTask<T> facade backs sync values and Future<T> callbacks",
        "Middleware, next, predicate, router, factory, and error handler normalize to MaybeTask<Unit> at Composer boundaries",
        "fork starts downstream and forked middleware together and resolves like Promise.all: first failure or both successes",
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

private func resolvedUnitTask(): MaybeTask<Unit> {
    MaybeTask<Unit>(())
}

private func resolvedBoolTask(value: Bool): MaybeTask<Bool> {
    MaybeTask<Bool>(value)
}

private func resolvedRouteTask(value: Option<String>): MaybeTask<Option<String>> {
    MaybeTask<Option<String>>(value)
}

private func blockingNext(next: MaybeNextFunction): NextFunction {
    { =>
        next().get()
    }
}

private func liftSyncMiddleware(middleware: MiddlewareFn): MaybeMiddlewareFn {
    { ctx: Context, next: MaybeNextFunction =>
        MaybeTask<Unit>({ =>
            middleware(ctx, blockingNext(next))
        })
    }
}

private func liftFutureMiddleware(middleware: AsyncMiddlewareFn): MaybeMiddlewareFn {
    { ctx: Context, next: MaybeNextFunction =>
        MaybeTask<Unit>(middleware(ctx, { => next().future() }))
    }
}

private func liftSyncMiddlewareArray(middleware: Array<MiddlewareFn>): Array<MaybeMiddlewareFn> {
    let lifted = ArrayList<MaybeMiddlewareFn>()
    for (mw in middleware) {
        lifted.add(liftSyncMiddleware(mw))
    }
    lifted.toArray()
}

private func liftFutureMiddlewareArray(middleware: Array<AsyncMiddlewareFn>): Array<MaybeMiddlewareFn> {
    let lifted = ArrayList<MaybeMiddlewareFn>()
    for (mw in middleware) {
        lifted.add(liftFutureMiddleware(mw))
    }
    lifted.toArray()
}

private func liftSyncPredicate(predicate: SyncPredicate): MaybePredicate {
    { ctx: Context => resolvedBoolTask(predicate(ctx)) }
}

private func liftFuturePredicate(predicate: Predicate): MaybePredicate {
    { ctx: Context => MaybeTask<Bool>(predicate(ctx)) }
}

private func liftSyncRouter(router: SyncRouter): MaybeRouter {
    { ctx: Context => resolvedRouteTask(router(ctx)) }
}

private func liftFutureRouter(router: Router): MaybeRouter {
    { ctx: Context => MaybeTask<Option<String>>(router(ctx)) }
}

private func maybePass(_ctx: Context, next: MaybeNextFunction): MaybeTask<Unit> {
    next()
}

private func asyncPass(_ctx: Context, next: AsyncNextFunction): Future<Unit> {
    next()
}

public func pass(_ctx: Context, next: NextFunction): Unit {
    next()
}

private func concatMaybe(first: MaybeMiddlewareFn, andThen: MaybeMiddlewareFn): MaybeMiddlewareFn {
    { ctx: Context, next: MaybeNextFunction =>
        MaybeTask<Unit>({ =>
            let nextCalled = NextCallState()
            first(ctx, { =>
                if (nextCalled.called) {
                    throw Exception("`next` already called before!")
                }
                nextCalled.called = true
                andThen(ctx, next)
            }).get()
        })
    }
}

public func concat(first: MiddlewareFn, andThen: MiddlewareFn): MiddlewareFn {
    { ctx: Context, next: NextFunction =>
        concatMaybe(liftSyncMiddleware(first), liftSyncMiddleware(andThen))(
            ctx,
            { => MaybeTask<Unit>({ => next() }) },
        ).get()
    }
}

private func compose(middleware: Array<MaybeMiddlewareFn>): MaybeMiddlewareFn {
    var handler: MaybeMiddlewareFn = maybePass
    for (mw in middleware) {
        handler = concatMaybe(handler, mw)
    }
    handler
}

public func run(middleware: MiddlewareFn, ctx: Context): Unit {
    liftSyncMiddleware(middleware)(ctx, { => resolvedUnitTask() }).get()
}

public func run(middleware: AsyncMiddlewareFn, ctx: Context): Unit {
    liftFutureMiddleware(middleware)(ctx, { => resolvedUnitTask() }).get()
}

public func run(middleware: MaybeMiddlewareFn, ctx: Context): Unit {
    middleware(ctx, { => resolvedUnitTask() }).get()
}

public func run(composer: Composer, ctx: Context): Unit {
    composer.run(ctx)
}

private func notPredicate(predicate: MaybePredicate): MaybePredicate {
    { ctx: Context =>
        MaybeTask<Bool>({ =>
            !predicate(ctx).get()
        })
    }
}

private func hasPredicate(predicate: SyncPredicate): MaybePredicate {
    liftSyncPredicate(predicate)
}

private func queryPredicate(query: String): MaybePredicate {
    { ctx: Context => resolvedBoolTask(matchFilter(query, ctx)) }
}

private func queryArrayPredicate(queries: Array<String>): MaybePredicate {
    { ctx: Context => resolvedBoolTask(matchFilter(queries, ctx)) }
}

private func routeMiddleware(router: MaybeRouter, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): MaybeMiddlewareFactory {
    routeMaybeMiddleware(router, liftSyncRouteHandlers(routeHandlers), liftSyncMiddleware(fallback))
}

private func routeFutureMiddleware(router: MaybeRouter, routeHandlers: HashMap<String, AsyncMiddlewareFn>, fallback: AsyncMiddlewareFn): MaybeMiddlewareFactory {
    routeMaybeMiddleware(router, liftFutureRouteHandlers(routeHandlers), liftFutureMiddleware(fallback))
}

private func routeMaybeMiddleware(router: MaybeRouter, routeHandlers: HashMap<String, MaybeMiddlewareFn>, fallback: MaybeMiddlewareFn): MaybeMiddlewareFactory {
    { ctx: Context =>
        MaybeTask<MaybeMiddlewareFn>({ =>
            match (router(ctx).get()) {
                case Some(route) =>
                    match (routeHandlers.get(route)) {
                        case Some(mw) => mw
                        case None => fallback
                    }
                case None => fallback
            }
        })
    }
}

private func liftSyncRouteHandlers(routeHandlers: HashMap<String, MiddlewareFn>): HashMap<String, MaybeMiddlewareFn> {
    let lifted = HashMap<String, MaybeMiddlewareFn>()
    for ((route, mw) in routeHandlers) {
        lifted[route] = liftSyncMiddleware(mw)
    }
    lifted
}

private func liftFutureRouteHandlers(routeHandlers: HashMap<String, AsyncMiddlewareFn>): HashMap<String, MaybeMiddlewareFn> {
    let lifted = HashMap<String, MaybeMiddlewareFn>()
    for ((route, mw) in routeHandlers) {
        lifted[route] = liftFutureMiddleware(mw)
    }
    lifted
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
    private var handler: MaybeMiddlewareFn = maybePass

    public init() {}

    public init(composer: Composer) {
        this.handler = composer.maybeMiddleware()
    }

    public init(middleware: MiddlewareFn) {
        this.handler = liftSyncMiddleware(middleware)
    }

    public init(middleware: AsyncMiddlewareFn) {
        this.handler = liftFutureMiddleware(middleware)
    }

    public init(middleware: Array<MiddlewareFn>) {
        this.handler = compose(liftSyncMiddlewareArray(middleware))
    }

    public init(middleware: Array<AsyncMiddlewareFn>) {
        this.handler = compose(liftFutureMiddlewareArray(middleware))
    }

    public init(middleware: MaybeMiddlewareFn) {
        this.handler = middleware
    }

    public init(middleware: Array<MaybeMiddlewareFn>) {
        this.handler = compose(middleware)
    }

    public func middleware(): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handler(ctx, { => MaybeTask<Unit>({ => next() }) }).get()
        }
    }

    public func asyncMiddleware(): AsyncMiddlewareFn {
        { ctx: Context, next: AsyncNextFunction =>
            this.handler(ctx, { => MaybeTask<Unit>(next()) }).future()
        }
    }

    public func maybeMiddleware(): MaybeMiddlewareFn {
        { ctx: Context, next: MaybeNextFunction =>
            this.handler(ctx, next)
        }
    }

    public func run(ctx: Context): Unit {
        this.handler(ctx, { => resolvedUnitTask() }).get()
    }

    public func use(middleware: MiddlewareFn): Composer {
        this.use([middleware])
    }

    public func use(middleware: AsyncMiddlewareFn): Composer {
        this.use([middleware])
    }

    public func use(composer: Composer): Composer {
        this.handler = concatMaybe(this.handler, composer.maybeMiddleware())
        composer
    }

    public func use(middleware: Array<MiddlewareFn>): Composer {
        let composer = Composer(middleware)
        this.handler = concatMaybe(this.handler, composer.maybeMiddleware())
        composer
    }

    public func use(middleware: Array<AsyncMiddlewareFn>): Composer {
        let composer = Composer(middleware)
        this.handler = concatMaybe(this.handler, composer.maybeMiddleware())
        composer
    }

    public func use(middleware: MaybeMiddlewareFn): Composer {
        this.use([middleware])
    }

    public func use(middleware: Array<MaybeMiddlewareFn>): Composer {
        let composer = Composer(middleware)
        this.handler = concatMaybe(this.handler, composer.maybeMiddleware())
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

    public func hears(trigger: Regex): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(trigger).matches(ctx) }))
    }

    public func hears(trigger: Regex, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(trigger).matches(ctx) }), middleware)
    }

    public func hears(trigger: Regex, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(trigger).matches(ctx) }), middleware)
    }

    public func hears(triggers: Array<Regex>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(triggers).matches(ctx) }))
    }

    public func hears(triggers: Array<Regex>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.text(triggers).matches(ctx) }), middleware)
    }

    public func hears(triggers: Array<Regex>, middleware: Array<MiddlewareFn>): Composer {
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

    public func callbackQuery(trigger: Regex): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(trigger).matches(ctx) }))
    }

    public func callbackQuery(trigger: Regex, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(trigger).matches(ctx) }), middleware)
    }

    public func callbackQuery(trigger: Regex, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(trigger).matches(ctx) }), middleware)
    }

    public func callbackQuery(triggers: Array<Regex>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(triggers).matches(ctx) }))
    }

    public func callbackQuery(triggers: Array<Regex>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.callbackQuery(triggers).matches(ctx) }), middleware)
    }

    public func callbackQuery(triggers: Array<Regex>, middleware: Array<MiddlewareFn>): Composer {
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

    public func gameQuery(trigger: Regex): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(trigger).matches(ctx) }))
    }

    public func gameQuery(trigger: Regex, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(trigger).matches(ctx) }), middleware)
    }

    public func gameQuery(trigger: Regex, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(trigger).matches(ctx) }), middleware)
    }

    public func gameQuery(triggers: Array<Regex>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(triggers).matches(ctx) }))
    }

    public func gameQuery(triggers: Array<Regex>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.gameQuery(triggers).matches(ctx) }), middleware)
    }

    public func gameQuery(triggers: Array<Regex>, middleware: Array<MiddlewareFn>): Composer {
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

    public func inlineQuery(trigger: Regex): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(trigger).matches(ctx) }))
    }

    public func inlineQuery(trigger: Regex, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(trigger).matches(ctx) }), middleware)
    }

    public func inlineQuery(trigger: Regex, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(trigger).matches(ctx) }), middleware)
    }

    public func inlineQuery(triggers: Array<Regex>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(triggers).matches(ctx) }))
    }

    public func inlineQuery(triggers: Array<Regex>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.inlineQuery(triggers).matches(ctx) }), middleware)
    }

    public func inlineQuery(triggers: Array<Regex>, middleware: Array<MiddlewareFn>): Composer {
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

    public func chosenInlineResult(trigger: Regex): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(trigger).matches(ctx) }))
    }

    public func chosenInlineResult(trigger: Regex, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(trigger).matches(ctx) }), middleware)
    }

    public func chosenInlineResult(trigger: Regex, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(trigger).matches(ctx) }), middleware)
    }

    public func chosenInlineResult(triggers: Array<Regex>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(triggers).matches(ctx) }))
    }

    public func chosenInlineResult(triggers: Array<Regex>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.chosenInlineResult(triggers).matches(ctx) }), middleware)
    }

    public func chosenInlineResult(triggers: Array<Regex>, middleware: Array<MiddlewareFn>): Composer {
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

    public func preCheckoutQuery(trigger: Regex): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(trigger).matches(ctx) }))
    }

    public func preCheckoutQuery(trigger: Regex, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(trigger).matches(ctx) }), middleware)
    }

    public func preCheckoutQuery(trigger: Regex, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(trigger).matches(ctx) }), middleware)
    }

    public func preCheckoutQuery(triggers: Array<Regex>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(triggers).matches(ctx) }))
    }

    public func preCheckoutQuery(triggers: Array<Regex>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.preCheckoutQuery(triggers).matches(ctx) }), middleware)
    }

    public func preCheckoutQuery(triggers: Array<Regex>, middleware: Array<MiddlewareFn>): Composer {
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

    public func shippingQuery(trigger: Regex): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(trigger).matches(ctx) }))
    }

    public func shippingQuery(trigger: Regex, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(trigger).matches(ctx) }), middleware)
    }

    public func shippingQuery(trigger: Regex, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(trigger).matches(ctx) }), middleware)
    }

    public func shippingQuery(triggers: Array<Regex>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(triggers).matches(ctx) }))
    }

    public func shippingQuery(triggers: Array<Regex>, middleware: MiddlewareFn): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(triggers).matches(ctx) }), middleware)
    }

    public func shippingQuery(triggers: Array<Regex>, middleware: Array<MiddlewareFn>): Composer {
        this.filter(hasPredicate({ ctx: Context => Context.has.shippingQuery(triggers).matches(ctx) }), middleware)
    }

    public func filter(predicate: Predicate): Composer {
        this.filter(liftFuturePredicate(predicate))
    }

    public func filter(predicate: SyncPredicate): Composer {
        this.filter(liftSyncPredicate(predicate))
    }

    public func filter(predicate: MaybePredicate): Composer {
        let composer = Composer()
        this.branch(predicate, composer.maybeMiddleware(), maybePass)
        composer
    }

    public func filter(predicate: Predicate, middleware: MiddlewareFn): Composer {
        this.filter(liftFuturePredicate(predicate), middleware)
    }

    public func filter(predicate: SyncPredicate, middleware: MiddlewareFn): Composer {
        this.filter(liftSyncPredicate(predicate), middleware)
    }

    public func filter(predicate: MaybePredicate, middleware: MiddlewareFn): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func filter(predicate: Predicate, middleware: AsyncMiddlewareFn): Composer {
        this.filter(liftFuturePredicate(predicate), middleware)
    }

    public func filter(predicate: MaybePredicate, middleware: AsyncMiddlewareFn): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func filter(predicate: Predicate, middleware: Array<MiddlewareFn>): Composer {
        this.filter(liftFuturePredicate(predicate), middleware)
    }

    public func filter(predicate: SyncPredicate, middleware: Array<MiddlewareFn>): Composer {
        this.filter(liftSyncPredicate(predicate), middleware)
    }

    public func filter(predicate: MaybePredicate, middleware: Array<MiddlewareFn>): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func filter(predicate: Predicate, middleware: Array<AsyncMiddlewareFn>): Composer {
        this.filter(liftFuturePredicate(predicate), middleware)
    }

    public func filter(predicate: MaybePredicate, middleware: Array<AsyncMiddlewareFn>): Composer {
        let composer = this.filter(predicate)
        composer.use(middleware)
        composer
    }

    public func drop(predicate: Predicate): Composer {
        this.filter(notPredicate(liftFuturePredicate(predicate)))
    }

    public func drop(predicate: SyncPredicate): Composer {
        this.drop(liftSyncPredicate(predicate))
    }

    public func drop(predicate: MaybePredicate): Composer {
        this.filter(notPredicate(predicate))
    }

    public func drop(predicate: Predicate, middleware: MiddlewareFn): Composer {
        this.filter(notPredicate(liftFuturePredicate(predicate)), middleware)
    }

    public func drop(predicate: SyncPredicate, middleware: MiddlewareFn): Composer {
        this.drop(liftSyncPredicate(predicate), middleware)
    }

    public func drop(predicate: MaybePredicate, middleware: MiddlewareFn): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func drop(predicate: Predicate, middleware: AsyncMiddlewareFn): Composer {
        this.filter(notPredicate(liftFuturePredicate(predicate)), middleware)
    }

    public func drop(predicate: MaybePredicate, middleware: AsyncMiddlewareFn): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func drop(predicate: Predicate, middleware: Array<MiddlewareFn>): Composer {
        this.filter(notPredicate(liftFuturePredicate(predicate)), middleware)
    }

    public func drop(predicate: SyncPredicate, middleware: Array<MiddlewareFn>): Composer {
        this.drop(liftSyncPredicate(predicate), middleware)
    }

    public func drop(predicate: MaybePredicate, middleware: Array<MiddlewareFn>): Composer {
        this.filter(notPredicate(predicate), middleware)
    }

    public func drop(predicate: Predicate, middleware: Array<AsyncMiddlewareFn>): Composer {
        this.filter(notPredicate(liftFuturePredicate(predicate)), middleware)
    }

    public func drop(predicate: MaybePredicate, middleware: Array<AsyncMiddlewareFn>): Composer {
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

    public func fork(middleware: MaybeMiddlewareFn): Composer {
        this.fork([middleware])
    }

    public func fork(middleware: Array<MiddlewareFn>): Composer {
        this.fork(liftSyncMiddlewareArray(middleware))
    }

    public func fork(middleware: Array<AsyncMiddlewareFn>): Composer {
        this.fork(liftFutureMiddlewareArray(middleware))
    }

    public func fork(middleware: Array<MaybeMiddlewareFn>): Composer {
        let composer = Composer(middleware)
        let forked = composer.maybeMiddleware()
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>(promiseAll(
                { => next().get() },
                { => run(forked, ctx) },
            ))
        }
        this.use(runner)
        composer
    }

    public func lazy(factory: MiddlewareFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                let middleware = factory(ctx)
                liftSyncMiddleware(middleware)(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazy(factory: AsyncMiddlewareFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                let middleware = factory(ctx).get()
                liftSyncMiddleware(middleware)(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazyAsync(factory: (Context) -> Future<AsyncMiddlewareFn>): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                let middleware = factory(ctx).get()
                liftFutureMiddleware(middleware)(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazyMaybe(factory: MaybeMiddlewareFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                let middleware = factory(ctx).get()
                middleware(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazy(factory: MiddlewareArrayFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                let middleware = factory(ctx)
                Composer(middleware).maybeMiddleware()(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazy(factory: AsyncMiddlewareArrayFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                let middleware = factory(ctx).get()
                Composer(middleware).maybeMiddleware()(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazyMaybeArray(factory: MaybeMiddlewareArrayFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                let middleware = factory(ctx).get()
                Composer(middleware).maybeMiddleware()(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazy(factory: ComposerFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                factory(ctx).maybeMiddleware()(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazy(factory: AsyncComposerFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                factory(ctx).get().maybeMiddleware()(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func lazyMaybeComposer(factory: MaybeComposerFactory): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                factory(ctx).get().maybeMiddleware()(ctx, next).get()
            })
        }
        this.use(runner)
    }

    public func route(router: SyncRouter, routeHandlers: HashMap<String, MiddlewareFn>): Composer {
        this.route(liftSyncRouter(router), routeHandlers, pass)
    }

    public func route(router: SyncRouter, routeHandlers: HashMap<String, AsyncMiddlewareFn>): Composer {
        this.route(liftSyncRouter(router), routeHandlers, asyncPass)
    }

    public func route(router: SyncRouter, routeHandlers: HashMap<String, MaybeMiddlewareFn>): Composer {
        this.route(liftSyncRouter(router), routeHandlers, maybePass)
    }

    public func route(router: Router, routeHandlers: HashMap<String, MiddlewareFn>): Composer {
        this.route(liftFutureRouter(router), routeHandlers, pass)
    }

    public func route(router: Router, routeHandlers: HashMap<String, AsyncMiddlewareFn>): Composer {
        this.route(liftFutureRouter(router), routeHandlers, asyncPass)
    }

    public func route(router: Router, routeHandlers: HashMap<String, MaybeMiddlewareFn>): Composer {
        this.route(liftFutureRouter(router), routeHandlers, maybePass)
    }

    public func route(router: MaybeRouter, routeHandlers: HashMap<String, MiddlewareFn>): Composer {
        this.route(router, routeHandlers, pass)
    }

    public func route(router: MaybeRouter, routeHandlers: HashMap<String, AsyncMiddlewareFn>): Composer {
        this.route(router, routeHandlers, asyncPass)
    }

    public func route(router: MaybeRouter, routeHandlers: HashMap<String, MaybeMiddlewareFn>): Composer {
        this.route(router, routeHandlers, maybePass)
    }

    public func route(router: SyncRouter, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): Composer {
        this.route(liftSyncRouter(router), routeHandlers, fallback)
    }

    public func route(router: SyncRouter, routeHandlers: HashMap<String, AsyncMiddlewareFn>, fallback: AsyncMiddlewareFn): Composer {
        this.route(liftSyncRouter(router), routeHandlers, fallback)
    }

    public func route(router: SyncRouter, routeHandlers: HashMap<String, MaybeMiddlewareFn>, fallback: MaybeMiddlewareFn): Composer {
        this.route(liftSyncRouter(router), routeHandlers, fallback)
    }

    public func route(router: Router, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): Composer {
        this.route(liftFutureRouter(router), routeHandlers, fallback)
    }

    public func route(router: Router, routeHandlers: HashMap<String, AsyncMiddlewareFn>, fallback: AsyncMiddlewareFn): Composer {
        this.route(liftFutureRouter(router), routeHandlers, fallback)
    }

    public func route(router: Router, routeHandlers: HashMap<String, MaybeMiddlewareFn>, fallback: MaybeMiddlewareFn): Composer {
        this.route(liftFutureRouter(router), routeHandlers, fallback)
    }

    public func route(router: MaybeRouter, routeHandlers: HashMap<String, MiddlewareFn>, fallback: MiddlewareFn): Composer {
        this.lazyMaybe(routeMiddleware(router, routeHandlers, fallback))
    }

    public func route(router: MaybeRouter, routeHandlers: HashMap<String, AsyncMiddlewareFn>, fallback: AsyncMiddlewareFn): Composer {
        this.lazyMaybe(routeFutureMiddleware(router, routeHandlers, fallback))
    }

    public func route(router: MaybeRouter, routeHandlers: HashMap<String, MaybeMiddlewareFn>, fallback: MaybeMiddlewareFn): Composer {
        this.lazyMaybe(routeMaybeMiddleware(router, routeHandlers, fallback))
    }

    public func branch(predicate: SyncPredicate, trueMiddleware: MiddlewareFn, falseMiddleware: MiddlewareFn): Composer {
        this.branch(liftSyncPredicate(predicate), trueMiddleware, falseMiddleware)
    }

    public func branch(predicate: Predicate, trueMiddleware: MiddlewareFn, falseMiddleware: MiddlewareFn): Composer {
        this.branch(liftFuturePredicate(predicate), liftSyncMiddleware(trueMiddleware), liftSyncMiddleware(falseMiddleware))
    }

    public func branch(predicate: MaybePredicate, trueMiddleware: MiddlewareFn, falseMiddleware: MiddlewareFn): Composer {
        this.branch(predicate, liftSyncMiddleware(trueMiddleware), liftSyncMiddleware(falseMiddleware))
    }

    public func branch(predicate: Predicate, trueMiddleware: AsyncMiddlewareFn, falseMiddleware: AsyncMiddlewareFn): Composer {
        this.branch(liftFuturePredicate(predicate), liftFutureMiddleware(trueMiddleware), liftFutureMiddleware(falseMiddleware))
    }

    public func branch(predicate: MaybePredicate, trueMiddleware: AsyncMiddlewareFn, falseMiddleware: AsyncMiddlewareFn): Composer {
        this.branch(predicate, liftFutureMiddleware(trueMiddleware), liftFutureMiddleware(falseMiddleware))
    }

    public func branch(predicate: MaybePredicate, trueMiddleware: MaybeMiddlewareFn, falseMiddleware: MaybeMiddlewareFn): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                if (predicate(ctx).get()) {
                    trueMiddleware(ctx, next).get()
                } else {
                    falseMiddleware(ctx, next).get()
                }
            })
        }
        this.use(runner)
    }

    public func branch(predicate: SyncPredicate, trueMiddleware: Array<MiddlewareFn>, falseMiddleware: Array<MiddlewareFn>): Composer {
        this.branch(liftSyncPredicate(predicate), trueMiddleware, falseMiddleware)
    }

    public func branch(predicate: Predicate, trueMiddleware: Array<MiddlewareFn>, falseMiddleware: Array<MiddlewareFn>): Composer {
        this.branch(liftFuturePredicate(predicate), liftSyncMiddlewareArray(trueMiddleware), liftSyncMiddlewareArray(falseMiddleware))
    }

    public func branch(predicate: MaybePredicate, trueMiddleware: Array<MiddlewareFn>, falseMiddleware: Array<MiddlewareFn>): Composer {
        this.branch(predicate, liftSyncMiddlewareArray(trueMiddleware), liftSyncMiddlewareArray(falseMiddleware))
    }

    public func branch(predicate: Predicate, trueMiddleware: Array<AsyncMiddlewareFn>, falseMiddleware: Array<AsyncMiddlewareFn>): Composer {
        this.branch(liftFuturePredicate(predicate), liftFutureMiddlewareArray(trueMiddleware), liftFutureMiddlewareArray(falseMiddleware))
    }

    public func branch(predicate: MaybePredicate, trueMiddleware: Array<AsyncMiddlewareFn>, falseMiddleware: Array<AsyncMiddlewareFn>): Composer {
        this.branch(predicate, liftFutureMiddlewareArray(trueMiddleware), liftFutureMiddlewareArray(falseMiddleware))
    }

    public func branch(predicate: MaybePredicate, trueMiddleware: Array<MaybeMiddlewareFn>, falseMiddleware: Array<MaybeMiddlewareFn>): Composer {
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                if (predicate(ctx).get()) {
                    Composer(trueMiddleware).maybeMiddleware()(ctx, next).get()
                } else {
                    Composer(falseMiddleware).maybeMiddleware()(ctx, next).get()
                }
            })
        }
        this.use(runner)
    }

    public func errorBoundary(errorHandler: ErrorHandler): Composer {
        this.errorBoundary(errorHandler, pass)
    }

    public func errorBoundary(errorHandler: AsyncErrorHandler): Composer {
        this.errorBoundary(errorHandler, asyncPass)
    }

    public func errorBoundary(errorHandler: MaybeErrorHandler): Composer {
        this.errorBoundary(errorHandler, maybePass)
    }

    public func errorBoundary(errorHandler: ErrorHandler, middleware: MiddlewareFn): Composer {
        this.errorBoundary(errorHandler, [middleware])
    }

    public func errorBoundary(errorHandler: AsyncErrorHandler, middleware: AsyncMiddlewareFn): Composer {
        this.errorBoundary(errorHandler, [middleware])
    }

    public func errorBoundary(errorHandler: MaybeErrorHandler, middleware: MaybeMiddlewareFn): Composer {
        this.errorBoundary(errorHandler, [middleware])
    }

    public func errorBoundary(errorHandler: ErrorHandler, middleware: Array<MiddlewareFn>): Composer {
        let maybeHandler: MaybeErrorHandler = { err: BotError, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                errorHandler(err, blockingNext(next))
            })
        }
        this.errorBoundary(maybeHandler, liftSyncMiddlewareArray(middleware))
    }

    public func errorBoundary(errorHandler: AsyncErrorHandler, middleware: Array<AsyncMiddlewareFn>): Composer {
        let maybeHandler: MaybeErrorHandler = { err: BotError, next: MaybeNextFunction =>
            MaybeTask<Unit>(errorHandler(err, { => next().future() }))
        }
        this.errorBoundary(maybeHandler, liftFutureMiddlewareArray(middleware))
    }

    public func errorBoundary(errorHandler: MaybeErrorHandler, middleware: Array<MaybeMiddlewareFn>): Composer {
        let composer = Composer(middleware)
        let bound = composer.maybeMiddleware()
        let runner: MaybeMiddlewareFn = { ctx: Context, next: MaybeNextFunction =>
            MaybeTask<Unit>({ =>
                let nextCalled = NextCallState()
                let cont: MaybeNextFunction = { =>
                    nextCalled.called = true
                    resolvedUnitTask()
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
            })
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
