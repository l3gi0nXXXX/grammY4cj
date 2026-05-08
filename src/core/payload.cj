package grammy4cj.core

import std.collection.ArrayList
import std.time.DateTime

import grammy4cj.types.InputFile
import grammy4cj.types.InputFileRawAdapter
import grammy4cj.types.InputFileRawData

public type MultipartStreamErrorCallback = (Exception) -> Unit

public class PayloadField {
    public let key: String
    public let value: String
    public let isNull: Bool
    public let isInputFile: Bool
    public let filename: String
    public let sourceKind: String
    public let valueKind: String
    public let children: ArrayList<PayloadField> = ArrayList<PayloadField>()
    public var inputFile: Option<InputFile> = None<InputFile>

    public init(key: String, value: String) {
        this.key = key
        this.value = value
        this.isNull = false
        this.isInputFile = false
        this.filename = ""
        this.sourceKind = ""
        this.valueKind = "string"
    }

    public init(key: String, value: String, valueKind: String) {
        this.key = key
        this.value = value
        this.isNull = valueKind == "null"
        this.isInputFile = valueKind == "file"
        this.filename = ""
        this.sourceKind = ""
        this.valueKind = valueKind
    }

    public init(key: String, value: String, isNull: Bool, isInputFile: Bool, filename: String, sourceKind: String) {
        this.key = key
        this.value = value
        this.isNull = isNull
        this.isInputFile = isInputFile
        this.filename = filename
        this.sourceKind = sourceKind
        this.valueKind = if (isNull) {
            "null"
        } else if (isInputFile) {
            "file"
        } else {
            "string"
        }
    }

    public init(key: String, value: String, isNull: Bool, isInputFile: Bool, filename: String, sourceKind: String, valueKind: String) {
        this.key = key
        this.value = value
        this.isNull = isNull
        this.isInputFile = isInputFile
        this.filename = filename
        this.sourceKind = sourceKind
        this.valueKind = valueKind
    }

    public static func object(key: String): PayloadField {
        PayloadField(key, "", false, false, "", "", "object")
    }

    public static func array(key: String): PayloadField {
        PayloadField(key, "", false, false, "", "", "array")
    }

    public static func stringItem(value: String): PayloadField {
        PayloadField("", value)
    }

    public static func numberItem(value: Int64): PayloadField {
        PayloadField("", value.toString(), "number")
    }

    public static func floatItem(value: Float64): PayloadField {
        PayloadField("", value.toString(), "number")
    }

    public static func boolItem(value: Bool): PayloadField {
        PayloadField("", if (value) { "true" } else { "false" }, "bool")
    }

    public static func nullItem(): PayloadField {
        PayloadField("", "", true, false, "", "", "null")
    }

    public static func undefinedItem(): PayloadField {
        PayloadField("", "", false, false, "", "", "undefined")
    }

    public static func fileItem(file: InputFile): PayloadField {
        let field = PayloadField("", file.sourceValue, false, true, file.filename, file.sourceKind, "file")
        field.inputFile = Some(file)
        field
    }

    public func addValue(key: String, value: String): PayloadField {
        this.children.add(PayloadField(key, value))
        this
    }

    public func addRawJson(key: String, value: String): PayloadField {
        this.children.add(PayloadField(key, value, "raw"))
        this
    }

    public func addInt(key: String, value: Int64): PayloadField {
        this.children.add(PayloadField(key, value.toString(), "number"))
        this
    }

    public func addFloat(key: String, value: Float64): PayloadField {
        this.children.add(PayloadField(key, value.toString(), "number"))
        this
    }

    public func addBool(key: String, value: Bool): PayloadField {
        this.children.add(PayloadField(key, if (value) { "true" } else { "false" }, "bool"))
        this
    }

    public func addNull(key: String): PayloadField {
        this.children.add(PayloadField(key, "", true, false, "", "", "null"))
        this
    }

    public func addUndefined(key: String): PayloadField {
        this.children.add(PayloadField(key, "", false, false, "", "", "undefined"))
        this
    }

