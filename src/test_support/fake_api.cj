package grammy4cj.test_support

import grammy4cj.core.Payload

public class FakeApi {
    public var called: Bool = false
    public var method: String = ""
    public var payloadBody: String = ""

    public init() {}

    public func call(method: String, payload: Payload): String {
        this.called = true
        this.method = method
        this.payloadBody = payload.body
        "{}"
    }
}
