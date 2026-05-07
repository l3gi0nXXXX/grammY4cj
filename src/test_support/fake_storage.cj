package grammy4cj.test_support

import grammy4cj.convenience.{AsyncStorageAdapter, SessionTask, StorageAdapter, StorageEntry}
import std.collection.ArrayList

public class FakeStorage {
    public var hasValue: Bool = false
    public var key: String = ""
    public var value: String = ""

    public init() {}

    public func write(key: String, value: String): Unit {
        this.hasValue = true
        this.key = key
        this.value = value
    }

    public func read(key: String): String {
        if (this.hasValue && this.key == key) {
            return this.value
        }
        ""
    }
}

public class FakeSessionStorage <: StorageAdapter<String> {
    private let entries: ArrayList<StorageEntry<String>> = ArrayList<StorageEntry<String>>()
    public var readCount: Int64 = 0
    public var writeCount: Int64 = 0
    public var deleteCount: Int64 = 0

    public init() {}

    public func read(key: String): Option<String> {
        this.readCount += 1
        for (entry in this.entries) {
            if (entry.key == key) {
                return Some(entry.value)
            }
        }
        None<String>
    }

    public func write(key: String, value: String): Unit {
        this.writeCount += 1
        this.deleteExisting(key)
        this.entries.add(StorageEntry<String>(key, value))
    }

    public func delete(key: String): Unit {
        this.deleteCount += 1
        this.deleteExisting(key)
    }

    public func has(key: String): Bool {
        for (entry in this.entries) {
            if (entry.key == key) {
                return true
            }
        }
        false
    }

    public func readAll(): Array<String> {
        this.readAllValues()
    }

    public func readAllKeys(): Array<String> {
        let keys = ArrayList<String>()
        for (entry in this.entries) {
            keys.add(entry.key)
        }
        keys.toArray()
    }

    public func readAllValues(): Array<String> {
        let values = ArrayList<String>()
        for (entry in this.entries) {
            values.add(entry.value)
        }
        values.toArray()
    }

    public func readAllEntries(): Array<StorageEntry<String>> {
        this.entries.toArray()
    }

    private func deleteExisting(key: String): Unit {
        var index: Int64 = 0
        while (index < this.entries.size) {
            if (this.entries[index].key == key) {
                this.entries.remove(at: index)
                return
            }
            index += 1
        }
    }
}

public class FakeAsyncSessionStorage <: AsyncStorageAdapter<String> {
    public let inner: FakeSessionStorage = FakeSessionStorage()

    public init() {}

    public func read(key: String): SessionTask<Option<String>> {
        SessionTask<Option<String>>({ => this.inner.read(key) })
    }

    public func write(key: String, value: String): SessionTask<Unit> {
        SessionTask<Unit>({ => this.inner.write(key, value) })
    }

    public func delete(key: String): SessionTask<Unit> {
        SessionTask<Unit>({ => this.inner.delete(key) })
    }

    public func has(key: String): SessionTask<Bool> {
        SessionTask<Bool>({ => this.inner.has(key) })
    }

    public func readAll(): SessionTask<Array<String>> {
        SessionTask<Array<String>>({ => this.inner.readAll() })
    }

    public func readAllKeys(): SessionTask<Array<String>> {
        SessionTask<Array<String>>({ => this.inner.readAllKeys() })
    }

    public func readAllValues(): SessionTask<Array<String>> {
        SessionTask<Array<String>>({ => this.inner.readAllValues() })
    }

    public func readAllEntries(): SessionTask<Array<StorageEntry<String>>> {
        SessionTask<Array<StorageEntry<String>>>({ => this.inner.readAllEntries() })
    }
}
