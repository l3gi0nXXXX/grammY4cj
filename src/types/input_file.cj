package grammy4cj.types

import std.collection.ArrayList
import std.fs.File
import stdx.encoding.url.URL
import stdx.net.http.*
import stdx.net.tls.TlsClientConfig

import grammy4cj.platform_contract.platformInputFileRawContractFor as contractInputFileRawContractFor
import grammy4cj.platform_contract.platformInputFileRuntimeNames as contractInputFileRuntimeNames
import grammy4cj.platform_contract.platformInputFileSourceKindNames as contractInputFileSourceKindNames
import grammy4cj.platform_contract.platformNormalizeInputFileRuntime as contractNormalizeInputFileRuntime
import grammy4cj.platform_contract.platformSupportsInputFileSourceKind as contractSupportsInputFileSourceKind

public class InputFileFetchResult {
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

    public static func noBody(url: String): InputFileFetchResult {
        InputFileFetchResult(url, false, [])
    }
}

public interface InputFileFileAdapter {
    func read(path: String): Array<Byte>
}

public interface InputFileFetchAdapter {
    func fetch(url: String): InputFileFetchResult
}

public class NativeInputFileFileAdapter <: InputFileFileAdapter {
    public init() {}

    public func read(path: String): Array<Byte> {
        File.readFrom(path)
    }
}

public class NativeInputFileFetchAdapter <: InputFileFetchAdapter {
    public init() {}

    public func fetch(url: String): InputFileFetchResult {
        let client = nativeInputFileHttpClient(url)
        try {
            let response = client.get(url)
            InputFileFetchResult(url, nativeInputFileReadBody(response))
        } catch (err: Exception) {
            throw Exception("Download failed from '" + url + "': " + err.message)
        } finally {
            client.close()
        }
    }
}

private func nativeInputFileHttpClient(url: String): Client {
    let builder = ClientBuilder()
    if (url.startsWith("https://")) {
        var tlsConfig = TlsClientConfig()
        tlsConfig.domain = URL.parse(url).hostName
        builder.tlsConfig(tlsConfig)
    }
    builder.build()
}

private func nativeInputFileReadBody(response: HttpResponse): Array<Byte> {
    let out = ArrayList<Byte>()
    let buffer = Array<Byte>(1024 * 16, repeat: 0)
    while (true) {
        let length = response.body.read(buffer)
        if (length == 0) {
            break
        }
        for (byte in buffer[..length]) {
            out.add(byte)
        }
    }
    out.toArray()
}

public class InputFileRawAdapter {
    private let fileAdapter: InputFileFileAdapter
    private let fetchAdapter: InputFileFetchAdapter

    public init() {
        this.fileAdapter = NativeInputFileFileAdapter()
        this.fetchAdapter = NativeInputFileFetchAdapter()
    }

    public init(fileAdapter: InputFileFileAdapter, fetchAdapter: InputFileFetchAdapter) {
        this.fileAdapter = fileAdapter
        this.fetchAdapter = fetchAdapter
    }

    public func readPath(path: String): Array<Byte> {
        this.fileAdapter.read(path)
    }

    public func fetchUrl(url: String): InputFileFetchResult {
        this.fetchAdapter.fetch(url)
    }
}

public func defaultInputFileRawAdapter(): InputFileRawAdapter {
    InputFileRawAdapter()
}

public class InputFileSource {
    public let kind: String
    public let value: String
    public let filenameHint: String
    public let rawContract: String
    public let reusable: Bool
    public let requiresFileAdapter: Bool
    public let requiresFetchAdapter: Bool
    public let hasBody: Bool
    public let supportedOnDeno: Bool
    public let supportedOnNode: Bool
    public let supportedOnWeb: Bool
    public let supplierSourceKind: String
    public let supplierSourceValue: String
    public let supplierSourceFilename: String
    public let supplierSourceContract: String
    public let supplierSourceReusable: Bool
    public let supplierSourceRequiresFileAdapter: Bool
    public let supplierSourceRequiresFetchAdapter: Bool
    public let supplierSourceHasBody: Bool
    public let supplierErrorMessage: String

