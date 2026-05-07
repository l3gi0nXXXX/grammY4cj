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
        @Expect(platform.adapter, "callback")
        @Expect(defaultAdapter(), "callback")
        @Expect(platform.supportsLongPolling(), true)
        @Expect(res.status, 599)
        @Expect(res.body.contains("POST https://api.telegram.org/botT/getMe"), true)
    }

    @TestCase
    public func baseFetchConfigMirrorsRuntimeContracts(): Unit {
        let https = baseFetchConfig("https://api.telegram.org")
        let http = baseFetchConfig("http://localhost:8081")
        let custom = baseFetchConfig("unix:/tmp/socket")

        @Expect(https.agentKind, "https")
        @Expect(https.keepAlive, true)
        @Expect(https.compress, true)
        @Expect(https.summary(), "https:keepAlive=true:compress=true")
        @Expect(http.agentKind, "http")
        @Expect(http.keepAlive, true)
        @Expect(http.compress, false)
        @Expect(custom.isEmpty, true)
        @Expect(defaultPlatform().baseFetchConfig("ftp://example.test").summary(), "empty")
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

    @TestCase
    public func iteratorToStreamBuildsFakeSingleUseStream(): Unit {
        let iterator = ByteIterator("chunks:2", 2)
        let stream = itrToStream(iterator)

        @Expect(iterator.consumed, true)
        @Expect(stream.sourceKind, "iterator")
        @Expect(stream.sourceValue, "chunks:2")
        @Expect(stream.chunkCount, 2)
        @Expect(stream.contract, "async-iterable-to-byte-stream")
        @Expect(defaultPlatform().itrToStream(ByteIterator("chunks:1", 1)).chunkCount, 1)
    }
}
