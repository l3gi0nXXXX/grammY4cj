package grammy4cj.platform

import std.unittest.*

private class FakePlatformRawAdapter {
    public var fileReadCount: Int64 = 0
    public var urlFetchCount: Int64 = 0
    public var bytesConsumeCount: Int64 = 0
    public var streamConsumeCount: Int64 = 0
    public var lastSummary: String = ""

    public init() {}

    public func consume(raw: PlatformRawData): String {
        if (raw.requiresFileAdapter) {
            this.fileReadCount += 1
        }
        if (raw.requiresFetchAdapter) {
            this.urlFetchCount += 1
        }
        if (raw.sourceKind == "bytes") {
            this.bytesConsumeCount += 1
        }
        if (!raw.reusableSource) {
            this.streamConsumeCount += 1
        }
        this.lastSummary = raw.consume()
        this.lastSummary
    }
}

private class FakePlatformHttpClient <: PlatformHttpClient {
    public var requestCount: Int64 = 0
    public var lastUrl: String = ""

    public init() {}

    public func send(req: PlatformHttpRequest): PlatformHttpResponse {
        this.requestCount += 1
        this.lastUrl = req.url
        PlatformHttpResponse(200, "fake:" + req.method + ":" + req.body)
    }
}

private class FakePlatformFileSourceAdapter <: PlatformFileSourceAdapter {
    public var readCount: Int64 = 0
    public var lastPath: String = ""

    public init() {}

    public func read(path: String): Array<Byte> {
        this.readCount += 1
        this.lastPath = path
        ("file:" + path).toArray()
    }
}

private class FakePlatformFetchSourceAdapter <: PlatformFetchSourceAdapter {
    public var fetchCount: Int64 = 0
    public var lastUrl: String = ""
    public var hasBody: Bool = true

    public init() {}

    public func fetch(url: String): PlatformFetchResult {
        this.fetchCount += 1
        this.lastUrl = url
        if (!this.hasBody) {
            return PlatformFetchResult.noBody(url)
        }
        PlatformFetchResult(url, ("url:" + url).toArray())
    }
}

private class FakeDebugEnvSource <: DebugEnvSource {
    public var value: String = ""
    public var granted: Bool = false
    public var colorDisabled: Bool = false
    public var lastName: String = ""

    public init() {}

    public func get(name: String): String {
        this.lastName = name
        this.value
    }

    public func permissionGranted(name: String): Bool {
        this.lastName = name
        this.granted
    }

    public func noColor(): Bool {
        this.colorDisabled
    }
}

private func platformRawErrorMessage(platform: PlatformAdapter, source: PlatformRawSource): String {
    var message = ""
    try {
        platform.inputFileRaw(source)
    } catch (e: Exception) {
        message = e.message
    }
    message
}

private func platformRawCollectErrorMessage(raw: PlatformRawData): String {
    var message = ""
    try {
        raw.collectBytes()
    } catch (e: Exception) {
        message = e.message
    }
    message
}

private func byteStreamCollectErrorMessage(stream: ByteStream): String {
    var message = ""
    try {
        stream.collectBytes()
    } catch (e: Exception) {
        message = e.message
    }
    message
}