    public func addNone(key: String): PayloadField {
        this.addUndefined(key)
    }

    public func addFile(key: String, file: InputFile): PayloadField {
        let field = PayloadField(key, file.sourceValue, false, true, file.filename, file.sourceKind, "file")
        field.inputFile = Some(file)
        this.children.add(field)
        this
    }

    public func addObject(key: String): PayloadField {
        let child = PayloadField.object(key)
        this.children.add(child)
        child
    }

    public func addArray(key: String): PayloadField {
        let child = PayloadField.array(key)
        this.children.add(child)
        child
    }

    public func addStringItem(value: String): PayloadField {
        this.children.add(PayloadField.stringItem(value))
        this
    }

    public func addNumberItem(value: Int64): PayloadField {
        this.children.add(PayloadField.numberItem(value))
        this
    }

    public func addFloatItem(value: Float64): PayloadField {
        this.children.add(PayloadField.floatItem(value))
        this
    }

    public func addBoolItem(value: Bool): PayloadField {
        this.children.add(PayloadField.boolItem(value))
        this
    }

    public func addNullItem(): PayloadField {
        this.children.add(PayloadField.nullItem())
        this
    }

    public func addUndefinedItem(): PayloadField {
        this.children.add(PayloadField.undefinedItem())
        this
    }

    public func addNoneItem(): PayloadField {
        this.addUndefinedItem()
    }

    public func addFileItem(file: InputFile): PayloadField {
        this.children.add(PayloadField.fileItem(file))
        this
    }

    public func addObjectItem(): PayloadField {
        let child = PayloadField.object("")
        this.children.add(child)
        child
    }
}

public class MultipartChunk {
    public let kind: String
    public let data: String
    public let bytes: Array<Byte>
    public let sourceKind: String
    public let raw: Option<InputFileRawData>
    public let inputFile: Option<InputFile>
    public let rawAdapter: Option<InputFileRawAdapter>

    public init(kind: String, data: String, sourceKind: String) {
        this.kind = kind
        this.data = data
        this.bytes = data.toArray()
        this.sourceKind = sourceKind
        this.raw = None<InputFileRawData>
        this.inputFile = None<InputFile>
        this.rawAdapter = None<InputFileRawAdapter>
    }

    public init(kind: String, bytes: Array<Byte>, sourceKind: String) {
        this.kind = kind
        this.data = String.fromUtf8(bytes)
        this.bytes = bytes
        this.sourceKind = sourceKind
        this.raw = None<InputFileRawData>
        this.inputFile = None<InputFile>
        this.rawAdapter = None<InputFileRawAdapter>
    }

    public init(kind: String, raw: InputFileRawData) {
        this.kind = kind
        this.data = raw.previewString()
        this.bytes = []
        this.sourceKind = raw.rawSourceKind
        this.raw = Some(raw)
        this.inputFile = None<InputFile>
        this.rawAdapter = None<InputFileRawAdapter>
    }

    public init(kind: String, file: InputFile, adapter: InputFileRawAdapter) {
        this.kind = kind
        this.data = if (file.source.reusable && !file.source.requiresFileAdapter && !file.source.requiresFetchAdapter) {
            file.sourceValue
        } else {
            ""
        }
        this.bytes = []
        this.sourceKind = file.sourceKind
        this.raw = None<InputFileRawData>
        this.inputFile = Some(file)
        this.rawAdapter = Some(adapter)
    }
}

public class MultipartByteStream {
    public let chunks: ArrayList<MultipartChunk> = ArrayList<MultipartChunk>()
    public var hasError: Bool = false
    public var errorMessage: String = ""
    public var errorAfterMillis: Int64 = 0
    private let onError: MultipartStreamErrorCallback

    public init() {
        this.onError = ignoreMultipartStreamError
    }

    public init(onError: MultipartStreamErrorCallback) {
        this.onError = onError
    }

    public func addText(data: String): MultipartByteStream {
        this.chunks.add(MultipartChunk("text", data, ""))
        this
    }

