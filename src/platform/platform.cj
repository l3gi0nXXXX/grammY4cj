package grammy4cj.platform

public let DEFAULT_WEBHOOK_ADAPTER: String = "callback"

public class PlatformHttpRequest {
    public let method: String
    public let url: String
    public let headers: String
    public let body: String

    public init(method: String, url: String, headers: String, body: String) {
        this.method = method
        this.url = url
        this.headers = headers
        this.body = body
    }
}

public class PlatformHttpResponse {
    public let status: Int64
    public let body: String

    public init(status: Int64, body: String) {
        this.status = status
        this.body = body
    }
}

public class BaseFetchConfig {
    public let apiRoot: String
    public let agentKind: String
    public let keepAlive: Bool
    public let compress: Bool
    public let isEmpty: Bool

    public init(apiRoot: String, agentKind: String, keepAlive: Bool, compress: Bool, isEmpty: Bool) {
        this.apiRoot = apiRoot
        this.agentKind = agentKind
        this.keepAlive = keepAlive
        this.compress = compress
        this.isEmpty = isEmpty
    }

    public func summary(): String {
        if (this.isEmpty) {
            return "empty"
        }
        this.agentKind + ":keepAlive=" + boolString(this.keepAlive) + ":compress=" + boolString(this.compress)
    }
}

public class ByteIterator {
    public let label: String
    public let chunkCount: Int64
    public var consumed: Bool = false

    public init(label: String, chunkCount: Int64) {
        this.label = label
        this.chunkCount = chunkCount
    }

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("ByteIterator has already been consumed.")
        }
        this.consumed = true
    }
}

public class ByteStream {
    public let sourceKind: String
    public let sourceValue: String
    public let chunkCount: Int64
    public let contract: String
    public var consumed: Bool = false

    public init(sourceKind: String) {
        this.sourceKind = sourceKind
        this.sourceValue = ""
        this.chunkCount = 0
        this.contract = "stream"
    }

    public init(sourceKind: String, sourceValue: String, chunkCount: Int64, contract: String) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.chunkCount = chunkCount
        this.contract = contract
    }

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("ByteStream has already been consumed.")
        }
        this.consumed = true
    }
}

public class PlatformRawSource {
    public let sourceKind: String
    public let sourceValue: String
    public let filename: String
    public let chunkCount: Int64
    public let reusable: Bool
    public var consumed: Bool = false

    public init(sourceKind: String, sourceValue: String, filename: String, chunkCount: Int64, reusable: Bool) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.chunkCount = chunkCount
        this.reusable = reusable
    }

    public static func bytes(label: String, filename: String): PlatformRawSource {
        PlatformRawSource("bytes", label, filename, 1, true)
    }

    public static func path(path: String, filename: String): PlatformRawSource {
        PlatformRawSource("path", path, filename, 1, true)
    }

    public static func url(url: String, filename: String): PlatformRawSource {
        PlatformRawSource("url", url, filename, 1, true)
    }

    public static func stream(label: String, filename: String, chunkCount: Int64): PlatformRawSource {
        PlatformRawSource("stream", label, filename, chunkCount, false)
    }

    public static func supplier(label: String, filename: String): PlatformRawSource {
        PlatformRawSource("supplier", label, filename, 1, true)
    }

    public func consumeIfSingleUse(): Unit {
        if (!this.reusable) {
            if (this.consumed) {
                throw Exception("Platform raw source has already been consumed.")
            }
            this.consumed = true
        }
    }
}

public class PlatformRawData {
    public let runtime: String
    public let sourceKind: String
    public let sourceValue: String
    public let filename: String
    public let contract: String
    public let stream: ByteStream

    public init(runtime: String, sourceKind: String, sourceValue: String, filename: String, contract: String, stream: ByteStream) {
        this.runtime = runtime
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.contract = contract
        this.stream = stream
    }

    public func summary(): String {
        this.runtime + ":" + this.sourceKind + ":" + this.contract + ":" + this.filename
    }
}

public class Logger {
    public let namespace: String

    public init(namespace: String) {
        this.namespace = namespace
    }

    public func sanitize(message: String, token: String): String {
        redactToken(message, token)
    }
}

public func redactToken(message: String, token: String): String {
    if (token.isEmpty()) {
        return message
    }
    message.replace(token, "<redacted>")
}

public class PlatformAdapter {
    public let runtime: String
    public let adapter: String

    public init(runtime: String) {
        this.runtime = runtime
        this.adapter = DEFAULT_WEBHOOK_ADAPTER
    }

    public init(runtime: String, adapter: String) {
        this.runtime = runtime
        this.adapter = adapter
    }

    public func supportsLongPolling(): Bool {
        true
    }