@Test
public class PlatformTest {
    @TestCase
    public func defaultPlatformExposesCjnativeRuntimeAndFallbackHttp(): Unit {
        let http = FakePlatformHttpClient()
        let platform = PlatformAdapter("cjnative", defaultAdapterForRuntime("cjnative"), http, PlatformInputFileDataAdapter())
        let req = PlatformHttpRequest("POST", "https://api.telegram.org/botT/getMe", "", "{}")
        let res = platform.request(req)
        let deno = PlatformAdapter("deno")
        let node = PlatformAdapter("node")
        let web = PlatformAdapter("web")

        @Expect(platform.runtime, "cjnative")
        @Expect(platform.adapter, "cangjie-native")
        @Expect(defaultAdapter(), "callback")
        @Expect(defaultAdapterForRuntime("cjnative"), "cangjie-native")
        @Expect(defaultAdapterForRuntime("deno"), "oak")
        @Expect(defaultAdapterForRuntime("node"), "express")
        @Expect(defaultAdapterForRuntime("web"), "cloudflare")
        @Expect(deno.adapter, "oak")
        @Expect(node.adapter, "express")
        @Expect(web.adapter, "cloudflare")
        @Expect(platform.supportsLongPolling(), true)
        @Expect(res.status, 200)
        @Expect(res.body, "fake:POST:{}")
        @Expect(http.requestCount, 1)
        @Expect(http.lastUrl, "https://api.telegram.org/botT/getMe")
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
        let denoDebug = debugContract("deno", "grammy:warn")
        let nodeDebug = PlatformAdapter("node").debug("grammy:warn")

        @Expect(logger.namespace, "grammy:core")
        @Expect(sanitized, "token <redacted> failed")
        @Expect(redactToken("unchanged", ""), "unchanged")
        @Expect(denoDebug.summary(), "deno:debug:DEBUG")
        @Expect(denoDebug.permissionAware, true)
        @Expect(nodeDebug.summary(), "node:debug:DEBUG")
        @Expect(nodeDebug.permissionAware, false)
    }

