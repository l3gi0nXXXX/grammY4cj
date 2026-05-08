package grammy4cj.convenience

import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.types.{Chat, Message, Update, UserFromGetMe}
import std.collection.{ArrayList, HashMap}
import std.sync.Mutex
import std.unittest.*

private class CounterSession {
    public var count: Int64

    public init(count: Int64) {
        this.count = count
    }
}

private class TestClock {
    public var nowMillis: Int64

    public init(nowMillis: Int64) {
        this.nowMillis = nowMillis
    }
}

private class CountingStorage<T> <: StorageEnumerableAdapter<T> {
    public let inner: MemorySessionStorage<T> = MemorySessionStorage<T>()
    public var readCount: Int64 = 0
    public var writeCount: Int64 = 0
    public var deleteCount: Int64 = 0
    public let events: ArrayList<String> = ArrayList<String>()

    public init() {}

    public func read(key: String): Option<T> {
        this.readCount += 1
        this.events.add("read:" + key)
        this.inner.read(key)
    }

    public func write(key: String, value: T): Unit {
        this.writeCount += 1
        this.events.add("write:" + key)
        this.inner.write(key, value)
    }

    public func delete(key: String): Unit {
        this.deleteCount += 1
        this.events.add("delete:" + key)
        this.inner.delete(key)
    }

    public func has(key: String): Bool {
        this.inner.has(key)
    }

    public func readAll(): Array<T> {
        this.inner.readAll()
    }

    public func readAllKeys(): Array<String> {
        this.inner.readAllKeys()
    }

    public func readAllValues(): Array<T> {
        this.inner.readAllValues()
    }

    public func readAllEntries(): Array<StorageEntry<T>> {
        this.inner.readAllEntries()
    }
}

private class AsyncCountingStorage<T> <: AsyncStorageEnumerableAdapter<T> {
    public let inner: CountingStorage<T> = CountingStorage<T>()

    public init() {}

    public func read(key: String): SessionTask<Option<T>> {
        SessionTask<Option<T>>({ => this.inner.read(key) })
    }

    public func write(key: String, value: T): SessionTask<Unit> {
        SessionTask<Unit>({ => this.inner.write(key, value) })
    }

    public func delete(key: String): SessionTask<Unit> {
        SessionTask<Unit>({ => this.inner.delete(key) })
    }

    public func has(key: String): SessionTask<Bool> {
        SessionTask<Bool>({ => this.inner.has(key) })
    }

    public func readAll(): SessionTask<Array<T>> {
        SessionTask<Array<T>>({ => this.inner.readAll() })
    }

    public func readAllKeys(): SessionTask<Array<String>> {
        SessionTask<Array<String>>({ => this.inner.readAllKeys() })
    }

    public func readAllValues(): SessionTask<Array<T>> {
        SessionTask<Array<T>>({ => this.inner.readAllValues() })
    }

    public func readAllEntries(): SessionTask<Array<StorageEntry<T>>> {
        SessionTask<Array<StorageEntry<T>>>({ => this.inner.readAllEntries() })
    }
}

private class AsyncMinimalStorage<T> <: AsyncStorageAdapter<T> {
    public let inner: MinimalStorage<T> = MinimalStorage<T>()

    public init() {}

    public func read(key: String): SessionTask<Option<T>> {
        SessionTask<Option<T>>({ => this.inner.read(key) })
    }

    public func write(key: String, value: T): SessionTask<Unit> {
        SessionTask<Unit>({ => this.inner.write(key, value) })
    }

    public func delete(key: String): SessionTask<Unit> {
        SessionTask<Unit>({ => this.inner.delete(key) })
    }
}

private class MinimalStorage<T> <: StorageAdapter<T> {
    public let inner: MemorySessionStorage<T> = MemorySessionStorage<T>()
    public var readCount: Int64 = 0
    public var writeCount: Int64 = 0
    public var deleteCount: Int64 = 0

    public init() {}

    public func read(key: String): Option<T> {
        this.readCount += 1
        this.inner.read(key)
    }

    public func write(key: String, value: T): Unit {
        this.writeCount += 1
        this.inner.write(key, value)
    }

    public func delete(key: String): Unit {
        this.deleteCount += 1
        this.inner.delete(key)
    }
}

private class BlockingReadStorage<T> <: StorageAdapter<T> {
    private let mutex: Mutex = Mutex()
    private var entered: Bool = false
    private var released: Bool = false
    public var value: Option<T>
    public var readCount: Int64 = 0
    public var writeCount: Int64 = 0
    public var deleteCount: Int64 = 0
    public var written: Option<T> = None<T>

    public init(value: Option<T>) {
        this.value = value
    }

    public func release(): Unit {
        synchronized(this.mutex) {
            this.released = true
        }
    }

    public func waitUntilEntered(): Unit {
        var done = false
        while (!done) {
            synchronized(this.mutex) {
                done = this.entered
            }
        }
    }

    public func read(key: String): Option<T> {
        synchronized(this.mutex) {
            this.entered = true
            this.readCount += 1
        }
        var done = false
        while (!done) {
            synchronized(this.mutex) {
                done = this.released
            }
        }
        this.value
    }

    public func write(key: String, value: T): Unit {
        this.writeCount += 1
        this.written = Some(value)
    }

    public func delete(key: String): Unit {
        this.deleteCount += 1
        this.written = None<T>
    }

    public func has(key: String): Bool {
        match (this.value) {
            case Some(_) => true
            case None => false
        }
    }

    public func readAll(): Array<T> {
        this.readAllValues()
    }

    public func readAllKeys(): Array<String> {
        []
    }

    public func readAllValues(): Array<T> {
        []
    }

    public func readAllEntries(): Array<StorageEntry<T>> {
        []
    }
}

private class ThrowingReadStorage<T> <: StorageAdapter<T> {
    public var writeCount: Int64 = 0
    public var deleteCount: Int64 = 0

    public init() {}

    public func read(key: String): Option<T> {
        throw Exception("read failed:" + key)
    }

    public func write(key: String, value: T): Unit {
        this.writeCount += 1
    }

    public func delete(key: String): Unit {
        this.deleteCount += 1
    }

    public func has(key: String): Bool {
        false
    }

    public func readAll(): Array<T> {
        []
    }

    public func readAllKeys(): Array<String> {
        []
    }

    public func readAllValues(): Array<T> {
        []
    }

