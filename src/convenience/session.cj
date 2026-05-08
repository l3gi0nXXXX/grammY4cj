package grammy4cj.convenience

import grammy4cj.composer.MiddlewareFn
import grammy4cj.composer.NextFunction
import grammy4cj.context.Context
import std.collection.{ArrayList, HashMap}
import std.time.DateTime

public type SessionKeyResolver = (Context) -> Option<String>
public type SessionInitializer<T> = () -> T
public type SessionNowMillis = () -> Int64

private let SESSION_TTL_DISABLED: Int64 = -1

public class SessionPropertyContract {
    public let upstreamProperty: String
    public let strictRead: String
    public let strictWrite: String
    public let strictDelete: String
    public let lazyRead: String
    public let multiDelete: String
    public let contextIntegration: String

    public init() {
        this.upstreamProperty = "ctx.session"
        this.strictRead = "SessionFlavorContext<T>.session"
        this.strictWrite = "SessionFlavorContext<T>.session = value"
        this.strictDelete = "SessionFlavorContext<T>.deleteSession() or setOptionalSession(None)"
        this.lazyRead = "LazySessionMiddleware + SessionFlavorContext<T>.session"
        this.multiDelete = "MultiSessionFlavorContext2<A,B>.session slots or deleteSession()"
        this.contextIntegration = "typed session flavor context exposes ctx.session property"
    }
}

public func sessionPropertyContract(): SessionPropertyContract {
    SessionPropertyContract()
}

public class StorageEntry<T> {
    public let key: String
    public let value: T

    public init(key: String, value: T) {
        this.key = key
        this.value = value
    }
}

public class SessionTask<T> {
    private let wait: () -> T

    public init(value: T) {
        this.wait = { => value }
    }

    public init(wait: () -> T) {
        this.wait = wait
    }

    public func get(): T {
        this.wait()
    }
}

public interface StorageAdapter<T> {
    func read(key: String): Option<T>
    func write(key: String, value: T): Unit
    func delete(key: String): Unit
    func has(key: String): Bool
    func readAll(): Array<T>
    func readAllKeys(): Array<String>
    func readAllValues(): Array<T>
    func readAllEntries(): Array<StorageEntry<T>>
}

public interface AsyncStorageAdapter<T> {
    func read(key: String): SessionTask<Option<T>>
    func write(key: String, value: T): SessionTask<Unit>
    func delete(key: String): SessionTask<Unit>
    func has(key: String): SessionTask<Bool>
    func readAll(): SessionTask<Array<T>>
    func readAllKeys(): SessionTask<Array<String>>
    func readAllValues(): SessionTask<Array<T>>
    func readAllEntries(): SessionTask<Array<StorageEntry<T>>>
}

public class AsyncStorageAdapterShim<T> <: StorageAdapter<T> {
    private let storage: AsyncStorageAdapter<T>

    public init(storage: AsyncStorageAdapter<T>) {
        this.storage = storage
    }

    public func read(key: String): Option<T> {
        this.storage.read(key).get()
    }

    public func write(key: String, value: T): Unit {
        this.storage.write(key, value).get()
    }

    public func delete(key: String): Unit {
        this.storage.delete(key).get()
    }

    public func has(key: String): Bool {
        this.storage.has(key).get()
    }

    public func readAll(): Array<T> {
        this.storage.readAll().get()
    }

    public func readAllKeys(): Array<String> {
        this.storage.readAllKeys().get()
    }

    public func readAllValues(): Array<T> {
        this.storage.readAllValues().get()
    }

    public func readAllEntries(): Array<StorageEntry<T>> {
        this.storage.readAllEntries().get()
    }
}

public class MemorySessionRecord<T> {
    public let session: T
    public let expiresAtMillis: Int64
    public let hasExpiresAtMillis: Bool

    public init(session: T) {
        this.session = session
        this.expiresAtMillis = 0
        this.hasExpiresAtMillis = false
    }

    public init(session: T, expiresAtMillis: Int64) {
        this.session = session
        this.expiresAtMillis = expiresAtMillis
        this.hasExpiresAtMillis = true
    }
}