    public func request(req: PlatformHttpRequest): PlatformHttpResponse {
        PlatformHttpResponse(599, "No HTTP client configured for " + req.method + " " + req.url)
    }

    public func baseFetchConfig(apiRoot: String): BaseFetchConfig {
        makeBaseFetchConfig(apiRoot)
    }

    public func itrToStream(iterator: ByteIterator): ByteStream {
        makeByteStreamFromIterator(iterator)
    }

    public func inputFileRaw(source: PlatformRawSource): PlatformRawData {
        makeInputFileRaw(this.runtime, source)
    }

    public func logger(namespace: String): Logger {
        Logger(namespace)
    }
}

public func defaultAdapter(): String {
    DEFAULT_WEBHOOK_ADAPTER
}

public func defaultPlatform(): PlatformAdapter {
    PlatformAdapter("cjnative", defaultAdapter())
}

public func baseFetchConfig(apiRoot: String): BaseFetchConfig {
    makeBaseFetchConfig(apiRoot)
}

public func itrToStream(iterator: ByteIterator): ByteStream {
    makeByteStreamFromIterator(iterator)
}

public func inputFileRaw(source: PlatformRawSource): PlatformRawData {
    makeInputFileRaw("cjnative", source)
}

private func makeBaseFetchConfig(apiRoot: String): BaseFetchConfig {
    if (apiRoot.startsWith("https:")) {
        return BaseFetchConfig(apiRoot, "https", true, true, false)
    }
    if (apiRoot.startsWith("http:")) {
        return BaseFetchConfig(apiRoot, "http", true, false, false)
    }
    BaseFetchConfig(apiRoot, "", false, false, true)
}

private func makeByteStreamFromIterator(iterator: ByteIterator): ByteStream {
    iterator.consume()
    ByteStream("iterator", iterator.label, iterator.chunkCount, "async-iterable-to-byte-stream")
}

private func makeInputFileRaw(runtime: String, source: PlatformRawSource): PlatformRawData {
    let normalizedRuntime = normalizeRuntime(runtime)
    if (!platformSupportsInputFileSource(source.sourceKind, normalizedRuntime)) {
        throw Exception("Platform runtime '" + normalizedRuntime + "' does not support InputFile source kind '" + source.sourceKind + "'")
    }
    source.consumeIfSingleUse()
    let contract = platformInputFileRawContract(source.sourceKind, normalizedRuntime)
    PlatformRawData(
        runtime,
        source.sourceKind,
        source.sourceValue,
        source.filename,
        contract,
        ByteStream(source.sourceKind, source.sourceValue, source.chunkCount, contract)
    )
}

public func platformSupportsInputFileSource(sourceKind: String, runtime: String): Bool {
    let normalizedRuntime = normalizeRuntime(runtime)
    if (sourceKind == "path") {
        return normalizedRuntime == "deno" || normalizedRuntime == "node"
    }
    if (sourceKind == "blob") {
        return normalizedRuntime == "deno" || normalizedRuntime == "web"
    }
    if (sourceKind == "response") {
        return normalizedRuntime == "deno"
    }
    if (sourceKind == "supplier") {
        return normalizedRuntime == "deno" || normalizedRuntime == "node"
    }
    sourceKind == "url" || sourceKind == "url_like" || sourceKind == "bytes" || sourceKind == "stream" ||
        sourceKind == "iterable" || sourceKind == "async_iterable"
}

public func platformInputFileRawContract(sourceKind: String, runtime: String): String {
    let normalizedRuntime = normalizeRuntime(runtime)
    if (sourceKind == "path") {
        if (normalizedRuntime == "deno") {
            return "deno-open-file-async-iterator"
        }
        return "node-create-read-stream"
    }
    if (sourceKind == "url" || sourceKind == "url_like") {
        return "fetch-body-async-iterable"
    }
    if (sourceKind == "bytes") {
        return "uint8-array-as-is"
    }
    if (sourceKind == "blob") {
        return "blob-stream"
    }
    if (sourceKind == "response") {
        return "response-body"
    }
    if (sourceKind == "stream") {
        if (normalizedRuntime == "node") {
            return "node-read-stream-as-is"
        }
        return "readable-stream-as-is"
    }
    if (sourceKind == "iterable") {
        return "iterator-as-is"
    }
    if (sourceKind == "async_iterable") {
        return "async-iterator-as-is"
    }
    if (sourceKind == "supplier") {
        return "supplier-deferred"
    }
    sourceKind + "-raw"
}

private func normalizeRuntime(runtime: String): String {
    if (runtime == "deno" || runtime == "node" || runtime == "web") {
        return runtime
    }
    if (runtime.isEmpty() || runtime == "cjnative") {
        return "node"
    }
    runtime
}

private func boolString(value: Bool): String {
    if (value) { "true" } else { "false" }
}