    public func readAllEntries(): Array<StorageEntry<T>> {
        []
    }
}

private func testCtx(updateId: Int64): Context {
    Context(Update.withMessage(updateId, Message(1, Chat(updateId, "private"), "")), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
}

private func noChatCtx(updateId: Int64): Context {
    Context(Update(updateId), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
}

private func stringValue(value: Option<String>): String {
    match (value) {
        case Some(v) => v
        case None => ""
    }
}

private func intValue(value: Option<Int64>): Int64 {
    match (value) {
        case Some(v) => v
        case None => -1
    }
}

private func counterValue(value: Option<CounterSession>): Int64 {
    match (value) {
        case Some(v) => v.count
        case None => -1
    }
}

private func envelopeCounter(value: Option<SessionEnvelope<CounterSession>>): CounterSession {
    match (value) {
        case Some(v) => v.data
        case None => CounterSession(-1)
    }
}

private func envelopeVersion(value: Option<SessionEnvelope<CounterSession>>): Int64 {
    match (value) {
        case Some(v) => v.version
        case None => -1
    }
}

private func envelopeExpiry(value: Option<SessionEnvelope<CounterSession>>): Int64 {
    match (value) {
        case Some(v) => v.expiresAtMillis
        case None => -1
    }
}

private func envelopeHasExpiry(value: Option<SessionEnvelope<CounterSession>>): Bool {
    match (value) {
        case Some(v) => v.hasExpiresAtMillis
        case None => false
    }
}

private func throwsException(action: () -> Unit): Bool {
    try {
        action()
        false
    } catch (_: Exception) {
        true
    }
}

private func exceptionMessage(action: () -> Unit): String {
    try {
        action()
        ""
    } catch (e: Exception) {
        e.message
    }
}

private func containsString(values: Array<String>, target: String): Bool {
    for (value in values) {
        if (value == target) {
            return true
        }
    }
    false
}

private func containsCounter(values: Array<CounterSession>, count: Int64): Bool {
    for (value in values) {
        if (value.count == count) {
            return true
        }
    }
    false
}

private func containsStringEntry(entries: Array<StorageEntry<String>>, key: String, value: String): Bool {
    for (entry in entries) {
        if (entry.key == key && entry.value == value) {
            return true
        }
    }
    false
}

private func containsCounterEntry(entries: Array<StorageEntry<CounterSession>>, key: String, count: Int64): Bool {
    for (entry in entries) {
        if (entry.key == key && entry.value.count == count) {
            return true
        }
    }
    false
}

@Test
public class MemorySessionStorageTest {
    @TestCase
    public func memoryStorageReadsWritesDeletesAndLists(): Unit {
        let storage = MemorySessionStorage<String>()

        storage.write("a", "one")
        storage.write("b", "two")
        storage.delete("b")

        @Expect(stringValue(storage.read("a")), "one")
        @Expect(stringValue(storage.read("b")), "")
        @Expect(storage.has("a"), true)
        @Expect(storage.has("b"), false)
        @Expect(storage.readAllKeys().size, 1)
        @Expect(storage.readAllValues().size, 1)
        @Expect(storage.readAllEntries().size, 1)
        @Expect(storage.readAllEntries()[0].key, "a")
        @Expect(storage.readAllEntries()[0].value, "one")
        @Expect(storage.readAll().size, 1)
    }

    @TestCase
    public func memoryStorageExpiresWithFakeClock(): Unit {
        let clock = TestClock(1000)
        let storage = MemorySessionStorage<String>(50, { => clock.nowMillis })

        storage.write("ttl", "alive")
        clock.nowMillis = 1049
        @Expect(stringValue(storage.read("ttl")), "alive")
        clock.nowMillis = 1051
        @Expect(stringValue(storage.read("ttl")), "")
        @Expect(storage.has("ttl"), false)
        @Expect(storage.size(), 0)
    }

    @TestCase
    public func memoryStorageHasAndReadAllKeysKeepExpiredUntilRead(): Unit {
        let clock = TestClock(1000)
        let storage = MemorySessionStorage<String>(10, { => clock.nowMillis })

        storage.write("expired", "value")
        clock.nowMillis = 1011

        @Expect(storage.has("expired"), true)
        @Expect(storage.readAllKeys().size, 1)
        @Expect(stringValue(storage.read("expired")), "")
        @Expect(storage.has("expired"), false)
        @Expect(storage.readAllKeys().size, 0)
    }

    @TestCase
    public func memoryStorageEnumeratesAllLiveData(): Unit {
        let storage = MemorySessionStorage<String>()

        storage.write("k0", "v0")
        storage.write("k1", "v1")
        storage.write("k2", "v2")
        storage.delete("k1")

        @Expect(storage.readAll().size, 2)
        @Expect(storage.readAllKeys().size, 2)
        @Expect(storage.readAllValues().size, 2)
        @Expect(storage.readAllEntries().size, 2)
        @Expect(containsString(storage.readAllKeys(), "k0"), true)
        @Expect(containsString(storage.readAllKeys(), "k2"), true)
        @Expect(containsString(storage.readAllValues(), "v0"), true)
        @Expect(containsString(storage.readAllValues(), "v2"), true)
        @Expect(containsStringEntry(storage.readAllEntries(), "k0", "v0"), true)
        @Expect(containsStringEntry(storage.readAllEntries(), "k2", "v2"), true)
    }

    @TestCase
    public func memoryStorageReadAllFiltersExpiredValues(): Unit {
        let clock = TestClock(200)
        let storage = MemorySessionStorage<String>(10, { => clock.nowMillis })

        storage.write("old", "value")
        clock.nowMillis = 211

        @Expect(storage.readAll().size, 0)
        @Expect(storage.readAllKeys().size, 0)
        @Expect(storage.readAllValues().size, 0)
        @Expect(storage.readAllEntries().size, 0)
    }
}

@Test
public class SessionMiddlewareTest {
    @TestCase
    public func defaultKeyUsesChatIdAndSkipsNoChatUpdates(): Unit {
        let contract = sessionPropertyContract()
        @Expect(contract.upstreamProperty, "ctx.session")
        @Expect(contract.strictRead, "SessionFlavorContext<T>.session")
        @Expect(contract.strictWrite, "SessionFlavorContext<T>.session = value")
        @Expect(contract.strictDelete, "SessionFlavorContext<T>.deleteSession() or setOptionalSession(None)")
        @Expect(contract.lazyRead, "LazySessionMiddleware + SessionFlavorContext<T>.session")
        @Expect(contract.multiDelete, "MultiSessionFlavorContext<T>.session named slots or deleteSession()")
        @Expect(contract.contextIntegration, "typed session flavor context exposes ctx.session property")
        @Expect(stringValue(defaultGetSessionKey(testCtx(7))), "7")
        @Expect(stringValue(defaultGetSessionKey(noChatCtx(8))), "")
    }

    @TestCase
    public func sessionFlavorContextExposesDirectSessionProperty(): Unit {
        let storage = MemorySessionStorage<CounterSession>()
        let middleware = session<CounterSession>(SessionOptions<CounterSession>({ => CounterSession(1) }, storage))

        middleware.handle(testCtx(70), { ctx: SessionFlavorContext<CounterSession> =>
            @Expect(intValue(ctx.chatId), 70)
            @Expect(ctx.updateId(), 70)
            ctx.session.count += 1
        })

        @Expect(counterValue(storage.read("70")), 2)
    }

    @TestCase
    public func sessionOptionalNoneDeletesStorageLikeNullAssignment(): Unit {
        let storage = MemorySessionStorage<CounterSession>()
        storage.write("71", CounterSession(8))
        let middleware = session<CounterSession>(SessionOptions<CounterSession>(storage))

        middleware.handle(testCtx(71), { ctx: SessionFlavorContext<CounterSession> =>
            @Expect(ctx.session.count, 8)
            ctx.setOptionalSession(None<CounterSession>)
        })

        @Expect(storage.has("71"), false)
    }

    @TestCase
    public func sessionInitializesWritesBackAndDeletes(): Unit {
        let storage = MemorySessionStorage<CounterSession>()
        let options = SessionOptions<CounterSession>({ => CounterSession(1) }, storage)
        let middleware = session<CounterSession>(options)

        middleware.handle(testCtx(7), { ctx: SessionContext<CounterSession> =>
            let current = ctx.session
            current.count += 1
        })

        @Expect(counterValue(storage.read("7")), 2)

        middleware.handle(testCtx(7), { ctx: SessionContext<CounterSession> =>
            @Expect(ctx.session.count, 2)
            ctx.deleteSession()
        })

        @Expect(storage.has("7"), false)
    }

    @TestCase
    public func sessionDoesPrimitiveIoAndDeletes(): Unit {
        let storage = CountingStorage<Int64>()
        storage.write("8", 0)
        storage.readCount = 0
        storage.writeCount = 0
        storage.deleteCount = 0
        let middleware = session<Int64>(SessionOptions<Int64>(storage))

        middleware.handle(testCtx(8), { ctx: SessionContext<Int64> =>
            if (ctx.session == 0) {
                ctx.session = 1
            } else {
                ctx.deleteSession()
            }
        })
        middleware.handle(testCtx(8), { ctx: SessionContext<Int64> =>
            if (ctx.session == 0) {
                ctx.session = 1
            } else {
                ctx.deleteSession()
            }
        })

        @Expect(storage.readCount, 2)
        @Expect(storage.writeCount, 1)
        @Expect(storage.deleteCount, 1)
        @Expect(intValue(storage.inner.read("8")), -1)
    }

    @TestCase
    public func sessionAcceptsTaskBackedAsyncStorage(): Unit {
        let storage = AsyncCountingStorage<Int64>()
        storage.inner.write("9", 0)
        storage.inner.readCount = 0
        storage.inner.writeCount = 0
        storage.inner.deleteCount = 0

        session<Int64>(SessionOptions<Int64>(storage)).handle(testCtx(9), { ctx: SessionContext<Int64> =>
            ctx.session = ctx.session + 1
        })

        @Expect(storage.inner.readCount, 1)
        @Expect(storage.inner.writeCount, 1)
        @Expect(storage.inner.deleteCount, 0)
        @Expect(intValue(storage.inner.inner.read("9")), 1)
    }

    @TestCase
    public func sessionAcceptsTaskBackedReadWriteDeleteOnlyStorage(): Unit {
        let storage = AsyncMinimalStorage<Int64>()
        storage.inner.inner.write("89", 4)

        session<Int64>(SessionOptions<Int64>(storage)).handle(testCtx(89), { ctx: SessionContext<Int64> =>
            ctx.session = ctx.session + 6
        })

        @Expect(storage.inner.readCount, 1)
        @Expect(storage.inner.writeCount, 1)
        @Expect(storage.inner.deleteCount, 0)
        @Expect(intValue(storage.inner.inner.read("89")), 10)
    }

    @TestCase
    public func sessionDoesNotReadOrWriteWhenHandlerDoesNotAccessSession(): Unit {
        let storage = CountingStorage<CounterSession>()
        let options = SessionOptions<CounterSession>({ => CounterSession(4) }, storage)

        session<CounterSession>(options).handle(testCtx(17), { _ctx: SessionContext<CounterSession> => () })

        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
        @Expect(counterValue(storage.inner.read("17")), -1)
    }

    @TestCase
    public func sessionAcceptsReadWriteDeleteOnlyStorage(): Unit {
        let storage = MinimalStorage<CounterSession>()
        storage.inner.write("90", CounterSession(2))
        let options = SessionOptions<CounterSession>(storage)

        session<CounterSession>(options).handle(testCtx(90), { ctx: SessionContext<CounterSession> =>
            ctx.session.count += 3
        })

        @Expect(storage.readCount, 1)
        @Expect(storage.writeCount, 1)
        @Expect(storage.deleteCount, 0)
        @Expect(counterValue(storage.inner.read("90")), 5)
    }

    @TestCase
    public func sessionThrowsWhenAccessingEmptySessionKey(): Unit {
        let storage = CountingStorage<CounterSession>()
        let options = SessionOptions<CounterSession>(
            "",
            Some({ => CounterSession(0) }),
            storage,
            { _ctx: Context => None<String> },
        )

        let threw = throwsException({ =>
            session<CounterSession>(options).handle(testCtx(18), { ctx: SessionContext<CounterSession> =>
                ctx.session.count += 1
            })
        })

        @Expect(threw, true)
        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
    }

    @TestCase
    public func sessionReportsUpstreamUndefinedKeyReasons(): Unit {
        let defaultMessage = exceptionMessage({ =>
            session<CounterSession>(SessionOptions<CounterSession>({ => CounterSession(0) })).handle(
                noChatCtx(81),
                { ctx: SessionContext<CounterSession> => ctx.session.count += 1 },
            )
        })
        let customOptions = SessionOptions<CounterSession>(
            "",
            Some({ => CounterSession(0) }),
            CountingStorage<CounterSession>(),
            { _ctx: Context => None<String> },
        )
        let customMessage = exceptionMessage({ =>
            session<CounterSession>(customOptions).handle(
                testCtx(82),
                { ctx: SessionContext<CounterSession> => ctx.session = CounterSession(1) },
            )
        })

        @Expect(defaultMessage, "Cannot access session data because this update does not belong to a chat, so the session key is undefined!")
        @Expect(customMessage, "Cannot assign session data because the custom `getSessionKey` function returned undefined for this update!")
    }

    @TestCase
    public func sessionPropagatesStorageReadErrorsAndDoesNotWriteBack(): Unit {
        let storage = ThrowingReadStorage<CounterSession>()
        let message = exceptionMessage({ =>
            session<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
                testCtx(83),
                { ctx: SessionContext<CounterSession> => ctx.maybeSession() },
            )
        })

        @Expect(message, "read failed:83")
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
    }

    @TestCase
    public func sessionThrowsWhenWritingEmptySessionKey(): Unit {
        let storage = CountingStorage<CounterSession>()
        let options = SessionOptions<CounterSession>(
            "",
            Some({ => CounterSession(0) }),
            storage,
            { _ctx: Context => None<String> },
        )

        let threw = throwsException({ =>
            session<CounterSession>(options).handle(testCtx(19), { ctx: SessionContext<CounterSession> =>
                ctx.session = CounterSession(1)
            })
        })

        @Expect(threw, true)
        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
    }

    @TestCase
    public func sessionPassesThroughEmptyKeyWhenUnused(): Unit {
        let storage = CountingStorage<CounterSession>()
        let options = SessionOptions<CounterSession>(
            "",
            Some({ => CounterSession(0) }),
            storage,
            { _ctx: Context => None<String> },
        )
        let events = ArrayList<String>()

        session<CounterSession>(options).handle(testCtx(20), { _ctx: SessionContext<CounterSession> =>
            events.add("ran")
        })

        @Expect(events.size, 1)
        @Expect(events[0], "ran")
        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
    }

    @TestCase
    public func sessionSkipsWriteWhenHandlerThrows(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("21", CounterSession(5))
        storage.readCount = 0
        storage.writeCount = 0
        storage.deleteCount = 0

        let threw = throwsException({ =>
            session<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
                testCtx(21),
                { ctx: SessionContext<CounterSession> =>
                    @Expect(ctx.session.count, 5)
                    ctx.session = CounterSession(6)
                    throw Exception("err")
                },
            )
        })

        @Expect(threw, true)
        @Expect(storage.readCount, 1)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
        @Expect(counterValue(storage.inner.read("21")), 5)
    }

    @TestCase
    public func customPrefixAndKeyWrapDefaultStorageKey(): Unit {
        let storage = MemorySessionStorage<CounterSession>()
        let options = SessionOptions<CounterSession>(
            "session:",
            Some({ => CounterSession(3) }),
            storage,
            { _ctx: Context => Some("chat-1") },
        )

        session<CounterSession>(options).handle(testCtx(10), { ctx: SessionContext<CounterSession> =>
            ctx.session.count += 4
        })

        @Expect(counterValue(storage.read("session:chat-1")), 7)
    }

    @TestCase
    public func middlewareAdapterRunsHandlerAndNextInsideSessionLifecycle(): Unit {
        let events = ArrayList<String>()
        let storage = MemorySessionStorage<CounterSession>()
        let options = SessionOptions<CounterSession>({ => CounterSession(0) }, storage)
        let middleware = session<CounterSession>(options).middleware(
            { ctx: SessionContext<CounterSession>, next: () -> Unit =>
                events.add("handler")
                ctx.session.count = 9
                next()
            },
        )

        middleware(testCtx(44), { =>
            events.add("next")
        })

        @Expect(events.size, 2)
        @Expect(events[0], "handler")
        @Expect(events[1], "next")
        @Expect(counterValue(storage.read("44")), 9)
    }

    @TestCase
    public func middlewareAdapterSupportsFlavorContextAcrossNext(): Unit {
        let events = ArrayList<String>()
        let storage = MemorySessionStorage<CounterSession>()
        let middleware = session<CounterSession>(SessionOptions<CounterSession>({ => CounterSession(0) }, storage)).middleware(
            { ctx: SessionFlavorContext<CounterSession>, next: () -> Unit =>
                events.add("handler:" + ctx.session.count.toString())
                ctx.session.count = 13
                next()
                ctx.session.count += 1
            },
        )

        middleware(testCtx(72), { =>
            events.add("next")
        })

        @Expect(events.size, 2)
        @Expect(events[0], "handler:0")
        @Expect(events[1], "next")
        @Expect(counterValue(storage.read("72")), 14)
    }
}

