package grammy4cj.platform

import grammy4cj.core.BaseFetchConfig as CoreBaseFetchConfig
import grammy4cj.platform_contract.platformInputFileRawContractFor as contractInputFileRawContractFor
import grammy4cj.platform_contract.platformNormalizeInputFileRuntime as contractNormalizeInputFileRuntime
import grammy4cj.platform_contract.platformSupportsInputFileSourceKind as contractSupportsInputFileSourceKind

public type BaseFetchConfig = CoreBaseFetchConfig

public let DEFAULT_WEBHOOK_ADAPTER: String = "callback"

public class PlatformRuntimeContract {
    public let runtime: String
    public let defaultAdapter: String
    public let baseFetchConfigContract: String
    public let byteStreamContract: String
    public let debugContract: String

    public init(
        runtime: String,
        defaultAdapter: String,
        baseFetchConfigContract: String,
        byteStreamContract: String,
        debugContract: String
    ) {
        this.runtime = runtime
        this.defaultAdapter = defaultAdapter
        this.baseFetchConfigContract = baseFetchConfigContract
        this.byteStreamContract = byteStreamContract
        this.debugContract = debugContract
    }

    public func summary(): String {
        this.runtime + ":" + this.defaultAdapter + ":" + this.baseFetchConfigContract + ":" + this.byteStreamContract
    }
}

public class DebugContract {
    public let runtime: String
    public let namespace: String
    public let implementation: String
    public let envVariable: String
    public let permissionAware: Bool
    public let colorAware: Bool

    public init(
        runtime: String,
        namespace: String,
        implementation: String,
        envVariable: String,
        permissionAware: Bool,
        colorAware: Bool
    ) {
        this.runtime = runtime
        this.namespace = namespace
        this.implementation = implementation
        this.envVariable = envVariable
        this.permissionAware = permissionAware
        this.colorAware = colorAware
    }