    public init(
        kind: String,
        value: String,
        filenameHint: String,
        rawContract: String,
        reusable: Bool,
        requiresFileAdapter: Bool,
        requiresFetchAdapter: Bool,
        hasBody: Bool
    ) {
        this.kind = kind
        this.value = value
        this.filenameHint = filenameHint
        this.rawContract = rawContract
        this.reusable = reusable
        this.requiresFileAdapter = requiresFileAdapter
        this.requiresFetchAdapter = requiresFetchAdapter
        this.hasBody = hasBody
        this.supportedOnDeno = true
        this.supportedOnNode = true
        this.supportedOnWeb = true
        this.supplierSourceKind = ""
        this.supplierSourceValue = ""
        this.supplierSourceFilename = ""
        this.supplierSourceContract = ""
        this.supplierSourceReusable = true
        this.supplierSourceRequiresFileAdapter = false
        this.supplierSourceRequiresFetchAdapter = false
        this.supplierSourceHasBody = true
        this.supplierErrorMessage = ""
    }

    public init(
        kind: String,
        value: String,
        filenameHint: String,
        rawContract: String,
        reusable: Bool,
        requiresFileAdapter: Bool,
        requiresFetchAdapter: Bool,
        hasBody: Bool,
        supportedOnDeno: Bool,
        supportedOnNode: Bool,
        supportedOnWeb: Bool
    ) {
        this.kind = kind
        this.value = value
        this.filenameHint = filenameHint
        this.rawContract = rawContract
        this.reusable = reusable
        this.requiresFileAdapter = requiresFileAdapter
        this.requiresFetchAdapter = requiresFetchAdapter
        this.hasBody = hasBody
        this.supportedOnDeno = supportedOnDeno
        this.supportedOnNode = supportedOnNode
        this.supportedOnWeb = supportedOnWeb
        this.supplierSourceKind = ""
        this.supplierSourceValue = ""
        this.supplierSourceFilename = ""
        this.supplierSourceContract = ""
        this.supplierSourceReusable = true
        this.supplierSourceRequiresFileAdapter = false
        this.supplierSourceRequiresFetchAdapter = false
        this.supplierSourceHasBody = true
        this.supplierErrorMessage = ""
    }

    public init(
        kind: String,
        value: String,
        filenameHint: String,
        rawContract: String,
        reusable: Bool,
        requiresFileAdapter: Bool,
        requiresFetchAdapter: Bool,
        hasBody: Bool,
        supportedOnDeno: Bool,
        supportedOnNode: Bool,
        supportedOnWeb: Bool,
        supplierSourceKind: String,
        supplierSourceValue: String,
        supplierSourceFilename: String,
        supplierSourceContract: String,
        supplierSourceReusable: Bool,
        supplierSourceRequiresFileAdapter: Bool,
        supplierSourceRequiresFetchAdapter: Bool,
        supplierSourceHasBody: Bool
    ) {
        this.kind = kind
        this.value = value
        this.filenameHint = filenameHint
        this.rawContract = rawContract
        this.reusable = reusable
        this.requiresFileAdapter = requiresFileAdapter
        this.requiresFetchAdapter = requiresFetchAdapter
        this.hasBody = hasBody
        this.supportedOnDeno = supportedOnDeno
        this.supportedOnNode = supportedOnNode
        this.supportedOnWeb = supportedOnWeb
        this.supplierSourceKind = supplierSourceKind
        this.supplierSourceValue = supplierSourceValue
        this.supplierSourceFilename = supplierSourceFilename
        this.supplierSourceContract = supplierSourceContract
        this.supplierSourceReusable = supplierSourceReusable
        this.supplierSourceRequiresFileAdapter = supplierSourceRequiresFileAdapter
        this.supplierSourceRequiresFetchAdapter = supplierSourceRequiresFetchAdapter
        this.supplierSourceHasBody = supplierSourceHasBody
        this.supplierErrorMessage = ""
    }

