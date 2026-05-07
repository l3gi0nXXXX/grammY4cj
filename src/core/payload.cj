package grammy4cj.core

import std.collection.ArrayList

import grammy4cj.types.InputFile

public class PayloadField {
    public let key: String
    public let value: String
    public let isNull: Bool
    public let isInputFile: Bool
    public let filename: String
    public let sourceKind: String

    public init(key: String, value: String) {
        this.key = key
        this.value = value
        this.isNull = false
        this.isInputFile = false
        this.filename = ""
        this.sourceKind = ""
    }

    public init(key: String, value: String, isNull: Bool, isInputFile: Bool, filename: String, sourceKind: String) {
        this.key = key
        this.value = value
        this.isNull = isNull
        this.isInputFile = isInputFile
        this.filename = filename
        this.sourceKind = sourceKind
    }
}

public class RequestPayload {
    public let method: String
    public let headers: String
    public let body: String

    public init(method: String, headers: String, body: String) {
        this.method = method
        this.headers = headers
        this.body = body
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

    public func addNull(key: String): Payload {
        this.fields.add(PayloadField(key, "", true, false, "", ""))
        this
    }

    public func addFile(key: String, file: InputFile): Payload {
        this.fields.add(PayloadField(key, file.sourceValue, false, true, file.filename, file.sourceKind))
        this
    }
}

public func requiresFormDataUpload(payload: Payload): Bool {
    for (field in payload.fields) {
        if (field.isInputFile) {
            return true
        }
    }
    false
}

public func createJsonPayload(payload: Payload): RequestPayload {
    if (payload.fields.size == 0) {
        return RequestPayload("POST", "content-type=application/json;connection=keep-alive", payload.body)
    }
    var body: String = "{"
    var first = true
    for (field in payload.fields) {
        if (field.isNull) {
            continue
        }
        if (!first) {
            body += ","
        }
        body += "\"" + escapeJson(field.key) + "\":\"" + escapeJson(field.value) + "\""
        first = false
    }
    body += "}"
    RequestPayload("POST", "content-type=application/json;connection=keep-alive", body)
}

public func createFormDataPayload(payload: Payload, boundary: String, attachIdPrefix: String): RequestPayload {
    var body: String = "--" + boundary + "\r\n"
    var first = true
    var fileIndex: Int64 = 0
    var fileParts: ArrayList<String> = ArrayList<String>()
    for (field in payload.fields) {
        if (field.isNull) {
            continue
        }
        if (!first) {
            body += "\r\n--" + boundary + "\r\n"
        }
        if (field.isInputFile) {
            let attachId = attachIdPrefix + fileIndex.toString()
            body += valuePart(field.key, "attach://" + attachId)
            fileParts.add(filePart(attachId, field.key, field.filename, field.value))
            fileIndex += 1
        } else {
            body += valuePart(field.key, field.value)
        }
        first = false
    }
    for (part in fileParts) {
        if (!first) {
            body += "\r\n--" + boundary + "\r\n"
        }
        body += part
        first = false
    }
    body += "\r\n--" + boundary + "--\r\n"
    RequestPayload("POST", "content-type=multipart/form-data;boundary=" + boundary + ";connection=keep-alive", body)
}

public func valuePart(key: String, value: String): String {
    "content-disposition:form-data;name=\"" + key + "\"\r\n\r\n" + value
}

public func filePart(attachId: String, origin: String, filename: String, body: String): String {
    let actualFilename = if (filename.isEmpty()) {
        origin + "." + defaultFileExtension(origin)
    } else {
        filename
    }
    if (actualFilename.contains("\r") || actualFilename.contains("\n")) {
        throw Exception("File paths cannot contain carriage-return or newline characters.")
    }
    "content-disposition:form-data;name=\"" + attachId + "\";filename=" + actualFilename +
        "\r\ncontent-type:application/octet-stream\r\n\r\n" + body
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
    "dat"
}

public func escapeJson(value: String): String {
    value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r")
}
