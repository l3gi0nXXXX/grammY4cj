package grammy4cj.types

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

public class InputFileRawData {
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
    }

    public func summary(): String {
        this.sourceKind + ":" + this.contract + ":" + this.filename
    }

    public func platformSummary(): String {
        this.runtime + ":" + this.rawSourceKind + ":" + this.platformContract + ":" + this.filename
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

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("Cannot reuse InputFile data source!")
        }
        this.consumed = true
    }

    public func toRaw(): InputFileRawData {
        this.toRaw("deno")
    }

    public func toRaw(runtime: String): InputFileRawData {
        if (this.consumed) {
            throw Exception("Cannot reuse InputFile data source!")
        }
        let normalizedRuntime = normalizeInputFileRuntime(runtime)
        if (!inputFileSourceSupportedOnRuntime(this.source.kind, normalizedRuntime)) {
            throw Exception("InputFile source kind '" + this.source.kind + "' is not supported on " + normalizedRuntime)
        }
        if (this.source.kind == "supplier" && !this.source.supplierSourceKind.isEmpty()) {
            if (!inputFileSourceSupportedOnRuntime(this.source.supplierSourceKind, normalizedRuntime)) {
                throw Exception("InputFile supplier source kind '" + this.source.supplierSourceKind + "' is not supported on " + normalizedRuntime)
            }
            if (!this.source.supplierSourceHasBody) {
                throw Exception("No response body!")
            }
            return InputFileRawData(
                this.source.kind,
                this.source.value,
                this.filename,
                this.source.rawContract,
                this.source.supplierSourceReusable,
                this.source.supplierSourceRequiresFileAdapter,
                this.source.supplierSourceRequiresFetchAdapter,
                runtime,
                this.source.supplierSourceKind,
                inputFilePlatformContract(this.source.supplierSourceKind, normalizedRuntime, this.source.supplierSourceContract),
                this.source.kind,
                this.source.value
            )
        }
        if (!this.source.hasBody) {
            throw Exception("No response body!")
        }
        let raw = InputFileRawData(
            this.sourceKind,
            this.sourceValue,
            this.filename,
            this.source.rawContract,
            this.source.reusable,
            this.source.requiresFileAdapter,
            this.source.requiresFetchAdapter,
            runtime,
            this.sourceKind,
            inputFilePlatformContract(this.sourceKind, normalizedRuntime, this.source.rawContract),
            this.sourceKind,
            ""
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

public func inputFileRuntimeNames(): Array<String> {
    ["deno", "node", "web"]
}

public func inputFileSourceKindNames(): Array<String> {
    ["path", "url", "url_like", "bytes", "blob", "response", "stream", "iterable", "async_iterable", "supplier"]
}

public func inputFileSourceKindCount(): Int64 {
    10
}

public func inputFileSourceSupportedOnRuntime(sourceKind: String, runtime: String): Bool {
    let normalizedRuntime = normalizeInputFileRuntime(runtime)
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
    inputFileSourceKindExists(sourceKind)
}

public func inputFilePlatformContract(sourceKind: String, runtime: String, fallbackContract: String): String {
    let normalizedRuntime = normalizeInputFileRuntime(runtime)
    if (sourceKind == "path") {
        if (normalizedRuntime == "deno") {
            return "deno-open-file-async-iterator"
        }
        if (normalizedRuntime == "node") {
            return "node-create-read-stream"
        }
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
    fallbackContract
}

private func normalizeInputFileRuntime(runtime: String): String {
    if (runtime == "deno" || runtime == "node" || runtime == "web") {
        return runtime
    }
    if (runtime.isEmpty() || runtime == "cjnative") {
        return "node"
    }
    runtime
}

private func inputFileSourceKindExists(sourceKind: String): Bool {
    for (kind in inputFileSourceKindNames()) {
        if (kind == sourceKind) {
            return true
        }
    }
    false
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
