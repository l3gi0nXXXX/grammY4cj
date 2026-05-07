package grammy4cj.test_support

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