    public func addBytes(sourceKind: String, data: Array<Byte>): MultipartByteStream {
        this.chunks.add(MultipartChunk("file", data, sourceKind))
        this
    }

    public func addFile(sourceKind: String, data: String): MultipartByteStream {
        this.chunks.add(MultipartChunk("file", data, sourceKind))
        this
    }

    public func addRaw(raw: InputFileRawData): MultipartByteStream {
        this.chunks.add(MultipartChunk("file", raw))
        this
    }

    public func addInputFile(file: InputFile, adapter: InputFileRawAdapter): MultipartByteStream {
        this.chunks.add(MultipartChunk("file", file, adapter))
        this
    }

    public func fail(message: String): MultipartByteStream {
        this.hasError = true
        this.errorMessage = message
        this.errorAfterMillis = 0
        this
    }

    public func fail(message: String, afterMillis: Int64): MultipartByteStream {
        this.hasError = true
        this.errorMessage = message
        this.errorAfterMillis = afterMillis
        this
    }

    public func body(): String {
        String.fromUtf8(this.collectBytes())
    }

    public func previewBody(): String {
        var out = ""
        for (chunk in this.chunks) {
            out += chunk.data
        }
        out
    }

    public func drain(): String {
        String.fromUtf8(this.drainBytes())
    }

    public func drainBytes(): Array<Byte> {
        if (this.hasError) {
            this.raiseError()
        }
        this.collectBytes()
    }

    public func collectBytes(): Array<Byte> {
        flattenMultipartChunks(this.collectChunks())
    }

    public func drainChunks(): Array<Array<Byte>> {
        if (this.hasError) {
            this.raiseError()
        }
        this.collectChunks()
    }

    public func collectChunks(): Array<Array<Byte>> {
        let chunks = ArrayList<Array<Byte>>()
        try {
            for (chunk in this.chunks) {
                match (chunk.raw) {
                    case Some(raw) =>
                        for (rawChunk in raw.collectChunks()) {
                            chunks.add(rawChunk)
                        }
                    case None =>
                        match (chunk.inputFile) {
                            case Some(file) =>
                                match (chunk.rawAdapter) {
                                    case Some(adapter) =>
                                        let raw = file.toRaw(adapter)
                                        for (rawChunk in raw.collectChunks()) {
                                            chunks.add(rawChunk)
                                        }
                                    case None => throw Exception("Multipart InputFile raw adapter missing")
                                }
                            case None => chunks.add(chunk.bytes)
                        }
                }
            }
        } catch (err: Exception) {
            this.onError(err)
            throw err
        }
        chunks.toArray()
    }

    public func raiseError(): Unit {
        let err = Exception(this.errorMessage)
        this.onError(err)
        throw err
    }

    public func chunkCount(): Int64 {
        this.chunks.size
    }
}

public class RequestPayload {
    public let method: String
    public let headers: String
    public let body: String
    public let bodyKind: String
    public let stream: MultipartByteStream

    public init(method: String, headers: String, body: String) {
        this.method = method
        this.headers = headers
        this.body = body
        this.bodyKind = "text"
        this.stream = MultipartByteStream()
        this.stream.addText(body)
    }

    public init(method: String, headers: String, body: String, stream: MultipartByteStream) {
        this.method = method
        this.headers = headers
        this.body = body
        this.bodyKind = "stream"
        this.stream = stream
    }
}

public class Payload {
    public let body: String
    public var fields: ArrayList<PayloadField> = ArrayList<PayloadField>()

    public init(body: String) {
        this.body = body
    }

    public func isEmpty(): Bool {
        this.body.isEmpty() && this.fields.size == 0
    }

    public func addValue(key: String, value: String): Payload {
        this.fields.add(PayloadField(key, value))
        this
    }

    public func addRawJson(key: String, value: String): Payload {
        this.fields.add(PayloadField(key, value, "raw"))
        this
    }

    public func addInt(key: String, value: Int64): Payload {
        this.fields.add(PayloadField(key, value.toString(), "number"))
        this
    }

    public func addFloat(key: String, value: Float64): Payload {
        this.fields.add(PayloadField(key, value.toString(), "number"))
        this
    }