    public init(
        kind: String,
        value: String,
        filenameHint: String,
        rawContract: String,
        reusable: Bool,
        requiresFileAdapter: Bool,
        requiresFetchAdapter: Bool,
        hasBody: Bool,
        supportedOnDeno: Bool,
        supportedOnNode: Bool,
        supportedOnWeb: Bool,
        supplierSourceKind: String,
        supplierSourceValue: String,
        supplierSourceFilename: String,
        supplierSourceContract: String,
        supplierSourceReusable: Bool,
        supplierSourceRequiresFileAdapter: Bool,
        supplierSourceRequiresFetchAdapter: Bool,
        supplierSourceHasBody: Bool,
        supplierErrorMessage: String
    ) {
        this.kind = kind
        this.value = value
        this.filenameHint = filenameHint
        this.rawContract = rawContract
        this.reusable = reusable
        this.requiresFileAdapter = requiresFileAdapter
        this.requiresFetchAdapter = requiresFetchAdapter
        this.hasBody = hasBody
        this.supportedOnDeno = supportedOnDeno
        this.supportedOnNode = supportedOnNode
        this.supportedOnWeb = supportedOnWeb
        this.supplierSourceKind = supplierSourceKind
        this.supplierSourceValue = supplierSourceValue
        this.supplierSourceFilename = supplierSourceFilename
        this.supplierSourceContract = supplierSourceContract
        this.supplierSourceReusable = supplierSourceReusable
        this.supplierSourceRequiresFileAdapter = supplierSourceRequiresFileAdapter
        this.supplierSourceRequiresFetchAdapter = supplierSourceRequiresFetchAdapter
        this.supplierSourceHasBody = supplierSourceHasBody
        this.supplierErrorMessage = supplierErrorMessage
    }

    public static func path(path: String): InputFileSource {
        InputFileSource("path", path, inferFilename(path), "deferred-file-read", true, true, false, true, true, true, false)
    }

    public static func url(url: String): InputFileSource {
        InputFileSource("url", url, inferUrlFilename(url), "deferred-fetch", true, false, true, true, true, true, true)
    }

    public static func urlLike(url: String): InputFileSource {
        InputFileSource("url_like", url, inferUrlFilename(url), "deferred-fetch", true, false, true, true, true, true, true)
    }

    public static func fileUrl(url: String): InputFileSource {
        InputFileSource("file_url", fileUrlPath(url), inferUrlFilename(url), "file-url-read", true, true, false, true, false, true, false)
    }

    public static func bytes(label: String, filename: String): InputFileSource {
        InputFileSource("bytes", label, filename, "bytes-as-is", true, false, false, true, true, true, true)
    }

    public static func blob(label: String, filename: String): InputFileSource {
        InputFileSource("blob", label, filename, "blob-stream", true, false, false, true, true, false, true)
    }

    public static func response(label: String, filename: String, hasBody: Bool): InputFileSource {
        InputFileSource("response", label, filename, "response-body", true, false, false, hasBody, true, false, false)
    }

    public static func stream(label: String, filename: String): InputFileSource {
        InputFileSource("stream", label, filename, "stream-as-is", false, false, false, true, true, true, true)
    }

    public static func iterable(label: String, filename: String): InputFileSource {
        InputFileSource("iterable", label, filename, "iterator-as-is", false, false, false, true, true, true, true)
    }

    public static func asyncIterable(label: String, filename: String): InputFileSource {
        InputFileSource("async_iterable", label, filename, "async-iterator-as-is", false, false, false, true, true, true, true)
    }

    public static func supplier(label: String, filename: String): InputFileSource {
        InputFileSource("supplier", label, filename, "supplier-deferred", true, false, false, true, true, true, false)
    }

    public static func supplierFailure(label: String, filename: String, errorMessage: String): InputFileSource {
        InputFileSource(
            "supplier",
            label,
            filename,
            "supplier-deferred",
            true,
            false,
            false,
            true,
            true,
            true,
            false,
            "",
            "",
            "",
            "",
            true,
            false,
            false,
            true,
            errorMessage
        )
    }

    public static func supplierSource(label: String, source: InputFileSource): InputFileSource {
        let filename = if (source.filenameHint.isEmpty()) { label } else { source.filenameHint }
        InputFileSource(
            "supplier",
            label,
            filename,
            "supplier-deferred",
            true,
            source.requiresFileAdapter,
            source.requiresFetchAdapter,
            source.hasBody,
            true,
            true,
            false,
            source.kind,
            source.value,
            source.filenameHint,
            source.rawContract,
            source.reusable,
            source.requiresFileAdapter,
            source.requiresFetchAdapter,
            source.hasBody
        )
    }
}

