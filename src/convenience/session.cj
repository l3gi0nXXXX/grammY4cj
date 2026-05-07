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

public class StorageEntry<T> {
    public let key: String
    public let value: T

    public init(key: String, value: T) {
        this.key = key
        this.value = value
    }
}

public interface StorageAdapter<T> {
    func read(key: String): Option<T>
    func write(key: String, value: T): Unit
    func delete(key: String): Unit
    func has(key: String): Bool
    func readAllKeys(): Array<String>
    func readAllValues(): Array<T>
    func readAllEntries(): Array<StorageEntry<T>>
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
        match (this.read(key)) {
            case Some(_) => true
            case None => false
        }
    }

    public func readAllKeys(): Array<String> {
        let keys = ArrayList<String>()
        for ((key, _) in this.storage) {
            keys.add(key)
        }

        let live = ArrayList<String>()
        for (key in keys) {
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

    public init() {
        this.initial = None
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = MemorySessionStorage<T>()
    }

    public init(initial: SessionInitializer<T>) {
        this.initial = Some(initial)
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = MemorySessionStorage<T>()
    }

    public init(storage: StorageAdapter<T>) {
        this.initial = None
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = storage
    }

    public init(initial: SessionInitializer<T>, storage: StorageAdapter<T>) {
        this.initial = Some(initial)
        this.prefix = ""
        this.getSessionKey = defaultGetSessionKey
        this.storage = storage
    }

    public init(prefix: String, initial: Option<SessionInitializer<T>>, storage: StorageAdapter<T>, getSessionKey: SessionKeyResolver) {
        this.initial = initial
        this.prefix = prefix
        this.getSessionKey = getSessionKey
        this.storage = storage
    }
}

public class SessionContext<T> {
    public let ctx: Context
    public let key: String
    private let storage: StorageAdapter<T>
    private let initial: Option<SessionInitializer<T>>
    private var value: Option<T> = None
    private var loaded: Bool = false
    private var readRequested: Bool = false
    private var wrote: Bool = false
    private var deleted: Bool = false

    public init(ctx: Context, key: String, storage: StorageAdapter<T>, initial: Option<SessionInitializer<T>>) {
        this.ctx = ctx
        this.key = key
        this.storage = storage
        this.initial = initial
    }

    public func preload(): Unit {
        this.ensureLoaded(false)
    }

    public func session(): T {
        this.readRequested = true
        this.ensureLoaded(true)
        match (this.value) {
            case Some(value) => value
            case None => throw Exception("Cannot access session data because no value is stored and no initial value was provided.")
        }
    }

    public func maybeSession(): Option<T> {
        this.readRequested = true
        this.ensureLoaded(true)
        this.value
    }

    public func setSession(value: T): Unit {
        this.value = Some(value)
        this.loaded = true
        this.wrote = true
        this.deleted = false
    }

    public func deleteSession(): Unit {
        this.value = None
        this.loaded = true
        this.wrote = true
        this.deleted = true
    }

    public func isLoaded(): Bool {
        this.loaded
    }

    public func wasRead(): Bool {
        this.readRequested
    }

    public func wasWritten(): Bool {
        this.wrote
    }

    public func finish(): Unit {
        if (this.readRequested && !this.loaded) {
            this.ensureLoaded(true)
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

    private func ensureLoaded(markInitialWrite: Bool): Unit {
        if (this.loaded || this.wrote) {
            return
        }
        match (this.storage.read(this.key)) {
            case Some(value) =>
                this.value = Some(value)
            case None =>
                match (this.initial) {
                    case Some(makeInitial) =>
                        this.value = Some(makeInitial())
                        if (markInitialWrite) {
                            this.wrote = true
                        }
                    case None => this.value = None
                }
        }
        this.loaded = true
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

    public func middleware(handler: (SessionContext<T>, NextFunction) -> Unit): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handle(ctx, { sessionContext: SessionContext<T> =>
                handler(sessionContext, next)
            })
        }
    }

    private func createContext(ctx: Context): SessionContext<T> {
        match (this.options.getSessionKey(ctx)) {
            case Some(key) => SessionContext<T>(ctx, this.options.prefix + key, this.options.storage, this.options.initial)
            case None => throw Exception("Cannot access session data because the session key is undefined for this update.")
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

    public func middleware(handler: (SessionContext<T>, NextFunction) -> Unit): MiddlewareFn {
        { ctx: Context, next: NextFunction =>
            this.handle(ctx, { sessionContext: SessionContext<T> =>
                handler(sessionContext, next)
            })
        }
    }

    private func createContext(ctx: Context): SessionContext<T> {
        match (this.options.getSessionKey(ctx)) {
            case Some(key) => SessionContext<T>(ctx, this.options.prefix + key, this.options.storage, this.options.initial)
            case None => throw Exception("Cannot access lazy session data because the session key is undefined for this update.")
        }
    }
}

public func session<T>(): SessionMiddleware<T> {
    SessionMiddleware<T>(SessionOptions<T>())
}

public func session<T>(options: SessionOptions<T>): SessionMiddleware<T> {
    SessionMiddleware<T>(options)
}

public func lazySession<T>(): LazySessionMiddleware<T> {
    LazySessionMiddleware<T>(SessionOptions<T>())
}

public func lazySession<T>(options: SessionOptions<T>): LazySessionMiddleware<T> {
    LazySessionMiddleware<T>(options)
}

public func defaultGetSessionKey(ctx: Context): Option<String> {
    Some(ctx.updateId().toString())
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

    public func readAllKeys(): Array<String> {
        this.backing.readAllKeys()
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
