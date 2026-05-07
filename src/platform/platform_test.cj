package grammy4cj.platform

import std.unittest.*

private func platformRawErrorMessage(platform: PlatformAdapter, source: PlatformRawSource): String {
    var message = ""
    try {
        platform.inputFileRaw(source)
    } catch (e: Exception) {
        message = e.message
    }
    message
}

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

    @TestCase
    public func inputFileRawAdapterMirrorsRuntimeContractsWithoutIo(): Unit {
        let deno = PlatformAdapter("deno", "oak")
        let node = PlatformAdapter("node", "express")
        let web = PlatformAdapter("web", "cloudflare")
        let denoPath = deno.inputFileRaw(PlatformRawSource.path("/tmp/photo.png", "photo.png"))
        let nodePath = node.inputFileRaw(PlatformRawSource.path("/tmp/photo.png", "photo.png"))
        let webUrl = web.inputFileRaw(PlatformRawSource.url("https://example.test/a.png", "a.png"))
        let webBytes = web.inputFileRaw(PlatformRawSource.bytes("bytes:3", "a.bin"))

        @Expect(denoPath.summary(), "deno:path:deno-open-file-async-iterator:photo.png")
        @Expect(denoPath.stream.contract, "deno-open-file-async-iterator")
        @Expect(nodePath.contract, "node-create-read-stream")
        @Expect(webUrl.contract, "fetch-body-async-iterable")
        @Expect(webBytes.contract, "uint8-array-as-is")
        @Expect(inputFileRaw(PlatformRawSource.bytes("bytes:1", "default.bin")).contract, "uint8-array-as-is")
    }

    @TestCase
    public func inputFileRawAdapterEnforcesSingleUseBoundaries(): Unit {
        let node = PlatformAdapter("node")
        let source = PlatformRawSource.stream("stream:2", "video.mp4", 2)
        let raw = node.inputFileRaw(source)

        @Expect(raw.contract, "node-read-stream-as-is")
        @Expect(raw.stream.sourceKind, "stream")
        @Expect(raw.stream.chunkCount, 2)
        @Expect(source.consumed, true)
        @Expect(platformRawErrorMessage(node, source), "Platform raw source has already been consumed.")
    }

    @TestCase
    public func inputFileRawAdapterRejectsUnsupportedRuntimeSources(): Unit {
        let node = PlatformAdapter("node")
        let web = PlatformAdapter("web")

        @Expect(platformSupportsInputFileSource("path", "deno"), true)
        @Expect(platformSupportsInputFileSource("path", "node"), true)
        @Expect(platformSupportsInputFileSource("path", "web"), false)
        @Expect(platformSupportsInputFileSource("supplier", "web"), false)
        @Expect(platformInputFileRawContract("stream", "node"), "node-read-stream-as-is")
        @Expect(
            platformRawErrorMessage(web, PlatformRawSource.path("/tmp/photo.png", "photo.png")),
            "Platform runtime 'web' does not support InputFile source kind 'path'"
        )
        @Expect(
            platformRawErrorMessage(node, PlatformRawSource("blob", "blob:1", "a.txt", 1, true)),
            "Platform runtime 'node' does not support InputFile source kind 'blob'"
        )
    }
}
