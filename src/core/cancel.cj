package grammy4cj.core

public class CancelSignal {
    public var cancelled: Bool = false
    public var reason: String = ""

    public init() {}

    public func throwIfCancelled(): Unit {
        if (this.cancelled) {
            throw Exception("Operation cancelled: " + this.reason)
        }
    }
}

public class CancelController {
    public let signal: CancelSignal

    public init() {
        this.signal = CancelSignal()
    }

    public func cancel(reason: String): Unit {
        this.signal.cancelled = true
        this.signal.reason = reason
    }
}

public class TimeoutConfig {
    public let timeoutMillis: Int64

    public init(timeoutMillis: Int64) {
        this.timeoutMillis = timeoutMillis
    }

    public func isEnabled(): Bool {
        this.timeoutMillis > 0
    }
}