@Test
public class MultiSessionMiddlewareTest {
    @TestCase
    public func arbitraryMultiSessionSupportsOneKey(): Unit {
        let storage = CountingStorage<CounterSession>()
        let options = MultiSessionOptions<CounterSession>()
        options.add("profile", SessionOptions<CounterSession>({ => CounterSession(1) }, storage))

        multiSession<CounterSession>(options).handle(testCtx(91), { ctx: MultiSessionContext<CounterSession> =>
            @Expect(ctx.size(), 1)
            ctx.session("profile").count += 4
        })

        @Expect(storage.readCount, 1)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.inner.read("91")), 5)
    }

    @TestCase
    public func arbitraryMultiSessionSupportsTwoAndThreeNamedKeysIndependently(): Unit {
        let first = CountingStorage<CounterSession>()
        let second = CountingStorage<CounterSession>()
        let third = CountingStorage<CounterSession>()
        let options = MultiSessionOptions<CounterSession>()
        options.add("one", SessionOptions<CounterSession>({ => CounterSession(1) }, first))
        options.add("two", SessionOptions<CounterSession>({ => CounterSession(2) }, second))
        options.add("three", SessionOptions<CounterSession>({ => CounterSession(3) }, third))

        multiSession<CounterSession>(options).handle(testCtx(92), { ctx: MultiSessionFlavorContext<CounterSession> =>
            @Expect(ctx.chatId, 92)
            ctx.session.get("one").count += 10
            ctx.session.set("two", CounterSession(20))
            ctx.session.delete("three")
        })

        @Expect(first.readCount, 1)
        @Expect(second.readCount, 0)
        @Expect(third.readCount, 0)
        @Expect(first.writeCount, 1)
        @Expect(second.writeCount, 1)
        @Expect(third.deleteCount, 1)
        @Expect(counterValue(first.inner.read("92")), 11)
        @Expect(counterValue(second.inner.read("92")), 20)
        @Expect(third.inner.has("92"), false)
    }

    @TestCase
    public func arbitraryMultiSessionSupportsNKeysAndDeleteAll(): Unit {
        let a = CountingStorage<CounterSession>()
        let b = CountingStorage<CounterSession>()
        let c = CountingStorage<CounterSession>()
        let d = CountingStorage<CounterSession>()
        a.write("93", CounterSession(1))
        b.write("93", CounterSession(2))
        c.write("93", CounterSession(3))
        d.write("93", CounterSession(4))
        a.readCount = 0
        b.readCount = 0
        c.readCount = 0
        d.readCount = 0
        let options = MultiSessionOptions<CounterSession>()
        options.add("alpha", SessionOptions<CounterSession>(a))
        options.add("beta", SessionOptions<CounterSession>(b))
        options.add("gamma", SessionOptions<CounterSession>(c))
        options.add("delta", SessionOptions<CounterSession>(d))

        multiSession<CounterSession>(options).handle(testCtx(93), { ctx: MultiSessionContext<CounterSession> =>
            @Expect(ctx.size(), 4)
            @Expect(ctx.session("alpha").count, 1)
            @Expect(ctx.session("delta").count, 4)
            ctx.deleteSession()
        })

        @Expect(a.readCount, 1)
        @Expect(b.readCount, 0)
        @Expect(c.readCount, 0)
        @Expect(d.readCount, 1)
        @Expect(a.deleteCount, 1)
        @Expect(b.deleteCount, 1)
        @Expect(c.deleteCount, 1)
        @Expect(d.deleteCount, 1)
        @Expect(a.inner.has("93"), false)
        @Expect(b.inner.has("93"), false)
        @Expect(c.inner.has("93"), false)
        @Expect(d.inner.has("93"), false)
    }

    @TestCase
    public func arbitraryMultiSessionRejectsDuplicateAndUnknownKeys(): Unit {
        let options = MultiSessionOptions<CounterSession>()
        options.add("same", SessionOptions<CounterSession>())
        let duplicate = throwsException({ =>
            options.add("same", SessionOptions<CounterSession>())
        })
        let unknown = throwsException({ =>
            multiSession<CounterSession>(options).handle(testCtx(94), { ctx: MultiSessionContext<CounterSession> =>
                ctx.session("missing").count += 1
            })
        })

        @Expect(duplicate, true)
        @Expect(unknown, true)
    }

    @TestCase
    public func multiSessionReadsWritesAndDeletesBothSlots(): Unit {
        let first = MemorySessionStorage<CounterSession>()
        let second = MemorySessionStorage<CounterSession>()
        let middleware = session<CounterSession, CounterSession>(
            MultiSessionOptions2<CounterSession, CounterSession>(
                SessionOptions<CounterSession>({ => CounterSession(0) }, first),
                SessionOptions<CounterSession>({ => CounterSession(10) }, second),
            ),
        )

        middleware.handle(testCtx(31), { ctx: MultiSessionContext2<CounterSession, CounterSession> =>
            ctx.first.session.count += 1
            ctx.second.session.count += 2
        })

        @Expect(counterValue(first.read("31")), 1)
        @Expect(counterValue(second.read("31")), 12)

        middleware.handle(testCtx(31), { ctx: MultiSessionContext2<CounterSession, CounterSession> =>
            @Expect(ctx.first.session.count, 1)
            @Expect(ctx.second.session.count, 12)
            ctx.deleteSession()
        })

        @Expect(first.has("31"), false)
        @Expect(second.has("31"), false)
    }

    @TestCase
    public func multiSessionDeletingOneSlotDoesNotAffectTheOther(): Unit {
        let first = MemorySessionStorage<CounterSession>()
        let second = MemorySessionStorage<CounterSession>()
        first.write("35", CounterSession(1))
        second.write("35", CounterSession(2))
        let middleware = multiSession<CounterSession, CounterSession>(
            MultiSessionOptions2<CounterSession, CounterSession>(
                SessionOptions<CounterSession>(first),
                SessionOptions<CounterSession>(second),
            ),
        )

        middleware.handle(testCtx(35), { ctx: MultiSessionContext2<CounterSession, CounterSession> =>
            ctx.first.deleteSession()
            ctx.second.session.count += 10
        })

        @Expect(first.has("35"), false)
        @Expect(counterValue(second.read("35")), 12)
    }

    @TestCase
    public func multiSessionFlavorContextExposesSessionSlots(): Unit {
        let first = MemorySessionStorage<CounterSession>()
        let second = MemorySessionStorage<CounterSession>()
        let middleware = multiSession<CounterSession, CounterSession>(
            MultiSessionOptions2<CounterSession, CounterSession>(
                SessionOptions<CounterSession>({ => CounterSession(2) }, first),
                SessionOptions<CounterSession>({ => CounterSession(4) }, second),
            ),
        )

        middleware.handle(testCtx(36), { ctx: MultiSessionFlavorContext2<CounterSession, CounterSession> =>
            @Expect(intValue(ctx.chatId), 36)
            ctx.session.first.count += 3
            ctx.session.second = CounterSession(11)
        })

        @Expect(counterValue(first.read("36")), 5)
        @Expect(counterValue(second.read("36")), 11)
    }

    @TestCase
    public func multiSessionFlavorOptionalNoneDeletesSlotsLikeNullAssignments(): Unit {
        let first = MemorySessionStorage<CounterSession>()
        let second = MemorySessionStorage<CounterSession>()
        first.write("37", CounterSession(1))
        second.write("37", CounterSession(2))
        let middleware = multiSession<CounterSession, CounterSession>(
            MultiSessionOptions2<CounterSession, CounterSession>(
                SessionOptions<CounterSession>(first),
                SessionOptions<CounterSession>(second),
            ),
        )

        middleware.handle(testCtx(37), { ctx: MultiSessionFlavorContext2<CounterSession, CounterSession> =>
            ctx.session.setOptionalFirst(None<CounterSession>)
            ctx.session.second.count += 8
        })

        @Expect(first.has("37"), false)
        @Expect(counterValue(second.read("37")), 10)

        middleware.handle(testCtx(37), { ctx: MultiSessionFlavorContext2<CounterSession, CounterSession> =>
            ctx.setOptionalSession(None<MultiSessionData2<CounterSession, CounterSession>>)
        })

        @Expect(first.has("37"), false)
        @Expect(second.has("37"), false)
    }

    @TestCase
    public func multiSessionSkipsWriteWhenHandlerThrows(): Unit {
        let first = CountingStorage<CounterSession>()
        let second = CountingStorage<CounterSession>()
        first.write("32", CounterSession(1))
        second.write("32", CounterSession(2))
        first.readCount = 0
        first.writeCount = 0
        first.deleteCount = 0
        second.readCount = 0
        second.writeCount = 0
        second.deleteCount = 0

        let middleware = multiSession<CounterSession, CounterSession>(
            MultiSessionOptions2<CounterSession, CounterSession>(
                SessionOptions<CounterSession>(first),
                SessionOptions<CounterSession>(second),
            ),
        )

        let threw = throwsException({ =>
            middleware.handle(testCtx(32), { ctx: MultiSessionContext2<CounterSession, CounterSession> =>
                @Expect(ctx.first.session.count, 1)
                @Expect(ctx.second.session.count, 2)
                ctx.first.session = CounterSession(11)
                ctx.second.session = CounterSession(12)
                throw Exception("err")
            })
        })

        @Expect(threw, true)
        @Expect(first.readCount, 1)
        @Expect(second.readCount, 1)
        @Expect(first.writeCount, 0)
        @Expect(second.writeCount, 0)
        @Expect(first.deleteCount, 0)
        @Expect(second.deleteCount, 0)
        @Expect(counterValue(first.inner.read("32")), 1)
        @Expect(counterValue(second.inner.read("32")), 2)
    }

    @TestCase
    public func multiSessionThrowsWhenReadingEmptySlotKey(): Unit {
        let first = CountingStorage<CounterSession>()
        let second = CountingStorage<CounterSession>()
        let middleware = multiSession<CounterSession, CounterSession>(
            MultiSessionOptions2<CounterSession, CounterSession>(
                SessionOptions<CounterSession>(
                    "",
                    Some({ => CounterSession(0) }),
                    first,
                    { _ctx: Context => None<String> },
                ),
                SessionOptions<CounterSession>({ => CounterSession(0) }, second),
            ),
        )

        let threw = throwsException({ =>
            middleware.handle(testCtx(33), { ctx: MultiSessionContext2<CounterSession, CounterSession> =>
                ctx.first.session.count += 1
            })
        })

        @Expect(threw, true)
        @Expect(first.readCount, 0)
        @Expect(first.writeCount, 0)
        @Expect(second.writeCount, 0)
    }

    @TestCase
    public func multiSessionThrowsWhenWritingEmptySlotKey(): Unit {
        let first = CountingStorage<CounterSession>()
        let second = CountingStorage<CounterSession>()
        let middleware = multiSession<CounterSession, CounterSession>(
            MultiSessionOptions2<CounterSession, CounterSession>(
                SessionOptions<CounterSession>(
                    "",
                    Some({ => CounterSession(0) }),
                    first,
                    { _ctx: Context => None<String> },
                ),
                SessionOptions<CounterSession>({ => CounterSession(0) }, second),
            ),
        )

        let threw = throwsException({ =>
            middleware.handle(testCtx(34), { ctx: MultiSessionContext2<CounterSession, CounterSession> =>
                ctx.first.session = CounterSession(3)
            })
        })

        @Expect(threw, true)
        @Expect(first.readCount, 0)
        @Expect(first.writeCount, 0)
        @Expect(second.writeCount, 0)
    }
}

