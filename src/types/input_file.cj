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
    }

    public static func path(path: String): InputFileSource {
        InputFileSource("path", path, inferFilename(path), "deferred-file-read", true, true, false, true)
    }

    public static func url(url: String): InputFileSource {
        InputFileSource("url", url, inferUrlFilename(url), "deferred-fetch", true, false, true, true)
    }

    public static func urlLike(url: String): InputFileSource {
        InputFileSource("url_like", url, inferUrlFilename(url), "deferred-fetch", true, false, true, true)
    }

    public static func bytes(label: String, filename: String): InputFileSource {
        InputFileSource("bytes", label, filename, "bytes-as-is", true, false, false, true)
    }

    public static func blob(label: String, filename: String): InputFileSource {
        InputFileSource("blob", label, filename, "blob-stream", true, false, false, true)
    }

    public static func response(label: String, filename: String, hasBody: Bool): InputFileSource {
        InputFileSource("response", label, filename, "response-body", false, false, false, hasBody)
    }

    public static func stream(label: String, filename: String): InputFileSource {
        InputFileSource("stream", label, filename, "stream-as-is", false, false, false, true)
    }

    public static func iterable(label: String, filename: String): InputFileSource {
        InputFileSource("iterable", label, filename, "iterator-as-is", false, false, false, true)
    }

    public static func asyncIterable(label: String, filename: String): InputFileSource {
        InputFileSource("async_iterable", label, filename, "async-iterator-as-is", false, false, false, true)
    }

    public static func supplier(label: String, filename: String): InputFileSource {
        InputFileSource("supplier", label, filename, "supplier-deferred", true, false, false, true)
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
    }

    public func summary(): String {
        this.sourceKind + ":" + this.contract + ":" + this.filename
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

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("Cannot reuse InputFile data source!")
        }
        this.consumed = true
    }

    public func toRaw(): InputFileRawData {
        if (this.consumed) {
            throw Exception("Cannot reuse InputFile data source!")
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
            this.source.requiresFetchAdapter
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