public class InputFileRaw {
    public let sourceKind: String
    public let sourceValue: String
    public let filename: String
    public let contract: String
    public let reusable: Bool
    public let requiresFileAdapter: Bool
    public let requiresFetchAdapter: Bool
    public let runtime: String
    public let rawSourceKind: String
    public let platformContract: String
    public let originalSourceKind: String
    public let supplierLabel: String
    public let singleUseBoundary: Bool
    public let body: InputFileRawBody
    public let isFakeContract: Bool
    public let rawKind: String

    public init(
        sourceKind: String,
        sourceValue: String,
        filename: String,
        contract: String,
        reusable: Bool,
        requiresFileAdapter: Bool,
        requiresFetchAdapter: Bool
    ) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.contract = contract
        this.reusable = reusable
        this.requiresFileAdapter = requiresFileAdapter
        this.requiresFetchAdapter = requiresFetchAdapter
        this.runtime = "cjnative"
        this.rawSourceKind = sourceKind
        this.platformContract = contract
        this.originalSourceKind = sourceKind
        this.supplierLabel = ""
        this.singleUseBoundary = !reusable
        this.body = InputFileRawBody(sourceKind, sourceValue, filename, contract, rawChunkCount(sourceKind, sourceValue), reusable, defaultInputFileRawAdapter())
        this.isFakeContract = false
        this.rawKind = sourceKind
    }

    public init(
        sourceKind: String,
        sourceValue: String,
        filename: String,
        contract: String,
        reusable: Bool,
        requiresFileAdapter: Bool,
        requiresFetchAdapter: Bool,
        runtime: String,
        rawSourceKind: String,
        platformContract: String,
        originalSourceKind: String,
        supplierLabel: String
    ) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.contract = contract
        this.reusable = reusable
        this.requiresFileAdapter = requiresFileAdapter
        this.requiresFetchAdapter = requiresFetchAdapter
        this.runtime = runtime
        this.rawSourceKind = rawSourceKind
        this.platformContract = platformContract
        this.originalSourceKind = originalSourceKind
        this.supplierLabel = supplierLabel
        this.singleUseBoundary = !reusable
        this.body = InputFileRawBody(rawSourceKind, sourceValue, filename, platformContract, rawChunkCount(rawSourceKind, sourceValue), reusable, defaultInputFileRawAdapter())
        this.isFakeContract = false
        this.rawKind = rawSourceKind
    }

    public init(
        sourceKind: String,
        sourceValue: String,
        filename: String,
        contract: String,
        reusable: Bool,
        requiresFileAdapter: Bool,
        requiresFetchAdapter: Bool,
        runtime: String,
        rawSourceKind: String,
        platformContract: String,
        originalSourceKind: String,
        supplierLabel: String,
        adapter: InputFileRawAdapter
    ) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.contract = contract
        this.reusable = reusable
        this.requiresFileAdapter = requiresFileAdapter
        this.requiresFetchAdapter = requiresFetchAdapter
        this.runtime = runtime
        this.rawSourceKind = rawSourceKind
        this.platformContract = platformContract
        this.originalSourceKind = originalSourceKind
        this.supplierLabel = supplierLabel
        this.singleUseBoundary = !reusable
        this.body = InputFileRawBody(rawSourceKind, sourceValue, filename, platformContract, rawChunkCount(rawSourceKind, sourceValue), reusable, adapter)
        this.isFakeContract = false
        this.rawKind = rawSourceKind
    }

    public func summary(): String {
        this.sourceKind + ":" + this.contract + ":" + this.filename
    }

    public func platformSummary(): String {
        this.runtime + ":" + this.rawSourceKind + ":" + this.platformContract + ":" + this.filename
    }

    public func consume(): String {
        this.body.consume()
        this.platformSummary()
    }

    public func rawConsumed(): Bool {
        this.body.consumed
    }

    public func collectBytes(): Array<Byte> {
        this.body.collectBytes()
    }

    public func collectChunks(): Array<Array<Byte>> {
        this.body.collectChunks()
    }

    public func collectString(): String {
        String.fromUtf8(this.collectBytes())
    }

    public func previewString(): String {
        this.body.previewString()
    }
}

public type InputFileRawData = InputFileRaw