public class MemorySessionStorage<T> <: StorageAdapter<T> {
    private let storage: HashMap<String, MemorySessionRecord<T>> = HashMap<String, MemorySessionRecord<T>>()
    private let timeToLiveMillis: Int64
    private let nowMillis: SessionNowMillis

    public init() {
        this.timeToLiveMillis = SESSION_TTL_DISABLED
        this.nowMillis = systemSessionNowMillis
    }

    public init(timeToLiveMillis: Int64) {
        this.timeToLiveMillis = timeToLiveMillis
        this.nowMillis = systemSessionNowMillis
    }

    public init(timeToLiveMillis: Int64, nowMillis: SessionNowMillis) {
        this.timeToLiveMillis = timeToLiveMillis
        this.nowMillis = nowMillis
    }

    public func read(key: String): Option<T> {
        match (this.storage.get(key)) {
            case Some(record) =>
                if (this.isExpired(record)) {
                    this.delete(key)
                    return None
                }
                Some(record.session)
            case None => None
        }
    }

    public func write(key: String, value: T): Unit {
        if (this.timeToLiveMillis >= 0) {
            this.storage[key] = MemorySessionRecord<T>(value, this.nowMillis() + this.timeToLiveMillis)
        } else {
            this.storage[key] = MemorySessionRecord<T>(value)
        }
    }

    public func delete(key: String): Unit {
        this.storage.remove(key)
    }

    public func has(key: String): Bool {
        match (this.storage.get(key)) {
            case Some(_) => true
            case None => false
        }
    }

    public func readAll(): Array<T> {
        this.readAllValues()
    }

    public func readAllKeys(): Array<String> {
        let keys = ArrayList<String>()
        for ((key, _) in this.storage) {
            keys.add(key)
        }
        keys.toArray()
    }

    public func readAllValues(): Array<T> {
        let values = ArrayList<T>()
        for (key in this.readAllKeys()) {
            match (this.read(key)) {
                case Some(value) => values.add(value)
                case None => ()
            }
        }
        values.toArray()
    }

    public func readAllEntries(): Array<StorageEntry<T>> {
        let entries = ArrayList<StorageEntry<T>>()
        for (key in this.readAllKeys()) {
            match (this.read(key)) {
                case Some(value) => entries.add(StorageEntry<T>(key, value))
                case None => ()
            }
        }
        entries.toArray()
    }

    public func size(): Int64 {
        this.readAllKeys().size
    }

    private func isExpired(record: MemorySessionRecord<T>): Bool {
        record.hasExpiresAtMillis && record.expiresAtMillis < this.nowMillis()
    }
}

public class SessionOptions<T> {
    public var initial: Option<SessionInitializer<T>>
    public var prefix: String
    public var getSessionKey: SessionKeyResolver
    public var storage: StorageAdapter<T>
    public var customGetSessionKey: Bool

    public init() {
        this.initial = None
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = MemorySessionStorage<T>()
        this.customGetSessionKey = false
    }

    public init(initial: SessionInitializer<T>) {
        this.initial = Some(initial)
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = MemorySessionStorage<T>()
        this.customGetSessionKey = false
    }

    public init(storage: StorageAdapter<T>) {
        this.initial = None
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = storage
        this.customGetSessionKey = false
    }

    public init(storage: AsyncStorageAdapter<T>) {
        this.initial = None
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = AsyncStorageAdapterShim<T>(storage)
        this.customGetSessionKey = false
    }

    public init(initial: SessionInitializer<T>, storage: StorageAdapter<T>) {
        this.initial = Some(initial)
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = storage
        this.customGetSessionKey = false
    }

    public init(initial: SessionInitializer<T>, storage: AsyncStorageAdapter<T>) {
        this.initial = Some(initial)
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = AsyncStorageAdapterShim<T>(storage)
        this.customGetSessionKey = false
    }

    public init(prefix: String, initial: Option<SessionInitializer<T>>, storage: StorageAdapter<T>, getSessionKey: SessionKeyResolver) {
        this.initial = initial
        this.prefix = prefix
        this.getSessionKey = getSessionKey
        this.storage = storage
        this.customGetSessionKey = true
    }

    public init(prefix: String, initial: Option<SessionInitializer<T>>, storage: AsyncStorageAdapter<T>, getSessionKey: SessionKeyResolver) {
        this.initial = initial
        this.prefix = prefix
        this.getSessionKey = getSessionKey
        this.storage = AsyncStorageAdapterShim<T>(storage)
        this.customGetSessionKey = true
    }
}

