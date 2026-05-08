package grammy4cj.platform

import std.collection.ArrayList
import std.fs.File

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

public interface DebugEnvSource {
    func get(name: String): String
    func permissionGranted(name: String): Bool
    func noColor(): Bool
}

public class EmptyDebugEnvSource <: DebugEnvSource {
    public init() {}

    public func get(name: String): String {
        ""
    }

    public func permissionGranted(name: String): Bool {
        false
    }

    public func noColor(): Bool {
        false
    }
}

public class DebugState {
    public let runtime: String
    public let namespace: String
    public let envVariable: String
    public let envValue: String
    public let canReadEnv: Bool
    public let enabled: Bool
    public let useColors: Bool

    public init(
        runtime: String,
        namespace: String,
        envVariable: String,
        envValue: String,
        canReadEnv: Bool,
        enabled: Bool,
        useColors: Bool
    ) {
        this.runtime = runtime
        this.namespace = namespace
        this.envVariable = envVariable
        this.envValue = envValue
        this.canReadEnv = canReadEnv
        this.enabled = enabled
        this.useColors = useColors
    }

    public func summary(): String {
        this.runtime + ":" + boolString(this.enabled) + ":" + boolString(this.useColors) + ":" + this.envValue
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

public interface PlatformHttpClient {
    func send(req: PlatformHttpRequest): PlatformHttpResponse
}

public class NativePlatformHttpClient <: PlatformHttpClient {
    public init() {}

    public func send(req: PlatformHttpRequest): PlatformHttpResponse {
        throw Exception("Native platform HTTP uses the Cangjie stdx.net.http ClientBuilder contract; inject a PlatformHttpClient in tests.")
    }
}

public func nativePlatformHttpClientContract(): String {
    "stdx.net.http.ClientBuilder"
}

public class PlatformFetchResult {
    public let url: String
    public let hasBody: Bool
    public let body: Array<Byte>

    public init(url: String, body: Array<Byte>) {
        this.url = url
        this.hasBody = true
        this.body = body
    }

    public init(url: String, hasBody: Bool, body: Array<Byte>) {
        this.url = url
        this.hasBody = hasBody
        this.body = body
    }

    public static func noBody(url: String): PlatformFetchResult {
        PlatformFetchResult(url, false, [])
    }
}

public interface PlatformFileSourceAdapter {
    func read(path: String): Array<Byte>
}

public interface PlatformFetchSourceAdapter {
    func fetch(url: String): PlatformFetchResult
}

public class NativePlatformFileSourceAdapter <: PlatformFileSourceAdapter {
    public init() {}

    public func read(path: String): Array<Byte> {
        File.readFrom(path)
    }
}

public class NativePlatformFetchSourceAdapter <: PlatformFetchSourceAdapter {
    public init() {}

    public func fetch(url: String): PlatformFetchResult {
        throw Exception("Native platform fetch uses the Cangjie stdx.net.http ClientBuilder contract; inject a PlatformFetchSourceAdapter in tests.")
    }
}

public func nativePlatformFetchSourceContract(): String {
    "stdx.net.http.ClientBuilder"
}

public class PlatformInputFileDataAdapter {
    private let fileAdapter: PlatformFileSourceAdapter
    private let fetchAdapter: PlatformFetchSourceAdapter

    public init() {
        this.fileAdapter = NativePlatformFileSourceAdapter()
        this.fetchAdapter = NativePlatformFetchSourceAdapter()
    }

    public init(fileAdapter: PlatformFileSourceAdapter, fetchAdapter: PlatformFetchSourceAdapter) {
        this.fileAdapter = fileAdapter
        this.fetchAdapter = fetchAdapter
    }

    public func bytesFor(sourceKind: String, sourceValue: String): Array<Byte> {
        if (sourceKind == "path") {
            return this.fileAdapter.read(sourceValue)
        }
        if (sourceKind == "url" || sourceKind == "url_like") {
            let result = this.fetchAdapter.fetch(sourceValue)
            if (!result.hasBody) {
                throw Exception("Download failed, no response body from '" + sourceValue + "'")
            }
            return result.body
        }
        sourceValue.toArray()
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
    public let chunks: Array<Array<Byte>>
    public let errorMessage: String
    public var consumed: Bool = false

    public init(sourceKind: String) {
        this.sourceKind = sourceKind
        this.sourceValue = ""
        this.chunkCount = 0
        this.contract = "stream"
        this.chunks = []
        this.errorMessage = ""
    }

    public init(sourceKind: String, sourceValue: String, chunkCount: Int64, contract: String) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.chunkCount = chunkCount
        this.contract = contract
        this.chunks = [sourceValue.toArray()]
        this.errorMessage = ""
    }

    public init(sourceKind: String, sourceValue: String, chunkCount: Int64, contract: String, chunks: Array<Array<Byte>>) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.chunkCount = chunkCount
        this.contract = contract
        this.chunks = chunks
        this.errorMessage = ""
    }

    public init(sourceKind: String, sourceValue: String, chunkCount: Int64, contract: String, chunks: Array<Array<Byte>>, errorMessage: String) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.chunkCount = chunkCount
        this.contract = contract
        this.chunks = chunks
        this.errorMessage = errorMessage
    }

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("ByteStream has already been consumed.")
        }
        this.consumed = true
    }

    public func collectBytes(): Array<Byte> {
        this.consume()
        if (!this.errorMessage.isEmpty()) {
            throw Exception(this.errorMessage)
        }
        flattenPlatformByteChunks(this.chunks)
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
    private let dataAdapter: PlatformInputFileDataAdapter

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
        this.dataAdapter = PlatformInputFileDataAdapter()
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
        this.dataAdapter = PlatformInputFileDataAdapter()
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
        requiresFetchAdapter: Bool,
        dataAdapter: PlatformInputFileDataAdapter
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
        this.dataAdapter = dataAdapter
    }

    public func summary(): String {
        this.runtime + ":" + this.sourceKind + ":" + this.contract + ":" + this.filename
    }

    public func consume(): String {
        this.stream.consume()
        this.summary()
    }

    public func collectBytes(): Array<Byte> {
        if (this.sourceKind == "path" || this.sourceKind == "url" || this.sourceKind == "url_like") {
            this.stream.consume()
            return this.dataAdapter.bytesFor(this.sourceKind, this.sourceValue)
        }
        this.stream.collectBytes()
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
    private let httpClient: PlatformHttpClient
    private let inputFileDataAdapter: PlatformInputFileDataAdapter

    public init(runtime: String) {
        this.runtime = runtime
        this.adapter = defaultAdapterForRuntime(runtime)
        this.httpClient = NativePlatformHttpClient()
        this.inputFileDataAdapter = PlatformInputFileDataAdapter()
    }

    public init(runtime: String, adapter: String) {
        this.runtime = runtime
        this.adapter = adapter
        this.httpClient = NativePlatformHttpClient()
        this.inputFileDataAdapter = PlatformInputFileDataAdapter()
    }

    public init(runtime: String, adapter: String, httpClient: PlatformHttpClient, inputFileDataAdapter: PlatformInputFileDataAdapter) {
        this.runtime = runtime
        this.adapter = adapter
        this.httpClient = httpClient
        this.inputFileDataAdapter = inputFileDataAdapter
    }

    public func supportsLongPolling(): Bool {
        true
    }

    public func request(req: PlatformHttpRequest): PlatformHttpResponse {
        this.httpClient.send(req)
    }

    public func baseFetchConfig(apiRoot: String): BaseFetchConfig {
        makeBaseFetchConfig(apiRoot)
    }

    public func itrToStream(iterator: ByteIterator): ByteStream {
        makeByteStreamFromIterator(iterator)
    }

    public func inputFileRaw(source: PlatformRawSource): PlatformRawData {
        makeInputFileRaw(this.runtime, source, this.inputFileDataAdapter)
    }

    public func logger(namespace: String): Logger {
        Logger(namespace)
    }

    public func debug(namespace: String): DebugContract {
        debugContract(this.runtime, namespace)
    }

    public func debugState(namespace: String): DebugState {
        debugState(this.runtime, namespace, EmptyDebugEnvSource())
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
    if (runtime == "cjnative" || runtime.isEmpty()) {
        return "cangjie-native"
    }
    DEFAULT_WEBHOOK_ADAPTER
}

public func platformRuntimeContracts(): Array<PlatformRuntimeContract> {
    [
        PlatformRuntimeContract("deno", "oak", "empty-fetch-config", "ReadableStream.from(asyncIterable)", "debug-skypack-deno-env"),
        PlatformRuntimeContract("node", "express", "keep-alive-agent", "Readable.from(asyncIterable)", "debug-node"),
        PlatformRuntimeContract("web", "cloudflare", "empty-fetch-config", "manual-readable-stream", "debug-skypack-web"),
        PlatformRuntimeContract("cjnative", "cangjie-native", "stdx.net.http-client", "byte-source-stream", "logger-sanitizer")
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

public func debugState(runtime: String, namespace: String, envSource: DebugEnvSource): DebugState {
    debugState(debugContract(runtime, namespace), envSource)
}

public func debugState(contract: DebugContract, envSource: DebugEnvSource): DebugState {
    if (contract.runtime == "web" || contract.implementation == "logger-sanitizer") {
        return DebugState(contract.runtime, contract.namespace, contract.envVariable, "", false, false, contract.colorAware && !envSource.noColor())
    }
    let canReadEnv = !contract.permissionAware || envSource.permissionGranted(contract.envVariable)
    let value = if (canReadEnv) { envSource.get(contract.envVariable) } else { "" }
    DebugState(
        contract.runtime,
        contract.namespace,
        contract.envVariable,
        value,
        canReadEnv,
        !value.isEmpty(),
        contract.colorAware && !envSource.noColor()
    )
}

public func defaultPlatform(): PlatformAdapter {
    PlatformAdapter("cjnative", defaultAdapterForRuntime("cjnative"))
}

public func baseFetchConfig(apiRoot: String): BaseFetchConfig {
    makeBaseFetchConfig(apiRoot)
}

public func itrToStream(iterator: ByteIterator): ByteStream {
    makeByteStreamFromIterator(iterator)
}

public func failingByteStream(sourceKind: String, sourceValue: String, chunkCount: Int64, contract: String, errorMessage: String): ByteStream {
    ByteStream(sourceKind, sourceValue, chunkCount, contract, [sourceValue.toArray()], errorMessage)
}

public func inputFileRaw(source: PlatformRawSource): PlatformRawData {
    makeInputFileRaw("cjnative", source, PlatformInputFileDataAdapter())
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
    ByteStream("iterator", iterator.label, iterator.chunkCount, "async-iterable-to-byte-stream", [iterator.label.toArray()])
}

private func makeInputFileRaw(runtime: String, source: PlatformRawSource, dataAdapter: PlatformInputFileDataAdapter): PlatformRawData {
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
        source.sourceKind == "url" || source.sourceKind == "url_like",
        dataAdapter
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

private func flattenPlatformByteChunks(chunks: Array<Array<Byte>>): Array<Byte> {
    let out = ArrayList<Byte>()
    for (chunk in chunks) {
        for (byte in chunk) {
            out.add(byte)
        }
    }
    out.toArray()
}