public class InputFileRawBody {
    public let sourceKind: String
    public let sourceValue: String
    public let filename: String
    public let contract: String
    public let chunkCount: Int64
    public let reusableSource: Bool
    public let chunks: Array<Array<Byte>>
    private let adapter: InputFileRawAdapter
    public var consumed: Bool = false

    public init(sourceKind: String, sourceValue: String, filename: String, contract: String, chunkCount: Int64, reusableSource: Bool) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.contract = contract
        this.chunkCount = chunkCount
        this.reusableSource = reusableSource
        this.chunks = defaultRawChunks(sourceKind, sourceValue)
        this.adapter = defaultInputFileRawAdapter()
    }

    public init(sourceKind: String, sourceValue: String, filename: String, contract: String, chunkCount: Int64, reusableSource: Bool, adapter: InputFileRawAdapter) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
        this.contract = contract
        this.chunkCount = chunkCount
        this.reusableSource = reusableSource
        this.chunks = defaultRawChunks(sourceKind, sourceValue)
        this.adapter = adapter
    }

    public func consume(): Unit {
        if (this.consumed && !this.reusableSource) {
            throw Exception("Cannot reuse InputFile data source!")
        }
        if (!this.reusableSource) {
            this.consumed = true
        }
    }

    public func summary(): String {
        this.sourceKind + ":" + this.contract + ":" + this.filename + ":chunks=" + this.chunkCount.toString()
    }

    public func collectBytes(): Array<Byte> {
        this.consume()
        if (this.sourceKind == "stream_error" || this.sourceKind == "stream_error_after") {
            throw Exception(this.sourceValue)
        }
        if (this.sourceKind == "path" || this.sourceKind == "file_url") {
            return this.adapter.readPath(this.sourceValue)
        }
        if (this.sourceKind == "url" || this.sourceKind == "url_like") {
            let result = this.adapter.fetchUrl(this.sourceValue)
            if (!result.hasBody) {
                throw Exception("Download failed, no response body from '" + this.sourceValue + "'")
            }
            return result.body
        }
        flattenByteChunks(this.chunks)
    }

    public func collectChunks(): Array<Array<Byte>> {
        this.consume()
        if (this.sourceKind == "stream_error" || this.sourceKind == "stream_error_after") {
            throw Exception(this.sourceValue)
        }
        if (this.sourceKind == "path" || this.sourceKind == "file_url") {
            return [this.adapter.readPath(this.sourceValue)]
        }
        if (this.sourceKind == "url" || this.sourceKind == "url_like") {
            let result = this.adapter.fetchUrl(this.sourceValue)
            if (!result.hasBody) {
                throw Exception("Download failed, no response body from '" + this.sourceValue + "'")
            }
            return [result.body]
        }
        this.chunks
    }

    public func previewString(): String {
        if (this.sourceKind == "path" || this.sourceKind == "file_url" || this.sourceKind == "url" || this.sourceKind == "url_like") {
            return ""
        }
        String.fromUtf8(flattenByteChunks(this.chunks))
    }
}

public class InputFile {
    public let source: InputFileSource
    public let sourceKind: String
    public let sourceValue: String
    public let filename: String
    public var consumed: Bool = false

    public init(sourceKind: String) {
        let source = legacySource(sourceKind, "", "")
        this.source = source
        this.sourceKind = source.kind
        this.sourceValue = source.value
        this.filename = source.filenameHint
    }

    public init(sourceKind: String, filename: String) {
        let source = legacySource(sourceKind, "", filename)
        this.source = source
        this.sourceKind = source.kind
        this.sourceValue = source.value
        this.filename = if (filename.isEmpty()) { source.filenameHint } else { filename }
    }

    public init(sourceKind: String, sourceValue: String, filename: String) {
        let source = legacySource(sourceKind, sourceValue, filename)
        this.source = source
        this.sourceKind = source.kind
        this.sourceValue = source.value
        this.filename = if (filename.isEmpty()) { source.filenameHint } else { filename }
    }

    public init(source: InputFileSource) {
        this.source = source
        this.sourceKind = source.kind
        this.sourceValue = source.value
        this.filename = source.filenameHint
    }

    public init(source: InputFileSource, filename: String) {
        this.source = source
        this.sourceKind = source.kind
        this.sourceValue = source.value
        this.filename = if (filename.isEmpty()) { source.filenameHint } else { filename }
    }