private class PropertySession<T> {
    private let storage: StorageAdapter<T>
    private let initial: Option<SessionInitializer<T>>
    private let key: String
    private let hasKey: Bool
    private let lazy: Bool
    private let custom: Bool
    private var value: Option<T> = None
    private var fetching: Bool = false
    private var loaded: Bool = false
    private var readRequested: Bool = false
    private var wrote: Bool = false
    private var deleted: Bool = false
    private var pending: Option<SessionTask<Option<T>>> = None<SessionTask<Option<T>>>

    public init(key: Option<String>, storage: StorageAdapter<T>, initial: Option<SessionInitializer<T>>, lazy: Bool, custom: Bool) {
        this.key = sessionKeyValue(key)
        this.hasKey = sessionKeyPresent(key)
        this.storage = storage
        this.initial = initial
        this.lazy = lazy
        this.custom = custom
    }

    public func preload(): Unit {
        this.load()
    }

    public func get(): T {
        this.requireKey("access")
        this.readRequested = true
        this.resolvePending()
        if (!this.lazy || this.wrote) {
            ()
        } else {
            this.load()
        }
        match (this.value) {
            case Some(value) => value
            case None => throw Exception("Cannot access session data because no value is stored and no initial value was provided.")
        }
    }

    public func maybeSession(): Option<T> {
        this.requireKey("access")
        this.readRequested = true
        this.resolvePending()
        if (!this.lazy || this.wrote) {
            ()
        } else {
            this.load()
        }
        this.value
    }

    public func set(value: T): Unit {
        this.requireKey("assign")
        this.value = Some(value)
        this.loaded = true
        this.wrote = true
        this.deleted = false
        this.fetching = false
        this.pending = None<SessionTask<Option<T>>>
    }

    public func setOptional(value: Option<T>): Unit {
        match (value) {
            case Some(v) => this.set(v)
            case None => this.delete()
        }
    }

    public func setTask(task: SessionTask<T>): Unit {
        this.setOptionalTask(SessionTask<Option<T>>({ => Some(task.get()) }))
    }

    public func setOptionalTask(task: SessionTask<Option<T>>): Unit {
        this.requireKey("assign")
        this.pending = Some(task)
        this.value = None<T>
        this.loaded = true
        this.wrote = true
        this.deleted = false
        this.fetching = false
    }

    public func delete(): Unit {
        this.requireKey("assign")
        this.value = None
        this.loaded = true
        this.wrote = true
        this.deleted = true
        this.fetching = false
        this.pending = None<SessionTask<Option<T>>>
    }

    public func deleteIfKeyPresent(): Unit {
        if (this.hasKey) {
            this.delete()
        }
    }

    public func isLoaded(): Bool {
        this.loaded
    }

    public func hasSessionKey(): Bool {
        this.hasKey
    }

    public func wasRead(): Bool {
        this.readRequested
    }

    public func wasWritten(): Bool {
        this.wrote
    }

    public func isFetching(): Bool {
        this.fetching
    }

    public func finish(): Unit {
        if (!this.hasKey) {
            return
        }
        this.resolvePending()
        if (this.readRequested) {
            this.load()
        }
        if (this.deleted) {
            this.storage.delete(this.key)
            return
        }
        if (this.readRequested || this.wrote) {
            match (this.value) {
                case Some(value) => this.storage.write(this.key, value)
                case None => this.storage.delete(this.key)
            }
        }
    }

    private func resolvePending(): Unit {
        match (this.pending) {
            case Some(task) =>
                let resolved = task.get()
                this.pending = None<SessionTask<Option<T>>>
                match (resolved) {
                    case Some(value) =>
                        this.value = Some(value)
                        this.deleted = false
                    case None =>
                        this.value = None<T>
                        this.deleted = true
                }
                this.loaded = true
                this.wrote = true
                this.fetching = false
            case None => ()
        }
    }