@Test
public class LazySessionMiddlewareTest {
    @TestCase
    public func lazySessionRejectsMultiSessionOptions(): Unit {
        let options = MultiSessionOptions2<CounterSession, CounterSession>(
            SessionOptions<CounterSession>({ => CounterSession(0) }),
            SessionOptions<CounterSession>({ => CounterSession(0) }),
        )

        let threw = throwsException({ =>
            let _middleware = lazySession<CounterSession, CounterSession>(options)
        })

        @Expect(threw, true)
    }

    @TestCase
    public func lazySessionRejectsArbitraryMultiSessionOptions(): Unit {
        let options = MultiSessionOptions<CounterSession>()
        options.add("one", SessionOptions<CounterSession>({ => CounterSession(0) }))

        let threw = throwsException({ =>
            let _middleware = lazySession<CounterSession>(options)
        })

        @Expect(threw, true)
    }

    @TestCase
    public func lazySessionSkipsStorageReadUntilAccess(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("5", CounterSession(10))
        storage.readCount = 0
        storage.writeCount = 0

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(5),
            { ctx: SessionContext<CounterSession> =>
                @Expect(ctx.isLoaded(), false)
                ctx.session = CounterSession(12)
            },
        )

        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.read("5")), 12)
    }

    @TestCase
    public func lazySessionReadsOnceOnAccessAndWritesBack(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("6", CounterSession(20))
        storage.readCount = 0
        storage.writeCount = 0

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(6),
            { ctx: SessionContext<CounterSession> =>
                @Expect(ctx.isLoaded(), false)
                ctx.session.count += 1
                @Expect(ctx.isLoaded(), true)
            },
        )

        @Expect(storage.readCount, 1)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.read("6")), 21)
    }

    @TestCase
    public func lazySessionDoesPrimitiveIoAndDeletes(): Unit {
        let storage = CountingStorage<Int64>()
        storage.write("40", 0)
        storage.readCount = 0
        storage.writeCount = 0
        storage.deleteCount = 0
        let middleware = lazySession<Int64>(SessionOptions<Int64>(storage))

        middleware.handle(testCtx(40), { ctx: SessionContext<Int64> =>
            if (ctx.session == 0) {
                ctx.session = 1
            } else {
                ctx.deleteSession()
            }
        })
        middleware.handle(testCtx(40), { ctx: SessionContext<Int64> =>
            if (ctx.session == 0) {
                ctx.session = 1
            } else {
                ctx.deleteSession()
            }
        })

        @Expect(storage.readCount, 2)
        @Expect(storage.writeCount, 1)
        @Expect(storage.deleteCount, 1)
        @Expect(intValue(storage.inner.read("40")), -1)
    }

    @TestCase
    public func lazySessionThrowsWhenAccessingEmptySessionKey(): Unit {
        let storage = CountingStorage<CounterSession>()
        let options = SessionOptions<CounterSession>(
            "",
            Some({ => CounterSession(0) }),
            storage,
            { _ctx: Context => None<String> },
        )

        let threw = throwsException({ =>
            lazySession<CounterSession>(options).handle(testCtx(41), { ctx: SessionContext<CounterSession> =>
                ctx.session.count += 1
            })
        })

        @Expect(threw, true)
        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 0)
    }

    @TestCase
    public func lazySessionReportsLazyUndefinedKeyReason(): Unit {
        let message = exceptionMessage({ =>
            lazySession<CounterSession>(SessionOptions<CounterSession>({ => CounterSession(0) })).handle(
                noChatCtx(84),
                { ctx: SessionContext<CounterSession> => ctx.session.count += 1 },
            )
        })

        @Expect(message, "Cannot access lazy session data because this update does not belong to a chat, so the session key is undefined!")
    }

    @TestCase
    public func lazySessionThrowsWhenAssigningEmptySessionKey(): Unit {
        let storage = CountingStorage<CounterSession>()
        let options = SessionOptions<CounterSession>(
            "",
            Some({ => CounterSession(0) }),
            storage,
            { _ctx: Context => None<String> },
        )

        let message = exceptionMessage({ =>
            lazySession<CounterSession>(options).handle(testCtx(85), { ctx: SessionContext<CounterSession> =>
                ctx.session = CounterSession(1)
            })
        })

        @Expect(message, "Cannot assign lazy session data because the custom `getSessionKey` function returned undefined for this update!")
        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
    }

    @TestCase
    public func lazySessionSkipsWriteWhenHandlerThrows(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("42", CounterSession(2))
        storage.readCount = 0
        storage.writeCount = 0
        storage.deleteCount = 0

        let threw = throwsException({ =>
            lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
                testCtx(42),
                { ctx: SessionContext<CounterSession> =>
                    @Expect(ctx.session.count, 2)
                    ctx.session = CounterSession(3)
                    throw Exception("err")
                },
            )
        })

        @Expect(threw, true)
        @Expect(storage.readCount, 1)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
        @Expect(counterValue(storage.inner.read("42")), 2)
    }

    @TestCase
    public func lazySessionDoesNotWriteIfNothingWasRead(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("43", CounterSession(3))
        storage.readCount = 0
        storage.writeCount = 0
        storage.deleteCount = 0

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(43),
            { ctx: SessionContext<CounterSession> =>
                @Expect(ctx.isLoaded(), false)
            },
        )

        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 0)
    }

    @TestCase
    public func lazySessionManualWriteWinsBeforeRead(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("44", CounterSession(3))
        storage.readCount = 0
        storage.writeCount = 0

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(44),
            { ctx: SessionContext<CounterSession> =>
                ctx.session = CounterSession(9)
                @Expect(ctx.session.count, 9)
            },
        )

        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.inner.read("44")), 9)
    }

    @TestCase
    public func lazySessionDiscardReadThatCompletesAfterManualWrite(): Unit {
        let storage = BlockingReadStorage<CounterSession>(Some(CounterSession(3)))

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(47),
            { ctx: SessionContext<CounterSession> =>
                let reader = spawn { =>
                    @Expect(ctx.session.count, 42)
                }
                storage.waitUntilEntered()
                @Expect(ctx.isFetching(), true)
                ctx.session = CounterSession(42)
                storage.release()
                reader.get()
            },
        )

        @Expect(storage.readCount, 1)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.written), 42)
    }

    @TestCase
    public func lazySessionWriteThenReadNeverTouchesStorageRead(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("46", CounterSession(3))
        storage.readCount = 0
        storage.writeCount = 0

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(46),
            { ctx: SessionContext<CounterSession> =>
                ctx.session = CounterSession(11)
                @Expect(ctx.session.count, 11)
                @Expect(ctx.wasRead(), true)
            },
        )

        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.inner.read("46")), 11)
    }

    @TestCase
    public func lazySessionReadsOnceAndCachesValue(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("45", CounterSession(4))
        storage.readCount = 0
        storage.writeCount = 0

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(45),
            { ctx: SessionContext<CounterSession> =>
                @Expect(ctx.session.count, 4)
                @Expect(ctx.session.count, 4)
                ctx.session.count += 1
            },
        )

        @Expect(storage.readCount, 1)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.inner.read("45")), 5)
    }

    @TestCase
    public func lazySessionFlavorContextWritesResolvedTask(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.readCount = 0
        storage.writeCount = 0

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(48),
            { ctx: SessionFlavorContext<CounterSession> =>
                ctx.setSessionTask(SessionTask<CounterSession>({ => CounterSession(15) }))
            },
        )

        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.inner.read("48")), 15)
    }

    @TestCase
    public func lazySessionOptionalTaskNoneDeletesStorage(): Unit {
        let storage = CountingStorage<CounterSession>()
        storage.write("49", CounterSession(5))
        storage.readCount = 0
        storage.writeCount = 0
        storage.deleteCount = 0

        lazySession<CounterSession>(SessionOptions<CounterSession>(storage)).handle(
            testCtx(49),
            { ctx: SessionFlavorContext<CounterSession> =>
                ctx.setOptionalSessionTask(SessionTask<Option<CounterSession>>({ => None<CounterSession> }))
            },
        )

        @Expect(storage.readCount, 0)
        @Expect(storage.writeCount, 0)
        @Expect(storage.deleteCount, 1)
        @Expect(storage.inner.has("49"), false)
    }
}