    public func addBool(key: String, value: Bool): Payload {
        this.fields.add(PayloadField(key, if (value) { "true" } else { "false" }, "bool"))
        this
    }

    public func addNull(key: String): Payload {
        this.fields.add(PayloadField(key, "", true, false, "", "", "null"))
        this
    }

    public func addUndefined(key: String): Payload {
        this.fields.add(PayloadField(key, "", false, false, "", "", "undefined"))
        this
    }

    public func addNone(key: String): Payload {
        this.addUndefined(key)
    }

    public func addFile(key: String, file: InputFile): Payload {
        let field = PayloadField(key, file.sourceValue, false, true, file.filename, file.sourceKind, "file")
        field.inputFile = Some(file)
        this.fields.add(field)
        this
    }

    public func addObject(key: String): PayloadField {
        let field = PayloadField.object(key)
        this.fields.add(field)
        field
    }

    public func addArray(key: String): PayloadField {
        let field = PayloadField.array(key)
        this.fields.add(field)
        field
    }
}

private class CollectedFile {
    public let id: String
    public let origin: String
    public let file: PayloadField

    public init(id: String, origin: String, file: PayloadField) {
        this.id = id
        this.origin = origin
        this.file = file
    }
}

private func ignoreMultipartStreamError(_err: Exception): Unit {}

public func requiresFormDataUpload(payload: Payload): Bool {
    for (field in payload.fields) {
        if (fieldRequiresUpload(field)) {
            return true
        }
    }
    false
}

private func fieldRequiresUpload(field: PayloadField): Bool {
    if (field.isInputFile || field.valueKind == "file") {
        return true
    }
    for (child in field.children) {
        if (fieldRequiresUpload(child)) {
            return true
        }
    }
    false
}

public func createJsonPayload(payload: Payload): RequestPayload {
    RequestPayload("POST", "content-type=application/json;connection=keep-alive", jsonPayloadBody(payload))
}

public func createJsonPayloadWithMethod(payload: Payload, method: String): RequestPayload {
    RequestPayload("POST", "content-type=application/json;connection=keep-alive", jsonPayloadBody(payload, method))
}

private func jsonPayloadBody(payload: Payload): String {
    jsonPayloadBody(payload, "")
}

private func jsonPayloadBody(payload: Payload, method: String): String {
    if (payload.fields.size == 0) {
        if (method.isEmpty()) {
            if (payload.body.isEmpty()) {
                return "{}"
            }
            return payload.body
        }
        if (payload.body.isEmpty() || payload.body == "{}") {
            return "{\"method\":\"" + escapeJson(method) + "\"}"
        }
    }

    var body = "{"
    var first = true
    for (field in payload.fields) {
        if (fieldShouldSkipInObject(field)) {
            continue
        }
        if (!first) {
            body += ","
        }
        body += "\"" + escapeJson(field.key) + "\":" + fieldToJson(field)
        first = false
    }
    if (!method.isEmpty()) {
        if (!first) {
            body += ","
        }
        body += "\"method\":\"" + escapeJson(method) + "\""
    }
    body += "}"
    body
}

private func fieldToJson(field: PayloadField): String {
    if (field.valueKind == "null" || field.isNull || field.valueKind == "undefined" || field.valueKind == "none") {
        return "null"
    }
    if (field.valueKind == "number" || field.valueKind == "bool" || field.valueKind == "raw") {
        return field.value
    }
    if (field.valueKind == "object") {
        var body = "{"
        var first = true
        for (child in field.children) {
            if (fieldShouldSkipInObject(child)) {
                continue
            }
            if (!first) {
                body += ","
            }
            body += "\"" + escapeJson(child.key) + "\":" + fieldToJson(child)
            first = false
        }
        body += "}"
        return body
    }
    if (field.valueKind == "array") {
        var body = "["
        var first = true
        for (child in field.children) {
            if (!first) {
                body += ","
            }
            body += fieldToJson(child)
            first = false
        }
        body += "]"
        return body
    }
    "\"" + escapeJson(field.value) + "\""
}