    private func load(): Unit {
        if (!this.hasKey) {
            return
        }
        if (this.loaded || this.wrote) {
            return
        }
        this.fetching = true
        let stored = this.storage.read(this.key)
        this.fetching = false
        if (this.wrote) {
            return
        }
        match (stored) {
            case Some(value) =>
                this.value = Some(value)
            case None =>
                match (this.initial) {
                    case Some(makeInitial) =>
                        this.value = Some(makeInitial())
                        this.wrote = true
                    case None => this.value = None
                }
        }
        this.loaded = true
    }

    private func requireKey(op: String): Unit {
        if (!this.hasKey) {
            throw Exception(undefinedSessionKeyMessage(op, this.lazy, this.custom))
        }
    }
}

public class SessionContext<T> {
    public let ctx: Context
    public let key: String
    private let property: PropertySession<T>

    public init(ctx: Context, key: String, storage: StorageAdapter<T>, initial: Option<SessionInitializer<T>>) {
        this.ctx = ctx
        this.key = key
        this.property = PropertySession<T>(Some(key), storage, initial, false, false)
    }

    public init(ctx: Context, key: Option<String>, storage: StorageAdapter<T>, initial: Option<SessionInitializer<T>>, lazy: Bool, custom: Bool) {
        this.ctx = ctx
        this.key = sessionKeyValue(key)
        this.property = PropertySession<T>(key, storage, initial, lazy, custom)
    }

    public mut prop session: T {
        get() {
            this.property.get()
        }
        set(value) {
            this.property.set(value)
        }
    }

    public func preload(): Unit {
        this.property.preload()
    }

    public func maybeSession(): Option<T> {
        this.property.maybeSession()
    }

    public func setSession(value: T): Unit {
        this.session = value
    }

    public func setOptionalSession(value: Option<T>): Unit {
        this.property.setOptional(value)
    }

    public func setSessionTask(task: SessionTask<T>): Unit {
        this.property.setTask(task)
    }

    public func setOptionalSessionTask(task: SessionTask<Option<T>>): Unit {
        this.property.setOptionalTask(task)
    }

    public func deleteSession(): Unit {
        this.property.delete()
    }

    public func deleteSessionIfKeyPresent(): Unit {
        this.property.deleteIfKeyPresent()
    }

    public func isLoaded(): Bool {
        this.property.isLoaded()
    }

    public func hasSessionKey(): Bool {
        this.property.hasSessionKey()
    }

    public func wasRead(): Bool {
        this.property.wasRead()
    }

    public func wasWritten(): Bool {
        this.property.wasWritten()
    }

    public func isFetching(): Bool {
        this.property.isFetching()
    }

    public func finish(): Unit {
        this.property.finish()
    }
}

public class SessionFlavorContext<T> {
    public let ctx: Context
    private let sessionContext: SessionContext<T>

    public init(sessionContext: SessionContext<T>) {
        this.ctx = sessionContext.ctx
        this.sessionContext = sessionContext
    }

    public mut prop session: T {
        get() {
            this.sessionContext.session
        }
        set(value) {
            this.sessionContext.session = value
        }
    }

    public prop chatId: Int64 {
        get() { this.ctx.chatId }
    }

    public func updateId(): Int64 {
        this.ctx.updateId()
    }

    public func botInfoUsername(): String {
        this.ctx.botInfoUsername()
    }

    public func maybeSession(): Option<T> {
        this.sessionContext.maybeSession()
    }

    public func setSession(value: T): Unit {
        this.session = value
    }

    public func setOptionalSession(value: Option<T>): Unit {
        this.sessionContext.setOptionalSession(value)
    }

    public func setSessionTask(task: SessionTask<T>): Unit {
        this.sessionContext.setSessionTask(task)
    }

    public func setOptionalSessionTask(task: SessionTask<Option<T>>): Unit {
        this.sessionContext.setOptionalSessionTask(task)
    }

    public func deleteSession(): Unit {
        this.sessionContext.deleteSession()
    }

    public func isLoaded(): Bool {
        this.sessionContext.isLoaded()
    }

    public func hasSessionKey(): Bool {
        this.sessionContext.hasSessionKey()
    }

    public func wasRead(): Bool {
        this.sessionContext.wasRead()
    }

    public func wasWritten(): Bool {
        this.sessionContext.wasWritten()
    }

    public func isFetching(): Bool {
        this.sessionContext.isFetching()
    }
}

public class SessionMiddleware<T> {
    private let options: SessionOptions<T>