@Test
public class EnhancedStorageTest {
    @TestCase
    public func migrationsRunInAscendingVersionOrder(): Unit {
        let backing = MemorySessionStorage<SessionEnvelope<CounterSession>>()
        let order = ArrayList<String>()
        let migrations = HashMap<Int64, (CounterSession) -> CounterSession>()
        migrations[2] = { old: CounterSession =>
            order.add("two")
            CounterSession(old.count * 2)
        }
        migrations[1] = { old: CounterSession =>
            order.add("one")
            CounterSession(old.count + 10)
        }
        backing.write("k", SessionEnvelope<CounterSession>(CounterSession(1), 0))

        let enhanced = enhanceStorage<CounterSession>(MigrationOptions<CounterSession>(backing, migrations))

        @Expect(backing.has("k"), true)
        @Expect(counterValue(enhanced.read("k")), 22)
        @Expect(order.size, 2)
        @Expect(order[0], "one")
        @Expect(order[1], "two")
    }

    @TestCase
    public func timeoutAndMigrationWrappersComposeWithoutMigratingExpiredValues(): Unit {
        let clock = TestClock(100)
        let backing = MemorySessionStorage<SessionEnvelope<CounterSession>>()
        let order = ArrayList<String>()
        let migrations = HashMap<Int64, (CounterSession) -> CounterSession>()
        migrations[1] = { old: CounterSession =>
            order.add("migrate")
            CounterSession(old.count + 1)
        }
        let expired = SessionEnvelope<CounterSession>(CounterSession(1), 0)
        expired.setExpiry(90)
        backing.write("expired", expired)

        let enhanced = enhanceStorage<CounterSession>(
            MigrationOptions<CounterSession>(backing, migrations, 50, { => clock.nowMillis }),
        )

        @Expect(counterValue(enhanced.read("expired")), -1)
        @Expect(order.size, 0)
        @Expect(backing.has("expired"), false)

        enhanced.write("fresh", CounterSession(3))
        let raw = backing.read("fresh")
        @Expect(envelopeCounter(raw).count, 3)
        @Expect(envelopeVersion(raw), 1)
        @Expect(envelopeHasExpiry(raw), true)
        @Expect(envelopeExpiry(raw), 150)
    }

