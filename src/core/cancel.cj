package grammy4cj.core

public class CancelSignal {
    public var cancelled: Bool = false
    public var reason: String = ""
    private let parent: Option<CancelSignal>

    public init() {
        this.parent = None<CancelSignal>
    }

    public init(parent: CancelSignal) {
        this.parent = Some(parent)
    }

    public func cancel(reason: String): Unit {
        this.cancelled = true
        this.reason = reason
    }

    public func isCancelled(): Bool {
        if (this.cancelled) {
            return true
        }
        match (this.parent) {
            case Some(parentSignal) => parentSignal.isCancelled()
            case None => false
        }
    }

    public func cancellationReason(): String {
        if (this.cancelled) {
            return this.reason
        }
        match (this.parent) {
            case Some(parentSignal) => parentSignal.cancellationReason()
            case None => ""
        }
    }

    public func throwIfCancelled(): Unit {
        if (this.isCancelled()) {
            throw Exception("Operation cancelled: " + this.cancellationReason())
        }
    }
}

public class CancelController {
    public let signal: CancelSignal

    public init() {
        this.signal = CancelSignal()
    }

    public func cancel(reason: String): Unit {
        this.signal.cancel(reason)
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