    public init(options: SessionOptions<T>) {
        this.options = options
    }

    public func handle(ctx: Context, handler: (SessionContext<T>) -> Unit): Unit {
        let sessionContext = this.createContext(ctx)
        sessionContext.preload()
        handler(sessionContext)
        sessionContext.finish()
    }

    public func handle(ctx: Context, handler: (SessionFlavorContext<T>) -> Unit): Unit {
        this.handle(ctx, { sessionContext: SessionContext<T> =>
            handler(SessionFlavorContext<T>(sessionContext))
        })
    }

    public func middleware(handler: (SessionContext<T>, NextFunction) -> Unit): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handle(ctx, { sessionContext: SessionContext<T> =>
                handler(sessionContext, next)
            })
        }
    }

    public func middleware(handler: (SessionFlavorContext<T>, NextFunction) -> Unit): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handle(ctx, { sessionContext: SessionContext<T> =>
                handler(SessionFlavorContext<T>(sessionContext), next)
            })
        }
    }

    private func createContext(ctx: Context): SessionContext<T> {
        match (this.options.getSessionKey(ctx)) {
            case Some(key) => SessionContext<T>(ctx, Some(this.options.prefix + key), this.options.storage, this.options.initial, false, this.options.customGetSessionKey)
            case None => SessionContext<T>(ctx, None<String>, this.options.storage, this.options.initial, false, this.options.customGetSessionKey)
        }
    }
}

public class LazySessionMiddleware<T> {
    private let options: SessionOptions<T>

    public init(options: SessionOptions<T>) {
        this.options = options
    }

    public func handle(ctx: Context, handler: (SessionContext<T>) -> Unit): Unit {
        let sessionContext = this.createContext(ctx)
        handler(sessionContext)
        sessionContext.finish()
    }

    public func handle(ctx: Context, handler: (SessionFlavorContext<T>) -> Unit): Unit {
        this.handle(ctx, { sessionContext: SessionContext<T> =>
            handler(SessionFlavorContext<T>(sessionContext))
        })
    }

    public func middleware(handler: (SessionContext<T>, NextFunction) -> Unit): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handle(ctx, { sessionContext: SessionContext<T> =>
                handler(sessionContext, next)
            })
        }
    }

    public func middleware(handler: (SessionFlavorContext<T>, NextFunction) -> Unit): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handle(ctx, { sessionContext: SessionContext<T> =>
                handler(SessionFlavorContext<T>(sessionContext), next)
            })
        }
    }

    private func createContext(ctx: Context): SessionContext<T> {
        match (this.options.getSessionKey(ctx)) {
            case Some(key) => SessionContext<T>(ctx, Some(this.options.prefix + key), this.options.storage, this.options.initial, true, this.options.customGetSessionKey)
            case None => SessionContext<T>(ctx, None<String>, this.options.storage, this.options.initial, true, this.options.customGetSessionKey)
        }
    }
}

public class MultiSessionOptions2<A, B> {
    public var first: SessionOptions<A>
    public var second: SessionOptions<B>

    public init(first: SessionOptions<A>, second: SessionOptions<B>) {
        this.first = first
        this.second = second
    }
}

public class MultiSessionContext2<A, B> {
    public let ctx: Context
    public let first: SessionContext<A>
    public let second: SessionContext<B>

    public init(ctx: Context, first: SessionContext<A>, second: SessionContext<B>) {
        this.ctx = ctx
        this.first = first
        this.second = second
    }

    public func preload(): Unit {
        this.first.preload()
        this.second.preload()
    }

    public func deleteSession(): Unit {
        this.first.deleteSessionIfKeyPresent()
        this.second.deleteSessionIfKeyPresent()
    }

    public func finish(): Unit {
        this.first.finish()
        this.second.finish()
    }
}

public class MultiSessionData2<A, B> {
    private let firstContext: SessionContext<A>
    private let secondContext: SessionContext<B>

    public init(first: SessionContext<A>, second: SessionContext<B>) {
        this.firstContext = first
        this.secondContext = second
    }

    public mut prop first: A {
        get() {
            this.firstContext.session
        }
        set(value) {
            this.firstContext.session = value
        }
    }