    @TestCase
    public func enhancedStorageRefreshesExpiryOnEnvelopeWithoutExpiry(): Unit {
        let clock = TestClock(200)
        let backing = MemorySessionStorage<SessionEnvelope<CounterSession>>()
        backing.write("legacy", SessionEnvelope<CounterSession>(CounterSession(4)))

        let enhanced = enhanceStorage<CounterSession>(
            MigrationOptions<CounterSession>(backing, 50, { => clock.nowMillis }),
        )

        @Expect(counterValue(enhanced.read("legacy")), 4)
        let raw = backing.read("legacy")
        @Expect(envelopeHasExpiry(raw), true)
        @Expect(envelopeExpiry(raw), 250)
    }

    @TestCase
    public func enhancedStorageReadsWritesDeletesEnvelopeData(): Unit {
        let backing = MemorySessionStorage<SessionEnvelope<CounterSession>>()
        let enhanced = enhanceStorage<CounterSession>(MigrationOptions<CounterSession>(backing))

        enhanced.write("plain", CounterSession(42))

        @Expect(counterValue(enhanced.read("plain")), 42)
        @Expect(envelopeCounter(backing.read("plain")).count, 42)

        enhanced.delete("plain")

        @Expect(backing.has("plain"), false)
    }

    @TestCase
    public func emptyMigrationsThrow(): Unit {
        let backing = MemorySessionStorage<SessionEnvelope<CounterSession>>()
        let migrations = HashMap<Int64, (CounterSession) -> CounterSession>()

        let threw = throwsException({ =>
            let _enhanced = enhanceStorage<CounterSession>(MigrationOptions<CounterSession>(backing, migrations))
        })

        @Expect(threw, true)
    }

