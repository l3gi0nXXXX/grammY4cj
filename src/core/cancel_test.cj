package grammy4cj.core

import std.unittest.*

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
    public func timeoutConfigCanBeDisabled(): Unit {
        @Expect(TimeoutConfig(0).isEnabled(), false)
        @Expect(TimeoutConfig(1000).isEnabled(), true)
    }
}