    public mut prop second: B {
        get() {
            this.secondContext.session
        }
        set(value) {
            this.secondContext.session = value
        }
    }

    public func deleteFirst(): Unit {
        this.firstContext.deleteSession()
    }

    public func deleteSecond(): Unit {
        this.secondContext.deleteSession()
    }

    public func setOptionalFirst(value: Option<A>): Unit {
        this.firstContext.setOptionalSession(value)
    }

    public func setOptionalSecond(value: Option<B>): Unit {
        this.secondContext.setOptionalSession(value)
    }
}

public class MultiSessionFlavorContext2<A, B> {
    public let ctx: Context
    public let session: MultiSessionData2<A, B>
    private let sessionContext: MultiSessionContext2<A, B>

    public init(sessionContext: MultiSessionContext2<A, B>) {
        this.ctx = sessionContext.ctx
        this.sessionContext = sessionContext
        this.session = MultiSessionData2<A, B>(sessionContext.first, sessionContext.second)
    }

    public prop chatId: Int64 {
        get() { this.ctx.chatId }
    }

    public func updateId(): Int64 {
        this.ctx.updateId()
    }

    public func deleteSession(): Unit {
        this.sessionContext.deleteSession()
    }

    public func setOptionalSession(value: Option<MultiSessionData2<A, B>>): Unit {
        match (value) {
            case Some(_) => ()
            case None => this.deleteSession()
        }
    }
}

public class MultiSessionMiddleware2<A, B> {
    private let options: MultiSessionOptions2<A, B>

    public init(options: MultiSessionOptions2<A, B>) {
        this.options = options
    }

    public func handle(ctx: Context, handler: (MultiSessionContext2<A, B>) -> Unit): Unit {
        let sessionContext = this.createContext(ctx)
        sessionContext.preload()
        handler(sessionContext)
        sessionContext.finish()
    }

    public func handle(ctx: Context, handler: (MultiSessionFlavorContext2<A, B>) -> Unit): Unit {
        this.handle(ctx, { sessionContext: MultiSessionContext2<A, B> =>
            handler(MultiSessionFlavorContext2<A, B>(sessionContext))
        })
    }

    private func createContext(ctx: Context): MultiSessionContext2<A, B> {
        MultiSessionContext2<A, B>(
            ctx,
            this.createFirstContext(ctx),
            this.createSecondContext(ctx),
        )
    }

    private func createFirstContext(ctx: Context): SessionContext<A> {
        match (this.options.first.getSessionKey(ctx)) {
            case Some(key) => SessionContext<A>(ctx, Some(this.options.first.prefix + key), this.options.first.storage, this.options.first.initial, false, this.options.first.customGetSessionKey)
            case None => SessionContext<A>(ctx, None<String>, this.options.first.storage, this.options.first.initial, false, this.options.first.customGetSessionKey)
        }
    }

    private func createSecondContext(ctx: Context): SessionContext<B> {
        match (this.options.second.getSessionKey(ctx)) {
            case Some(key) => SessionContext<B>(ctx, Some(this.options.second.prefix + key), this.options.second.storage, this.options.second.initial, false, this.options.second.customGetSessionKey)
            case None => SessionContext<B>(ctx, None<String>, this.options.second.storage, this.options.second.initial, false, this.options.second.customGetSessionKey)
        }
    }
}

public func session<T>(): SessionMiddleware<T> {
    SessionMiddleware<T>(SessionOptions<T>())
}

public func session<T>(options: SessionOptions<T>): SessionMiddleware<T> {
    SessionMiddleware<T>(options)
}

public func session<A, B>(options: MultiSessionOptions2<A, B>): MultiSessionMiddleware2<A, B> {
    MultiSessionMiddleware2<A, B>(options)
}

public func multiSession<A, B>(options: MultiSessionOptions2<A, B>): MultiSessionMiddleware2<A, B> {
    MultiSessionMiddleware2<A, B>(options)
}

public func lazySession<T>(): LazySessionMiddleware<T> {
    LazySessionMiddleware<T>(SessionOptions<T>())
}

public func lazySession<T>(options: SessionOptions<T>): LazySessionMiddleware<T> {
    LazySessionMiddleware<T>(options)
}

public func lazySession<A, B>(options: MultiSessionOptions2<A, B>): LazySessionMiddleware<A> {
    throw Exception("Cannot use lazy multi sessions!")
}