    public static func fromPath(path: String): InputFile {
        InputFile(InputFileSource.path(path))
    }

    public static func fromUrl(url: String): InputFile {
        InputFile(InputFileSource.url(url))
    }

    public static func fromUrlLike(url: String): InputFile {
        InputFile(InputFileSource.urlLike(url))
    }

    public static func fromFileUrl(url: String): InputFile {
        InputFile(InputFileSource.fileUrl(url))
    }

    public static func fromBytes(bytesLabel: String, filename: String): InputFile {
        InputFile(InputFileSource.bytes(bytesLabel, filename))
    }

    public static func fromBlob(blobLabel: String, filename: String): InputFile {
        InputFile(InputFileSource.blob(blobLabel, filename))
    }

    public static func fromResponse(responseLabel: String, filename: String): InputFile {
        InputFile(InputFileSource.response(responseLabel, filename, true))
    }

    public static func fromResponse(responseLabel: String, filename: String, hasBody: Bool): InputFile {
        InputFile(InputFileSource.response(responseLabel, filename, hasBody))
    }

    public static func fromStream(streamLabel: String, filename: String): InputFile {
        InputFile(InputFileSource.stream(streamLabel, filename))
    }

    public static func fromIterable(iterableLabel: String, filename: String): InputFile {
        InputFile(InputFileSource.iterable(iterableLabel, filename))
    }

    public static func fromAsyncIterable(iterableLabel: String, filename: String): InputFile {
        InputFile(InputFileSource.asyncIterable(iterableLabel, filename))
    }

    public static func fromSupplier(supplierLabel: String, filename: String): InputFile {
        InputFile(InputFileSource.supplier(supplierLabel, filename))
    }

    public static func fromSupplier(supplierLabel: String, source: InputFileSource): InputFile {
        InputFile(InputFileSource.supplierSource(supplierLabel, source))
    }

    public static func fromSupplierFailure(supplierLabel: String, filename: String, errorMessage: String): InputFile {
        InputFile(InputFileSource.supplierFailure(supplierLabel, filename, errorMessage))
    }

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("Cannot reuse InputFile data source!")
        }
        this.consumed = true
    }

    public func toRaw(): InputFileRaw {
        this.toRaw("deno")
    }

    public func toRaw(adapter: InputFileRawAdapter): InputFileRaw {
        this.toRaw("deno", adapter)
    }

    public func toRaw(runtime: String): InputFileRaw {
        this.toRaw(runtime, defaultInputFileRawAdapter())
    }

    public func toRaw(runtime: String, adapter: InputFileRawAdapter): InputFileRaw {
        if (this.consumed) {
            throw Exception("Cannot reuse InputFile data source!")
        }
        let normalizedRuntime = normalizeInputFileRuntime(runtime)
        if (!inputFileSourceSupportedOnRuntime(this.source.kind, normalizedRuntime)) {
            throw Exception("InputFile source kind '" + this.source.kind + "' is not supported on " + normalizedRuntime)
        }
        if (this.source.kind == "supplier") {
            if (!this.source.supplierErrorMessage.isEmpty()) {
                throw Exception(this.source.supplierErrorMessage)
            }
            if (!this.source.supplierSourceKind.isEmpty()) {
                if (!inputFileSourceSupportedOnRuntime(this.source.supplierSourceKind, normalizedRuntime)) {
                    throw Exception("InputFile supplier source kind '" + this.source.supplierSourceKind + "' is not supported on " + normalizedRuntime)
                }
                if (!this.source.supplierSourceHasBody) {
                    throw Exception("No response body!")
                }
                return InputFileRaw(
                    this.source.kind,
                    this.source.supplierSourceValue,
                    this.filename,
                    this.source.rawContract,
                    this.source.supplierSourceReusable,
                    this.source.supplierSourceRequiresFileAdapter,
                    this.source.supplierSourceRequiresFetchAdapter,
                    normalizedRuntime,
                    this.source.supplierSourceKind,
                    inputFilePlatformContract(this.source.supplierSourceKind, normalizedRuntime, this.source.supplierSourceContract),
                    this.source.kind,
                    this.source.value,
                    adapter
                )
            }
        }
        if (!this.source.hasBody) {
            throw Exception("No response body!")
        }
        let raw = InputFileRaw(
            this.sourceKind,
            this.sourceValue,
            this.filename,
            this.source.rawContract,
            this.source.reusable,
            this.source.requiresFileAdapter,
            this.source.requiresFetchAdapter,
            normalizedRuntime,
            this.sourceKind,
            inputFilePlatformContract(this.sourceKind, normalizedRuntime, this.source.rawContract),
            this.sourceKind,
            "",
            adapter
        )
        if (!this.source.reusable) {
            this.consumed = true
        }
        raw
    }

    public func toJSON(): String {
        throw Exception("InputFile instances must be sent via grammY")
    }
}

