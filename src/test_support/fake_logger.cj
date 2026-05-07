package grammy4cj.test_support

public class FakeLogger {
    public var debugCount: Int64 = 0
    public var warnCount: Int64 = 0
    public var errorCount: Int64 = 0
    public var lastMessage: String = ""

    public init() {}

    public func debug(message: String): Unit {
        this.debugCount += 1
        this.lastMessage = message
    }

    public func warn(message: String): Unit {
        this.warnCount += 1
        this.lastMessage = message
    }

    public func error(message: String): Unit {
        this.errorCount += 1
        this.lastMessage = message
    }
}