public func defaultGetSessionKey(ctx: Context): Option<String> {
    let chatId = ctx.chatId
    if (chatId == 0) {
        None<String>
    } else {
        Some(chatId.toString())
    }
}

private func sessionKeyValue(key: Option<String>): String {
    match (key) {
        case Some(value) => value
        case None => ""
    }
}

private func sessionKeyPresent(key: Option<String>): Bool {
    match (key) {
        case Some(_) => true
        case None => false
    }
}

private func undefinedSessionKeyMessage(op: String, lazy: Bool, custom: Bool): String {
    let kind = if (lazy) { "lazy session" } else { "session" }
    let reason = if (custom) {
        "the custom `getSessionKey` function returned undefined for this update"
    } else {
        "this update does not belong to a chat, so the session key is undefined"
    }
    "Cannot " + op + " " + kind + " data because " + reason + "!"
}

public class SessionEnvelope<T> {
    public var version: Int64
    public var hasVersion: Bool
    public var data: T
    public var expiresAtMillis: Int64
    public var hasExpiresAtMillis: Bool

    public init(data: T) {
        this.version = 0
        this.hasVersion = false
        this.data = data
        this.expiresAtMillis = 0
        this.hasExpiresAtMillis = false
    }

    public init(data: T, version: Int64) {
        this.version = version
        this.hasVersion = true
        this.data = data
        this.expiresAtMillis = 0
        this.hasExpiresAtMillis = false
    }

    public func copyWithData(data: T): SessionEnvelope<T> {
        let envelope = SessionEnvelope<T>(data)
        envelope.version = this.version
        envelope.hasVersion = this.hasVersion
        envelope.expiresAtMillis = this.expiresAtMillis
        envelope.hasExpiresAtMillis = this.hasExpiresAtMillis
        envelope
    }

    public func setExpiry(expiresAtMillis: Int64): Unit {
        this.expiresAtMillis = expiresAtMillis
        this.hasExpiresAtMillis = true
    }

    public func setVersion(version: Int64): Unit {
        this.version = version
        this.hasVersion = true
    }
}

public class MigrationOptions<T> {
    public let storage: StorageAdapter<SessionEnvelope<T>>
    public let migrations: HashMap<Int64, (T) -> T>
    public let hasMigrations: Bool
    public let millisecondsToLive: Int64
    public let hasMillisecondsToLive: Bool
    public let nowMillis: SessionNowMillis

    public init(storage: StorageAdapter<SessionEnvelope<T>>) {
        this.storage = storage
        this.migrations = HashMap<Int64, (T) -> T>()
        this.hasMigrations = false
        this.millisecondsToLive = 0
        this.hasMillisecondsToLive = false
        this.nowMillis = systemSessionNowMillis
    }

    public init(storage: StorageAdapter<SessionEnvelope<T>>, millisecondsToLive: Int64, nowMillis: SessionNowMillis) {
        this.storage = storage
        this.migrations = HashMap<Int64, (T) -> T>()
        this.hasMigrations = false
        this.millisecondsToLive = millisecondsToLive
        this.hasMillisecondsToLive = true
        this.nowMillis = nowMillis
    }

    public init(storage: StorageAdapter<SessionEnvelope<T>>, migrations: HashMap<Int64, (T) -> T>) {
        this.storage = storage
        this.migrations = migrations
        this.hasMigrations = true
        this.millisecondsToLive = 0
        this.hasMillisecondsToLive = false
        this.nowMillis = systemSessionNowMillis
    }

    public init(storage: StorageAdapter<SessionEnvelope<T>>, migrations: HashMap<Int64, (T) -> T>, millisecondsToLive: Int64, nowMillis: SessionNowMillis) {
        this.storage = storage
        this.migrations = migrations
        this.hasMigrations = true
        this.millisecondsToLive = millisecondsToLive
        this.hasMillisecondsToLive = true
        this.nowMillis = nowMillis
    }
}

public func enhanceStorage<T>(options: MigrationOptions<T>): StorageAdapter<T> {
    EnhancedStorage<T>(options)
}