public func inferFilename(source: String): String {
    if (looksLikeRemoteUrl(source)) {
        return inferUrlFilename(source)
    }
    basename(source)
}

public func inferUrlFilename(url: String): String {
    let cleaned = stripQueryAndHash(url)
    let protocolParts = cleaned.split("://")
    let rest = if (protocolParts.size > 1) { protocolParts[1] } else { cleaned }
    let segments = rest.split("/")
    if (segments.size == 0) {
        return ""
    }
    let host = segments[0]
    var i = segments.size
    while (i > 1) {
        i -= 1
        let segment = segments[i]
        if (!segment.isEmpty()) {
            return segment
        }
    }
    host
}

public func looksLikeRemoteUrl(source: String): Bool {
    source.startsWith("http:") || source.startsWith("https:")
}

public func inputFilePathLooksLikeRemoteUrlWarning(source: String): String {
    if (looksLikeRemoteUrl(source)) {
        return "InputFile received the local file path '" + source + "' that looks like a URL. Is this a mistake?"
    }
    ""
}

public func inputFileRuntimeNames(): Array<String> {
    contractInputFileRuntimeNames()
}

public func inputFileSourceKindNames(): Array<String> {
    contractInputFileSourceKindNames()
}

public func inputFileSourceKindCount(): Int64 {
    11
}

public class InputFileSourceMatrixRow {
    public let sourceKind: String
    public let upstreamDeno: Bool
    public let upstreamNode: Bool
    public let upstreamWeb: Bool
    public let rawContract: String
    public let filenameInference: String
    public let singleUse: Bool

    public init(
        sourceKind: String,
        upstreamDeno: Bool,
        upstreamNode: Bool,
        upstreamWeb: Bool,
        rawContract: String,
        filenameInference: String,
        singleUse: Bool
    ) {
        this.sourceKind = sourceKind
        this.upstreamDeno = upstreamDeno
        this.upstreamNode = upstreamNode
        this.upstreamWeb = upstreamWeb
        this.rawContract = rawContract
        this.filenameInference = filenameInference
        this.singleUse = singleUse
    }
}

public func inputFileSourceMatrix(): Array<InputFileSourceMatrixRow> {
    [
        InputFileSourceMatrixRow("path", true, true, false, "deferred-file-read", "basename(path)", false),
        InputFileSourceMatrixRow("url", true, true, true, "deferred-fetch", "basename(pathname) or hostname", false),
        InputFileSourceMatrixRow("url_like", true, true, true, "deferred-fetch", "basename(url)", false),
        InputFileSourceMatrixRow("file_url", false, true, false, "file-url-read", "basename(pathname)", false),
        InputFileSourceMatrixRow("bytes", true, true, true, "bytes-as-is", "explicit filename", false),
        InputFileSourceMatrixRow("blob", true, false, true, "blob-stream", "explicit filename", false),
        InputFileSourceMatrixRow("response", true, false, false, "response-body", "explicit filename", false),
        InputFileSourceMatrixRow("stream", true, true, true, "stream-as-is", "explicit filename", true),
        InputFileSourceMatrixRow("iterable", true, true, true, "iterator-as-is", "explicit filename", true),
        InputFileSourceMatrixRow("async_iterable", true, true, true, "async-iterator-as-is", "explicit filename", true),
        InputFileSourceMatrixRow("supplier", true, true, false, "supplier-deferred", "supplied source or explicit filename", false)
    ]
}

public func inputFileSourceMatrixCount(): Int64 {
    11
}

