package grammy4cj.core

import std.collection.ArrayList

public type CancelListener = (CancelSignal) -> Unit

public class CancelSignal {
    public var cancelled: Bool = false
    public var reason: String = ""
    private let parent: Option<CancelSignal>
    private let listeners: ArrayList<CancelListener> = ArrayList<CancelListener>()

    public init() {
        this.parent = None<CancelSignal>
    }

    public init(parent: CancelSignal) {
        this.parent = Some(parent)
        parent.addEventListener("abort", { parentSignal: CancelSignal =>
            this.cancel(parentSignal.cancellationReason())
        })
    }

    public func cancel(reason: String): Unit {
        if (this.cancelled) {
            return
        }
        this.cancelled = true
        this.reason = reason
        for (listener in this.listeners) {
            listener(this)
        }
    }

    public func abort(reason: String): Unit {
        this.cancel(reason)
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

    public func aborted(): Bool {
        this.isCancelled()
    }

    public func addEventListener(event: String, listener: CancelListener): Unit {
        if (event != "abort") {
            return
        }
        this.listeners.add(listener)
        if (this.isCancelled()) {
            listener(this)
        }
    }

    public func removeEventListener(_event: String, _listener: CancelListener): Unit {
        ()
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

    public func abort(reason: String): Unit {
        this.signal.abort(reason)
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