private class EnhancedStorage<T> <: StorageAdapter<T> {
    private let backing: StorageAdapter<SessionEnvelope<T>>
    private let migrations: HashMap<Int64, (T) -> T>
    private let hasMigrations: Bool
    private let versions: ArrayList<Int64>
    private let latest: Int64
    private let millisecondsToLive: Int64
    private let hasMillisecondsToLive: Bool
    private let nowMillis: SessionNowMillis

    public init(options: MigrationOptions<T>) {
        this.backing = options.storage
        this.migrations = options.migrations
        this.hasMigrations = options.hasMigrations
        this.versions = if (options.hasMigrations) {
            sortedMigrationVersions(options.migrations)
        } else {
            ArrayList<Int64>()
        }
        this.latest = if (this.versions.size > 0) { this.versions[this.versions.size - 1] } else { 0 }
        this.millisecondsToLive = options.millisecondsToLive
        this.hasMillisecondsToLive = options.hasMillisecondsToLive
        this.nowMillis = options.nowMillis
        if (this.hasMigrations && this.versions.size == 0) {
            throw Exception("No migrations given!")
        }
    }

    public func read(key: String): Option<T> {
        match (this.backing.read(key)) {
            case Some(envelope) =>
                if (this.hasMillisecondsToLive) {
                    if (!envelope.hasExpiresAtMillis) {
                        envelope.setExpiry(this.nowMillis() + this.millisecondsToLive)
                        this.backing.write(key, envelope)
                    } else if (envelope.expiresAtMillis < this.nowMillis()) {
                        this.backing.delete(key)
                        return None
                    }
                }

                if (this.hasMigrations) {
                    let current = if (envelope.hasVersion) { envelope.version } else { this.versions[0] - 1 }
                    var value = envelope.data
                    for (version in this.versions) {
                        if (version > current) {
                            match (this.migrations.get(version)) {
                                case Some(migration) => value = migration(value)
                                case None => ()
                            }
                        }
                    }
                    return Some(value)
                }

                return Some(envelope.data)
            case None => return None
        }
    }

    public func write(key: String, value: T): Unit {
        let envelope = SessionEnvelope<T>(value)
        if (this.hasMigrations) {
            envelope.setVersion(this.latest)
        }
        if (this.hasMillisecondsToLive) {
            envelope.setExpiry(this.nowMillis() + this.millisecondsToLive)
        }
        this.backing.write(key, envelope)
    }

    public func delete(key: String): Unit {
        this.backing.delete(key)
    }

    public func has(key: String): Bool {
        match (this.read(key)) {
            case Some(_) => true
            case None => false
        }
    }

    public func readAll(): Array<T> {
        this.readAllValues()
    }

    public func readAllKeys(): Array<String> {
        let live = ArrayList<String>()
        for (key in this.backing.readAllKeys()) {
            match (this.read(key)) {
                case Some(_) => live.add(key)
                case None => ()
            }
        }
        live.toArray()
    }

    public func readAllValues(): Array<T> {
        let values = ArrayList<T>()
        for (key in this.readAllKeys()) {
            match (this.read(key)) {
                case Some(value) => values.add(value)
                case None => ()
            }
        }
        values.toArray()
    }

    public func readAllEntries(): Array<StorageEntry<T>> {
        let entries = ArrayList<StorageEntry<T>>()
        for (key in this.readAllKeys()) {
            match (this.read(key)) {
                case Some(value) => entries.add(StorageEntry<T>(key, value))
                case None => ()
            }
        }
        entries.toArray()
    }
}

private func systemSessionNowMillis(): Int64 {
    DateTime.now().toUnixTimeStamp().toMilliseconds()
}

private func sortedMigrationVersions<T>(migrations: HashMap<Int64, (T) -> T>): ArrayList<Int64> {
    let remaining = ArrayList<Int64>()
    for ((version, _) in migrations) {
        remaining.add(version)
    }

    let sorted = ArrayList<Int64>()
    while (remaining.size > 0) {
        var minIndex: Int64 = 0
        var minVersion = remaining[0]
        var i: Int64 = 1
        while (i < remaining.size) {
            if (remaining[i] < minVersion) {
                minVersion = remaining[i]
                minIndex = i
            }
            i += 1
        }
        sorted.add(minVersion)
        remaining.remove(at: minIndex)
    }
    sorted
}