public func inputFileSourceMatrixFor(sourceKind: String): InputFileSourceMatrixRow {
    for (row in inputFileSourceMatrix()) {
        if (row.sourceKind == sourceKind) {
            return row
        }
    }
    InputFileSourceMatrixRow(sourceKind, false, false, false, "", "", false)
}

public func inputFileSourceSupportedOnRuntime(sourceKind: String, runtime: String): Bool {
    contractSupportsInputFileSourceKind(sourceKind, runtime)
}

public func inputFilePlatformContract(sourceKind: String, runtime: String, fallbackContract: String): String {
    contractInputFileRawContractFor(sourceKind, runtime, fallbackContract)
}

private func normalizeInputFileRuntime(runtime: String): String {
    contractNormalizeInputFileRuntime(runtime)
}

private func inputFileSourceKindExists(sourceKind: String): Bool {
    for (kind in inputFileSourceKindNames()) {
        if (kind == sourceKind) {
            return true
        }
    }
    false
}

private func rawChunkCount(sourceKind: String, sourceValue: String): Int64 {
    if (sourceKind == "stream" || sourceKind == "iterable" || sourceKind == "async_iterable") {
        return defaultRawChunks(sourceKind, sourceValue).size
    }
    1
}

private func legacySource(sourceKind: String, sourceValue: String, filename: String): InputFileSource {
    if (sourceKind == "path") {
        return InputFileSource.path(sourceValue)
    }
    if (sourceKind == "url") {
        return InputFileSource.url(sourceValue)
    }
    if (sourceKind == "url_like") {
        return InputFileSource.urlLike(sourceValue)
    }
    if (sourceKind == "file_url") {
        return InputFileSource.fileUrl(sourceValue)
    }
    if (sourceKind == "bytes") {
        return InputFileSource.bytes(sourceValue, filename)
    }
    if (sourceKind == "blob") {
        return InputFileSource.blob(sourceValue, filename)
    }
    if (sourceKind == "response") {
        return InputFileSource.response(sourceValue, filename, true)
    }
    if (sourceKind == "stream") {
        return InputFileSource.stream(sourceValue, filename)
    }
    if (sourceKind == "iterable") {
        return InputFileSource.iterable(sourceValue, filename)
    }
    if (sourceKind == "async_iterable") {
        return InputFileSource.asyncIterable(sourceValue, filename)
    }
    if (sourceKind == "supplier") {
        return InputFileSource.supplier(sourceValue, filename)
    }
    InputFileSource(sourceKind, sourceValue, filename, sourceKind + "-raw", true, false, false, true)
}

private func basename(path: String): String {
    let cleaned = stripQueryAndHash(path)
    let parts = cleaned.split("/")
    var i = parts.size
    while (i > 0) {
        i -= 1
        let part = parts[i]
        if (!part.isEmpty()) {
            return part
        }
    }
    ""
}

private func stripQueryAndHash(value: String): String {
    let withoutHash = value.split("#")[0]
    withoutHash.split("?")[0]
}

private func fileUrlPath(url: String): String {
    if (!url.startsWith("file://")) {
        return url
    }
    let rest = url[7..]
    if (rest.startsWith("localhost/")) {
        return "/" + rest[10..]
    }
    if (rest.startsWith("/")) {
        return rest
    }
    let slash = rest.indexOf("/")
    if (slash.isSome()) {
        return rest[slash.getOrThrow()..]
    }
    rest
}

private func defaultRawChunks(sourceKind: String, sourceValue: String): Array<Array<Byte>> {
    if (sourceKind == "stream" || sourceKind == "iterable" || sourceKind == "async_iterable") {
        return parseChunkLabel(sourceValue)
    }
    [sourceValue.toArray()]
}

private func parseChunkLabel(sourceValue: String): Array<Array<Byte>> {
    let chunks = ArrayList<Array<Byte>>()
    for (part in sourceValue.split("|")) {
        chunks.add(part.toArray())
    }
    if (chunks.size == 0) {
        chunks.add(sourceValue.toArray())
    }
    chunks.toArray()
}

private func flattenByteChunks(chunks: Array<Array<Byte>>): Array<Byte> {
    let out = ArrayList<Byte>()
    for (chunk in chunks) {
        for (byte in chunk) {
            out.add(byte)
        }
    }
    out.toArray()
}
