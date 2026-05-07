package grammy4cj.test_support

import grammy4cj.core.Payload
import grammy4cj.core.createJsonPayload
import grammy4cj.core.createJsonPayloadWithMethod

public func payloadBodyEquals(payload: Payload, expected: String): Bool {
    payload.body == expected
}

public func payloadJsonEquals(payload: Payload, expected: String): Bool {
    createJsonPayload(payload).body == expected
}

public func webhookPayloadEquals(payload: Payload, method: String, expected: String): Bool {
    createJsonPayloadWithMethod(payload, method).body == expected
}
