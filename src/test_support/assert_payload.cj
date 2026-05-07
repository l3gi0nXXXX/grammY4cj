package grammy4cj.test_support

import grammy4cj.core.Payload

public func payloadBodyEquals(payload: Payload, expected: String): Bool {
    payload.body == expected
}