    @TestCase
    public func migrationsHandleMiddleMissingAndCurrentVersions(): Unit {
        let backing = MemorySessionStorage<SessionEnvelope<CounterSession>>()
        let migrations = HashMap<Int64, (CounterSession) -> CounterSession>()
        migrations[1] = { old: CounterSession => CounterSession(old.count + 10) }
        migrations[3] = { old: CounterSession => CounterSession(old.count * 2) }
        migrations[12] = { old: CounterSession => CounterSession(old.count * old.count) }

        backing.write("start", SessionEnvelope<CounterSession>(CounterSession(0)))
        backing.write("middle", SessionEnvelope<CounterSession>(CounterSession(5), 3))
        backing.write("missing", SessionEnvelope<CounterSession>(CounterSession(5), 8))
        backing.write("current", SessionEnvelope<CounterSession>(CounterSession(42), 12))

        let enhanced = enhanceStorage<CounterSession>(MigrationOptions<CounterSession>(backing, migrations))

        @Expect(counterValue(enhanced.read("start")), 400)
        @Expect(counterValue(enhanced.read("middle")), 25)
        @Expect(counterValue(enhanced.read("missing")), 25)
        @Expect(counterValue(enhanced.read("current")), 42)
    }

    @TestCase
    public func migrationsDoNotRunForMissingValues(): Unit {
        let backing = MemorySessionStorage<SessionEnvelope<CounterSession>>()
        let migrations = HashMap<Int64, (CounterSession) -> CounterSession>()
        let order = ArrayList<String>()
        migrations[1] = { old: CounterSession =>
            order.add("migrate")
            CounterSession(old.count + 1)
        }

        let enhanced = enhanceStorage<CounterSession>(MigrationOptions<CounterSession>(backing, migrations))

        @Expect(counterValue(enhanced.read("missing")), -1)
        @Expect(order.size, 0)
    }