    public func summary(): String {
        this.runtime + ":" + this.implementation + ":" + this.envVariable
    }
}

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
    public let hasBody: Bool
    public var consumed: Bool = false

    public init(sourceKind: String, sourceValue: String, filename: String, chunkCount: Int64, reusable: Bool) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.chunkCount = chunkCount
        this.reusable = reusable
        this.hasBody = true
    }

    public init(sourceKind: String, sourceValue: String, filename: String, chunkCount: Int64, reusable: Bool, hasBody: Bool) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.chunkCount = chunkCount
        this.reusable = reusable
        this.hasBody = hasBody
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

    public static func urlLike(url: String, filename: String): PlatformRawSource {
        PlatformRawSource("url_like", url, filename, 1, true)
    }

    public static func blob(label: String, filename: String): PlatformRawSource {
        PlatformRawSource("blob", label, filename, 1, true)
    }

    public static func response(label: String, filename: String, hasBody: Bool): PlatformRawSource {
        PlatformRawSource("response", label, filename, 1, true, hasBody)
    }

    public static func stream(label: String, filename: String, chunkCount: Int64): PlatformRawSource {
        PlatformRawSource("stream", label, filename, chunkCount, false)
    }

    public static func iterable(label: String, filename: String, chunkCount: Int64): PlatformRawSource {
        PlatformRawSource("iterable", label, filename, chunkCount, false)
    }

    public static func asyncIterable(label: String, filename: String, chunkCount: Int64): PlatformRawSource {
        PlatformRawSource("async_iterable", label, filename, chunkCount, false)
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
    public let reusableSource: Bool
    public let requiresFileAdapter: Bool
    public let requiresFetchAdapter: Bool

    public init(runtime: String, sourceKind: String, sourceValue: String, filename: String, contract: String, stream: ByteStream) {
        this.runtime = runtime
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.contract = contract
        this.stream = stream
        this.reusableSource = true
        this.requiresFileAdapter = sourceKind == "path"
        this.requiresFetchAdapter = sourceKind == "url" || sourceKind == "url_like"
    }

    public init(
        runtime: String,
        sourceKind: String,
        sourceValue: String,
        filename: String,
        contract: String,
        stream: ByteStream,
        reusableSource: Bool,
        requiresFileAdapter: Bool,
        requiresFetchAdapter: Bool
    ) {
        this.runtime = runtime
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.contract = contract
        this.stream = stream
        this.reusableSource = reusableSource
        this.requiresFileAdapter = requiresFileAdapter
        this.requiresFetchAdapter = requiresFetchAdapter
    }

    public func summary(): String {
        this.runtime + ":" + this.sourceKind + ":" + this.contract + ":" + this.filename
    }

    public func consume(): String {
        this.stream.consume()
        this.summary()
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
        this.adapter = defaultAdapterForRuntime(runtime)
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

    public func debug(namespace: String): DebugContract {
        debugContract(this.runtime, namespace)
    }
}

public func defaultAdapter(): String {
    DEFAULT_WEBHOOK_ADAPTER
}

public func defaultAdapterForRuntime(runtime: String): String {
    if (runtime == "deno") {
        return "oak"
    }
    if (runtime == "node") {
        return "express"
    }
    if (runtime == "web") {
        return "cloudflare"
    }
    DEFAULT_WEBHOOK_ADAPTER
}

public func platformRuntimeContracts(): Array<PlatformRuntimeContract> {
    [
        PlatformRuntimeContract("deno", "oak", "empty-fetch-config", "ReadableStream.from(asyncIterable)", "debug-skypack-deno-env"),
        PlatformRuntimeContract("node", "express", "keep-alive-agent", "Readable.from(asyncIterable)", "debug-node"),
        PlatformRuntimeContract("web", "cloudflare", "empty-fetch-config", "manual-readable-stream", "debug-skypack-web"),
        PlatformRuntimeContract("cjnative", DEFAULT_WEBHOOK_ADAPTER, "node-compatible-fetch-config", "fake-byte-stream", "logger-sanitizer")
    ]
}

public func platformRuntimeContractCount(): Int64 {
    4
}

public func platformRuntimeContractFor(runtime: String): PlatformRuntimeContract {
    for (contract in platformRuntimeContracts()) {
        if (contract.runtime == runtime) {
            return contract
        }
    }
    PlatformRuntimeContract(runtime, defaultAdapterForRuntime(runtime), "unknown", "unknown", "unknown")
}

public func debugContract(runtime: String, namespace: String): DebugContract {
    if (runtime == "deno") {
        return DebugContract("deno", namespace, "debug", "DEBUG", true, true)
    }
    if (runtime == "node") {
        return DebugContract("node", namespace, "debug", "DEBUG", false, true)
    }
    if (runtime == "web") {
        return DebugContract("web", namespace, "debug", "DEBUG", false, true)
    }
    DebugContract(runtime, namespace, "logger-sanitizer", "DEBUG", false, false)
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
    if (!source.hasBody) {
        throw Exception("No response body!")
    }
    source.consumeIfSingleUse()
    let contract = platformInputFileRawContract(source.sourceKind, normalizedRuntime)
    PlatformRawData(
        runtime,
        source.sourceKind,
        source.sourceValue,
        source.filename,
        contract,
        ByteStream(source.sourceKind, source.sourceValue, source.chunkCount, contract),
        source.reusable,
        source.sourceKind == "path",
        source.sourceKind == "url" || source.sourceKind == "url_like"
    )
}

public func platformSupportsInputFileSource(sourceKind: String, runtime: String): Bool {
    contractSupportsInputFileSourceKind(sourceKind, runtime)
}

public func platformInputFileRawContract(sourceKind: String, runtime: String): String {
    contractInputFileRawContractFor(sourceKind, runtime, sourceKind + "-raw")
}

private func normalizeRuntime(runtime: String): String {
    contractNormalizeInputFileRuntime(runtime)
}

private func boolString(value: Bool): String {
    if (value) { "true" } else { "false" }
}
