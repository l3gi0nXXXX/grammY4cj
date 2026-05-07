package grammy4cj.convenience

import grammy4cj.context.Context
import grammy4cj.core.Api
import grammy4cj.types.{Update, UserFromGetMe}
import std.collection.{ArrayList, HashMap}
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

private class CountingStorage<T> <: StorageAdapter<T> {
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

private func testCtx(updateId: Int64): Context {
    Context(Update(updateId), Api("fake-token"), UserFromGetMe(42, true, "grammY4cj", "grammy4cj_bot"))
}

private func stringValue(value: Option<String>): String {
    match (value) {
        case Some(v) => v
        case None => ""
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
}

@Test
public class SessionMiddlewareTest {
    @TestCase
    public func defaultKeyUsesUpdateIdUntilChatContextLands(): Unit {
        @Expect(stringValue(defaultGetSessionKey(testCtx(7))), "7")
    }

    @TestCase
    public func sessionInitializesWritesBackAndDeletes(): Unit {
        let storage = MemorySessionStorage<CounterSession>()
        let options = SessionOptions<CounterSession>({ => CounterSession(1) }, storage)
        let middleware = session<CounterSession>(options)

        middleware.handle(testCtx(7), { ctx: SessionContext<CounterSession> =>
            let current = ctx.session()
            current.count += 1
        })

        @Expect(counterValue(storage.read("7")), 2)

        middleware.handle(testCtx(7), { ctx: SessionContext<CounterSession> =>
            @Expect(ctx.session().count, 2)
            ctx.deleteSession()
        })

        @Expect(storage.has("7"), false)
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
            ctx.session().count += 4
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
                ctx.session().count = 9
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
}

@Test
public class LazySessionMiddlewareTest {
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
                ctx.setSession(CounterSession(12))
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
                ctx.session().count += 1
                @Expect(ctx.isLoaded(), true)
            },
        )

        @Expect(storage.readCount, 1)
        @Expect(storage.writeCount, 1)
        @Expect(counterValue(storage.read("6")), 21)
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
}