    @TestCase
    public func enhancedStorageEnumeratesLiveValuesAndEntries(): Unit {
        let clock = TestClock(1000)
        let backing = MemorySessionStorage<SessionEnvelope<CounterSession>>()
        let enhanced = enhanceStorage<CounterSession>(
            MigrationOptions<CounterSession>(backing, 20, { => clock.nowMillis }),
        )

        enhanced.write("a", CounterSession(1))
        enhanced.write("b", CounterSession(2))

        @Expect(enhanced.readAll().size, 2)
        @Expect(enhanced.readAllKeys().size, 2)
        @Expect(containsString(enhanced.readAllKeys(), "a"), true)
        @Expect(containsString(enhanced.readAllKeys(), "b"), true)
        @Expect(containsCounter(enhanced.readAllValues(), 1), true)
        @Expect(containsCounter(enhanced.readAllValues(), 2), true)
        @Expect(containsCounterEntry(enhanced.readAllEntries(), "a", 1), true)
        @Expect(containsCounterEntry(enhanced.readAllEntries(), "b", 2), true)

        clock.nowMillis = 1021

        @Expect(enhanced.readAll().size, 0)
        @Expect(enhanced.readAllKeys().size, 0)
        @Expect(enhanced.readAllValues().size, 0)
        @Expect(enhanced.readAllEntries().size, 0)
    }
}