    @TestCase
    public func debugStateMirrorsDenoPermissionAndNodeEnvSemantics(): Unit {
        let env = FakeDebugEnvSource()
        let denied = debugState("deno", "grammy:warn", env)
        env.value = "grammy:*"
        let node = debugState("node", "grammy:warn", env)
        env.granted = true
        let deno = debugState("deno", "grammy:warn", env)
        env.colorDisabled = true
        let noColor = debugState("deno", "grammy:warn", env)
        let web = debugState("web", "grammy:warn", env)
        let native = PlatformAdapter("cjnative").debugState("grammy:warn")

        @Expect(denied.canReadEnv, false)
        @Expect(denied.enabled, false)
        @Expect(node.canReadEnv, true)
        @Expect(node.enabled, true)
        @Expect(node.envValue, "grammy:*")
        @Expect(deno.canReadEnv, true)
        @Expect(deno.summary(), "deno:true:true:grammy:*")
        @Expect(noColor.useColors, false)
        @Expect(web.canReadEnv, false)
        @Expect(web.enabled, false)
        @Expect(native.enabled, false)
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
    public func iteratorToStreamBuildsRealByteSourceStream(): Unit {
        let iterator = ByteIterator("chunks:2", 2)
        let stream = itrToStream(iterator)
        let chunked = ByteStream("iterator", "manual", 2, "manual-readable-stream", ["AB".toArray(), "CD".toArray()])
        let failing = failingByteStream("iterator", "boom", 1, "manual-readable-stream", "stream exploded")

        @Expect(iterator.consumed, true)
        @Expect(stream.sourceKind, "iterator")
        @Expect(stream.sourceValue, "chunks:2")
        @Expect(stream.chunkCount, 2)
        @Expect(stream.contract, "async-iterable-to-byte-stream")
        @Expect(String.fromUtf8(stream.collectBytes()), "chunks:2")
        @Expect(String.fromUtf8(chunked.collectBytes()), "ABCD")
        @Expect(byteStreamCollectErrorMessage(failing), "stream exploded")
        @Expect(defaultPlatform().itrToStream(ByteIterator("chunks:1", 1)).chunkCount, 1)
    }

    @TestCase
    public func inputFileRawAdapterMirrorsRuntimeContractsWithoutIo(): Unit {
        let deno = PlatformAdapter("deno", "oak")
        let node = PlatformAdapter("node", "express")
        let web = PlatformAdapter("web", "cloudflare")
        let denoPath = deno.inputFileRaw(PlatformRawSource.path("/tmp/photo.png", "photo.png"))
        let nodePath = node.inputFileRaw(PlatformRawSource.path("/tmp/photo.png", "photo.png"))
        let webUrl = web.inputFileRaw(PlatformRawSource.urlLike("https://example.test/a.png", "a.png"))
        let webBytes = web.inputFileRaw(PlatformRawSource.bytes("bytes:3", "a.bin"))
        let fake = FakePlatformRawAdapter()

        @Expect(denoPath.summary(), "deno:path:deno-open-file-async-iterator:photo.png")
        @Expect(denoPath.stream.contract, "deno-open-file-async-iterator")
        @Expect(nodePath.contract, "node-create-read-stream")
        @Expect(webUrl.contract, "fetch-body-async-iterable")
        @Expect(webBytes.contract, "uint8-array-as-is")
        @Expect(inputFileRaw(PlatformRawSource.bytes("bytes:1", "default.bin")).contract, "uint8-array-as-is")
        @Expect(fake.consume(denoPath), "deno:path:deno-open-file-async-iterator:photo.png")
        @Expect(fake.consume(webUrl), "web:url_like:fetch-body-async-iterable:a.png")
        @Expect(fake.consume(webBytes), "web:bytes:uint8-array-as-is:a.bin")
        @Expect(fake.fileReadCount, 1)
        @Expect(fake.urlFetchCount, 1)
        @Expect(fake.bytesConsumeCount, 1)
    }

    @TestCase
    public func inputFileRawAdapterCollectsBytesThroughInjectedRuntimeAdapters(): Unit {
        let fileAdapter = FakePlatformFileSourceAdapter()
        let fetchAdapter = FakePlatformFetchSourceAdapter()
        let dataAdapter = PlatformInputFileDataAdapter(fileAdapter, fetchAdapter)
        let platform = PlatformAdapter("node", "express", FakePlatformHttpClient(), dataAdapter)
        let pathRaw = platform.inputFileRaw(PlatformRawSource.path("/tmp/photo.png", "photo.png"))
        let urlRaw = platform.inputFileRaw(PlatformRawSource.urlLike("https://example.test/a.png", "a.png"))

        @Expect(String.fromUtf8(pathRaw.collectBytes()), "file:/tmp/photo.png")
        @Expect(fileAdapter.readCount, 1)
        @Expect(fileAdapter.lastPath, "/tmp/photo.png")
        @Expect(String.fromUtf8(urlRaw.collectBytes()), "url:https://example.test/a.png")
        @Expect(fetchAdapter.fetchCount, 1)
        @Expect(fetchAdapter.lastUrl, "https://example.test/a.png")
    }

    @TestCase
    public func inputFileRawAdapterSeparatesFetchAndResponseMissingBodyErrors(): Unit {
        let fetchAdapter = FakePlatformFetchSourceAdapter()
        fetchAdapter.hasBody = false
        let dataAdapter = PlatformInputFileDataAdapter(FakePlatformFileSourceAdapter(), fetchAdapter)
        let platform = PlatformAdapter("web", "cloudflare", FakePlatformHttpClient(), dataAdapter)
        let urlRaw = platform.inputFileRaw(PlatformRawSource.url("https://example.test/no-body.bin", "no-body.bin"))

        @Expect(platformRawCollectErrorMessage(urlRaw), "Download failed, no response body from 'https://example.test/no-body.bin'")
        @Expect(
            platformRawErrorMessage(PlatformAdapter("deno"), PlatformRawSource.response("empty", "empty.bin", false)),
            "No response body!"
        )
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

    @TestCase
    public func platformRuntimeContractsEnumerateUpstreamDifferences(): Unit {
        let deno = platformRuntimeContractFor("deno")
        let node = platformRuntimeContractFor("node")
        let web = platformRuntimeContractFor("web")
        let cjnative = platformRuntimeContractFor("cjnative")

        @Expect(platformRuntimeContractCount(), 4)
        @Expect(platformRuntimeContracts().size, 4)
        @Expect(deno.summary(), "deno:oak:empty-fetch-config:ReadableStream.from(asyncIterable)")
        @Expect(node.defaultAdapter, "express")
        @Expect(node.baseFetchConfigContract, "keep-alive-agent")
        @Expect(web.defaultAdapter, "cloudflare")
        @Expect(web.byteStreamContract, "manual-readable-stream")
        @Expect(cjnative.defaultAdapter, "cangjie-native")
        @Expect(cjnative.byteStreamContract, "byte-source-stream")
    }
}