public func createFormDataPayload(payload: Payload, boundary: String, attachIdPrefix: String): RequestPayload {
    createFormDataPayload(payload, boundary, attachIdPrefix, ignoreMultipartStreamError)
}

public func createFormDataPayload(payload: Payload, onError: MultipartStreamErrorCallback): RequestPayload {
    createFormDataPayload(payload, createBoundary(), "", onError)
}

public func createFormDataPayload(payload: Payload, boundary: String, attachIdPrefix: String, adapter: InputFileRawAdapter): RequestPayload {
    createFormDataPayload(payload, boundary, attachIdPrefix, ignoreMultipartStreamError, adapter)
}

public func createFormDataPayload(payload: Payload, boundary: String, attachIdPrefix: String, onError: MultipartStreamErrorCallback): RequestPayload {
    createFormDataPayload(payload, boundary, attachIdPrefix, onError, InputFileRawAdapter())
}

public func createFormDataPayload(
    payload: Payload,
    boundary: String,
    attachIdPrefix: String,
    onError: MultipartStreamErrorCallback,
    adapter: InputFileRawAdapter
): RequestPayload {
    let stream = MultipartByteStream(onError)
    let fileParts = ArrayList<CollectedFile>()

    stream.addText("--" + boundary + "\r\n")
    var first = true
    for (field in payload.fields) {
        if (fieldShouldSkipInObject(field)) {
            continue
        }
        if (!first) {
            stream.addText("\r\n--" + boundary + "\r\n")
        }
        stream.addText(valuePart(field.key, multipartFieldValue(field, fileParts, attachIdPrefix, "")))
        first = false
    }
    for (part in fileParts) {
        if (!first) {
            stream.addText("\r\n--" + boundary + "\r\n")
        }
        appendFilePart(stream, part, adapter)
        first = false
    }
    stream.addText("\r\n--" + boundary + "--\r\n")
    let body = stream.previewBody()
    RequestPayload("POST", "content-type=multipart/form-data; boundary=" + boundary + ";connection=keep-alive", body, stream)
}

private func createBoundary(): String {
    "----------" + randomId(32)
}

private func randomId(length: Int64): String {
    let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    var seed = DateTime.now().toUnixTimeStamp().toMilliseconds()
    var out = ""
    var i: Int64 = 0
    while (i < length) {
        seed = ((seed % 2147483647) + 1103515245 + i * 97) % 2147483647
        let index = seed % chars.size
        out += chars[index..index + 1]
        i += 1
    }
    out
}

private func multipartFieldValue(field: PayloadField, fileParts: ArrayList<CollectedFile>, attachIdPrefix: String, parentType: String): String {
    if (field.valueKind == "file" || field.isInputFile) {
        let attachId = if (attachIdPrefix.isEmpty()) {
            randomId(16)
        } else {
            attachIdPrefix + fileParts.size.toString()
        }
        let origin = if (field.key == "media" && !parentType.isEmpty()) {
            parentType
        } else {
            field.key
        }
        fileParts.add(CollectedFile(attachId, origin, field))
        return "attach://" + attachId
    }
    if (field.valueKind == "object") {
        return fieldToMultipartJson(field, fileParts, attachIdPrefix)
    }
    if (field.valueKind == "array") {
        return fieldToMultipartJson(field, fileParts, attachIdPrefix)
    }
    if (field.valueKind == "number" || field.valueKind == "bool" || field.valueKind == "raw") {
        return field.value
    }
    field.value
}

private func fieldToMultipartJson(field: PayloadField, fileParts: ArrayList<CollectedFile>, attachIdPrefix: String): String {
    if (field.valueKind == "object") {
        let parentType = objectType(field)
        var body = "{"
        var first = true
        for (child in field.children) {
            if (fieldShouldSkipInObject(child)) {
                continue
            }
            if (!first) {
                body += ","
            }
            body += "\"" + escapeJson(child.key) + "\":" + multipartJsonValue(child, fileParts, attachIdPrefix, parentType)
            first = false
        }
        body += "}"
        return body
    }
    if (field.valueKind == "array") {
        var body = "["
        var first = true
        for (child in field.children) {
            if (!first) {
                body += ","
            }
            body += multipartJsonValue(child, fileParts, attachIdPrefix, "")
            first = false
        }
        body += "]"
        return body
    }
    multipartJsonValue(field, fileParts, attachIdPrefix, "")
}

