package grammy4cj.test_support

public class FakeClock {
    public var nowMillis: Int64 = 0

    public init() {}

    public func sleep(ms: Int64): Unit {
        this.nowMillis += ms
    }
}
