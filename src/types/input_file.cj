package grammy4cj.types

public class InputFile {
    public let sourceKind: String
    public let sourceValue: String
    public let filename: String
    public var consumed: Bool = false

    public init(sourceKind: String) {
        this.sourceKind = sourceKind
        this.sourceValue = ""
        this.filename = ""
    }

    public init(sourceKind: String, filename: String) {
        this.sourceKind = sourceKind
        this.sourceValue = ""
        this.filename = filename
    }

    public init(sourceKind: String, sourceValue: String, filename: String) {
        this.sourceKind = sourceKind
        this.sourceValue = sourceValue
        this.filename = filename
    }

    public static func fromPath(path: String): InputFile {
        InputFile("path", path, inferFilename(path))
    }

    public static func fromUrl(url: String): InputFile {
        InputFile("url", url, inferFilename(url))
    }

    public static func fromBytes(bytesLabel: String, filename: String): InputFile {
        InputFile("bytes", bytesLabel, filename)
    }

    public static func fromStream(streamLabel: String, filename: String): InputFile {
        InputFile("stream", streamLabel, filename)
    }

    public static func fromSupplier(supplierLabel: String, filename: String): InputFile {
        InputFile("supplier", supplierLabel, filename)
    }

    public func consume(): Unit {
        if (this.consumed) {
            throw Exception("InputFile source has already been consumed.")
        }
        this.consumed = true
    }

    public func toJSON(): String {
        throw Exception("InputFile instances must be sent via grammY4cj multipart payload handling.")
    }
}

public func inferFilename(source: String): String {
    let parts = source.split("/")
    if (parts.size == 0) {
        return ""
    }
    parts[parts.size - 1]
}