private func multipartJsonValue(field: PayloadField, fileParts: ArrayList<CollectedFile>, attachIdPrefix: String, parentType: String): String {
    if (field.valueKind == "null" || field.isNull || field.valueKind == "undefined" || field.valueKind == "none") {
        return "null"
    }
    if (field.valueKind == "file" || field.isInputFile) {
        return "\"" + escapeJson(multipartFieldValue(field, fileParts, attachIdPrefix, parentType)) + "\""
    }
    if (field.valueKind == "object" || field.valueKind == "array") {
        return fieldToMultipartJson(field, fileParts, attachIdPrefix)
    }
    if (field.valueKind == "number" || field.valueKind == "bool" || field.valueKind == "raw") {
        return field.value
    }
    "\"" + escapeJson(field.value) + "\""
}

private func fieldShouldSkipInObject(field: PayloadField): Bool {
    field.isNull || field.valueKind == "null" || field.valueKind == "undefined" || field.valueKind == "none"
}

private func objectType(field: PayloadField): String {
    for (child in field.children) {
        if (child.key == "type" && child.valueKind == "string") {
            return child.value
        }
    }
    ""
}

public func valuePart(key: String, value: String): String {
    "content-disposition:form-data;name=\"" + key + "\"\r\n\r\n" + value
}

public func filePart(attachId: String, origin: String, filename: String, body: String): String {
    filePartHeader(attachId, origin, filename) + body
}

private func appendFilePart(stream: MultipartByteStream, part: CollectedFile, adapter: InputFileRawAdapter): Unit {
    stream.addText(filePartHeader(part.id, part.origin, part.file.filename))
    if (part.file.sourceKind == "stream_error_after") {
        stream.fail(part.file.value, 100)
        return
    }
    if (part.file.sourceKind == "stream_error") {
        stream.fail(part.file.value, 0)
        return
    }
    appendInputFileBytes(stream, part.file, adapter)
}

private func appendInputFileBytes(stream: MultipartByteStream, field: PayloadField, adapter: InputFileRawAdapter): Unit {
    match (field.inputFile) {
        case Some(file) =>
            stream.addInputFile(file, adapter)
        case None => stream.addFile(field.sourceKind, field.value)
    }
}

private func filePartHeader(attachId: String, origin: String, filename: String): String {
    let actualFilename = if (filename.isEmpty()) {
        origin + "." + defaultFileExtension(origin)
    } else {
        filename
    }
    if (actualFilename.contains("\r") || actualFilename.contains("\n")) {
        throw Exception(
            "File paths cannot contain carriage-return (\\r) or newline (\\n) characters! Filename for property '" +
            origin + "' was:\n\"\"\"\n" + actualFilename + "\n\"\"\""
        )
    }
    "content-disposition:form-data;name=\"" + attachId + "\";filename=" + actualFilename +
        "\r\ncontent-type:application/octet-stream\r\n\r\n"
}

public func defaultFileExtension(key: String): String {
    if (key == "certificate") {
        return "pem"
    }
    if (key == "photo" || key == "thumbnail") {
        return "jpg"
    }
    if (key == "voice") {
        return "ogg"
    }
    if (key == "audio") {
        return "mp3"
    }
    if (key == "animation" || key == "video" || key == "video_note") {
        return "mp4"
    }
    if (key == "sticker") {
        return "webp"
    }
    "dat"
}

public func escapeJson(value: String): String {
    value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r")
}

private func flattenMultipartChunks(chunks: Array<Array<Byte>>): Array<Byte> {
    let out = ArrayList<Byte>()
    for (chunk in chunks) {
        for (byte in chunk) {
            out.add(byte)
        }
    }
    out.toArray()
}
