package grammy4cj.platform

import std.unittest.*

@Test
public class PlatformTest {
    @TestCase
    public func defaultPlatformExposesCjnativeRuntimeAndFallbackHttp(): Unit {
        let platform = defaultPlatform()
        let req = PlatformHttpRequest("POST", "https://api.telegram.org/botT/getMe", "", "{}")
        let res = platform.request(req)

        @Expect(platform.runtime, "cjnative")
        @Expect(platform.supportsLongPolling(), true)
        @Expect(res.status, 599)
        @Expect(res.body.contains("POST https://api.telegram.org/botT/getMe"), true)
    }

    @TestCase
    public func loggerRedactsTokenFromMessage(): Unit {
        let logger = Logger("grammy:core")
        let sanitized = logger.sanitize("token 123:ABC failed", "123:ABC")

        @Expect(logger.namespace, "grammy:core")
        @Expect(sanitized, "token <redacted> failed")
        @Expect(redactToken("unchanged", ""), "unchanged")
    }

    @TestCase
    public func byteStreamIsSingleUseBoundary(): Unit {
        let stream = ByteStream("supplier")

        @Expect(stream.sourceKind, "supplier")
        @Expect(stream.consumed, false)
        stream.consume()
        @Expect(stream.consumed, true)
    }
}
