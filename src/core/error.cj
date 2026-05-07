package grammy4cj.core

import grammy4cj.types.ApiError
import grammy4cj.types.ResponseParameters

public class GrammyError <: Exception {
    public let ok: Bool = false
    public let method: String
    public let payload: String
    public let errorCode: Int64
    public let error_code: Int64
    public let description: String
    public let parameters: ResponseParameters

    public init(message: String, method: String) {
        super(message)
        this.method = method
        this.payload = ""
        this.errorCode = 0
        this.error_code = 0
        this.description = message
        this.parameters = ResponseParameters()
    }

    public init(method: String, payload: String, errorCode: Int64, description: String, parameters: ResponseParameters) {
        super("Call to '" + method + "' failed! (" + errorCode.toString() + ": " + description + ")")
        this.method = method
        this.payload = payload
        this.errorCode = errorCode
        this.error_code = errorCode
        this.description = description
        this.parameters = parameters
    }
}

public class TransportErrorInfo <: Exception {
    public let status: Int64
    public let statusText: String

    public init(message: String) {
        super(message)
        this.status = 0
        this.statusText = ""
    }

    public init(status: Int64, statusText: String, message: String) {
        super(message)
        this.status = status
        this.statusText = statusText
    }
}

public class HttpError <: Exception {
    public let status: Int64
    public let statusText: String
    public let method: String
    public let url: String
    public let error: String

    public init(message: String, status: Int64) {
        super(message)
        this.status = status
        this.statusText = ""
        this.method = ""
        this.url = ""
        this.error = message
    }

    public init(message: String, status: Int64, method: String, url: String) {
        super(message)
        this.status = status
        this.statusText = ""
        this.method = method
        this.url = url
        this.error = message
    }

    public init(message: String, status: Int64, statusText: String, method: String, url: String, error: String) {
        super(message)
        this.status = status
        this.statusText = statusText
        this.method = method
        this.url = url
        this.error = error
    }
}

public func toGrammyError(err: ApiError, method: String, payload: Payload): GrammyError {
    GrammyError(method, createJsonPayload(payload).body, err.errorCode, err.description, err.parameters)
}

public func toHttpError(method: String, sensitiveLogs: Bool, err: Exception): HttpError {
    var message = "Network request for '" + method + "' failed!"
    var status: Int64 = 0
    var statusText = ""
    try {
        throw err
    } catch (e: TransportErrorInfo) {
        status = e.status
        statusText = e.statusText
        if (!e.statusText.isEmpty()) {
            message += " (" + e.status.toString() + ": " + e.statusText + ")"
        }
        if (sensitiveLogs && !e.message.isEmpty()) {
            message += " " + e.message
        }
        return HttpError(message, status, statusText, method, "", e.message)
    } catch (e: Exception) {
        if (sensitiveLogs && !e.message.isEmpty()) {
            message += " " + e.message
        }
        return HttpError(message, status, statusText, method, "", e.message)
    }
}

public func toHttpError(method: String, sensitiveLogs: Bool, status: Int64, statusText: String, errorMessage: String): HttpError {
    toHttpError(method, sensitiveLogs, TransportErrorInfo(status, statusText, errorMessage))
}

public func toHttpError(method: String, sensitiveLogs: Bool, status: Int64): HttpError {
    toHttpError(method, sensitiveLogs, TransportErrorInfo(status, "", ""))
}
