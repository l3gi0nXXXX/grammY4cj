package grammy4cj.core

import std.unittest.*

private class CancelListenerProbe {
    public var calls: Int64 = 0
    public var reason: String = ""

    public init() {}

    public func record(signal: CancelSignal): Unit {
        this.calls += 1
        this.reason = signal.cancellationReason()
    }
}

@Test
public class CancelTest {
    @TestCase
    public func cancelControllerUpdatesSignal(): Unit {
        let controller = CancelController()

        @Expect(controller.signal.cancelled, false)
        controller.cancel("stop polling")
        @Expect(controller.signal.cancelled, true)
        @Expect(controller.signal.reason, "stop polling")
    }

    @TestCase
    public func cancelSignalProvidesAbortSignalAliasesAndOneShotListeners(): Unit {
        let signal = CancelSignal()
        let probe = CancelListenerProbe()

        signal.addEventListener("abort", { aborted: CancelSignal =>
            probe.record(aborted)
        })
        signal.abort("user abort")
        signal.abort("ignored")

        @Expect(signal.aborted(), true)
        @Expect(signal.isCancelled(), true)
        @Expect(signal.reason, "user abort")
        @Expect(probe.calls, 1)
        @Expect(probe.reason, "user abort")
    }

    @TestCase
    public func childCancelSignalObservesParentAbort(): Unit {
        let parent = CancelSignal()
        let child = CancelSignal(parent)
        let probe = CancelListenerProbe()

        child.addEventListener("abort", { _signal: CancelSignal =>
            probe.record(child)
        })
        parent.abort("parent abort")

        @Expect(child.aborted(), true)
        @Expect(child.cancellationReason(), "parent abort")
        @Expect(probe.calls, 1)
        @Expect(probe.reason, "parent abort")
    }

    @TestCase
    public func timeoutConfigCanBeDisabled(): Unit {
        @Expect(TimeoutConfig(0).isEnabled(), false)
        @Expect(TimeoutConfig(1000).isEnabled(), true)
    }
}
